#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# linux.sh  —  Linux dependency setup (supports apt and pacman)
#
# Run this ONCE after cloning the template. It will:
#   1. Install system dependencies via apt or pacman
#   2. Build GLFW from source → external/GLFW/
#   3. Download GLM headers   → external/GLM/
#   4. Generate GLAD loader   → external/GLAD/
#   5. Download ImGui source  → external/imgui/
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXT="$ROOT/external"

GLFW_VERSION="3.4"
GLM_VERSION="1.0.1"
IMGUI_VERSION="1.92.8"

# ─── Preflight checks & Package Installation ──────────────────────────────────
echo "══════════════════════════════════════════════════"
echo "  OpenGL Template — Linux Dependency Setup"
echo "══════════════════════════════════════════════════"

if command -v apt-get &>/dev/null; then
    echo "  Detected Debian/Ubuntu system (apt)..."
    echo "  Updating package lists and installing dependencies (requires sudo)..."
    sudo apt-get update -y
    sudo apt-get install -y \
        build-essential \
        cmake \
        python3 \
        python3-venv \
        libxrandr-dev \
        libxinerama-dev \
        libxcursor-dev \
        libxi-dev \
        libgl1-mesa-dev
elif command -v pacman &>/dev/null; then
    echo "  Detected Arch Linux system (pacman)..."
    echo "  Installing dependencies (requires sudo)..."
    sudo pacman -Syu --needed --noconfirm \
        base-devel \
        cmake \
        python \
        libxrandr \
        libxinerama \
        libxcursor \
        libxi \
        mesa
else
    echo "  Warning: Neither apt nor pacman detected."
    echo "  Please ensure you have cmake, python3 (with venv), and X11/OpenGL development libraries installed."
fi

# Pre setup
mkdir -p "$EXT"

# ─── 1. GLFW ─────────────────────────────────────────────────────────────────
echo ""
echo "[1/4] Building GLFW $GLFW_VERSION static library..."

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

curl -fsSL \
    "https://github.com/glfw/glfw/archive/refs/tags/$GLFW_VERSION.tar.gz" \
    -o "$TMP/glfw.tar.gz"
tar -xf "$TMP/glfw.tar.gz" -C "$TMP"

cmake -S "$TMP/glfw-$GLFW_VERSION" -B "$TMP/glfw-build" \
    -DCMAKE_BUILD_TYPE=Release  \
    -DGLFW_BUILD_EXAMPLES=OFF   \
    -DGLFW_BUILD_TESTS=OFF      \
    -DGLFW_BUILD_DOCS=OFF       \
    -DBUILD_SHARED_LIBS=OFF     \
    -G "Unix Makefiles"         \
    > /dev/null 2>&1

cmake --build "$TMP/glfw-build" --parallel > /dev/null 2>&1

mkdir -p "$EXT/GLFW/include/GLFW/"
mkdir -p "$EXT/GLFW/lib/"

cp -r "$TMP/glfw-$GLFW_VERSION/include/GLFW/" "$EXT/GLFW/include/GLFW/"
cp    "$TMP/glfw-build/src/libglfw3.a"         "$EXT/GLFW/lib/libglfw3.a"

trap - EXIT; rm -rf "$TMP"
echo "    ✓ headers    → external/GLFW/include/GLFW/"
echo "    ✓ libglfw3.a → external/GLFW/lib/"

# ─── 2. GLM ──────────────────────────────────────────────────────────────────
echo ""
echo "[2/4] Downloading GLM $GLM_VERSION (header-only)..."

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

curl -fsSL \
    "https://github.com/g-truc/glm/archive/refs/tags/$GLM_VERSION.tar.gz" \
    -o "$TMP/glm.tar.gz"
tar -xf "$TMP/glm.tar.gz" -C "$TMP"
mkdir -p "$EXT/GLM/include/glm/"
cp -r "$TMP/glm-$GLM_VERSION/glm/" "$EXT/GLM/include/glm/"

trap - EXIT; rm -rf "$TMP"
echo "    ✓ glm/ headers → external/GLM/include/glm/"

# ─── 3. GLAD ─────────────────────────────────────────────────────────────────
echo ""
echo "[3/4] Generating GLAD OpenGL 3.3 Core loader..."

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

python3 -m venv "$TMP/venv"
"$TMP/venv/bin/pip" install glad --quiet

"$TMP/venv/bin/glad" \
    --profile core   \
    --api    gl=3.3  \
    --generator c    \
    --out-path "$TMP/glad-out"

mkdir -p "$EXT/GLAD/include/glad/"
mkdir -p "$EXT/GLAD/include/KHR/"
mkdir -p "$EXT/GLAD/src/"

cp "$TMP/glad-out/include/glad/glad.h"       "$EXT/GLAD/include/glad/"
cp "$TMP/glad-out/include/KHR/khrplatform.h" "$EXT/GLAD/include/KHR/"
cp "$TMP/glad-out/src/glad.c"                "$EXT/GLAD/src/"

trap - EXIT; rm -rf "$TMP"
echo "    ✓ glad.h          → external/GLAD/include/glad/"
echo "    ✓ khrplatform.h   → external/GLAD/include/KHR/"
echo "    ✓ glad.c          → external/GLAD/src/"

# ─── 4. ImGui ─────────────────────────────────────────────────────────────────
echo ""
echo "[4/4] Downloading ImGui $IMGUI_VERSION..."

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

curl -fsSL \
    "https://github.com/ocornut/imgui/archive/refs/tags/v$IMGUI_VERSION.tar.gz" \
    -o "$TMP/imgui.tar.gz"
tar -xf "$TMP/imgui.tar.gz" -C "$TMP"

mkdir -p "$EXT/imgui/"
cp -r "$TMP/imgui-$IMGUI_VERSION/"* "$EXT/imgui/"

trap - EXIT; rm -rf "$TMP"
echo "    ✓ ImGui source → external/imgui/"

# ─── Done ────────────────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════"
echo "  All dependencies placed in external/"
echo "  Next step:  make"
echo "══════════════════════════════════════════════════"
