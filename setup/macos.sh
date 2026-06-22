#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# setup.sh  —  macOS dependency setup (requires Homebrew)
#
# Run this ONCE after cloning the template. It will:
#   1. Build GLFW from source → external/GLFW/
#   2. Download GLM headers   → external/GLM/
#   3. Generate GLAD loader   → external/GLAD/
#
# Prerequisites (all free):
#   • Xcode Command Line Tools  →  xcode-select --install
#   • Homebrew                  →  https://brew.sh
#   • cmake (via brew)          →  brew install cmake
#   • Python 3 (via brew)       →  brew install python3
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXT="$ROOT/../external"

GLFW_VERSION="3.4"
GLM_VERSION="1.0.1"

# ─── Preflight checks ────────────────────────────────────────────────────────
echo "══════════════════════════════════════════════════"
echo "  OpenGL Template — macOS Dependency Setup"
echo "══════════════════════════════════════════════════"

if ! command -v brew &>/dev/null; then
    echo ""
    echo "  Error: Homebrew not found."
    echo "  Install it from https://brew.sh and re-run this script."
    exit 1
fi
BREW="$(brew --prefix)"
echo "  Homebrew prefix : $BREW"

if ! command -v cmake &>/dev/null; then
    echo "  cmake not found — installing via Homebrew..."
    brew install cmake
fi
echo "  cmake           : $(cmake --version | head -1)"

if ! command -v python3 &>/dev/null; then
    echo "  python3 not found — installing via Homebrew..."
    brew install python3
fi
echo "  python3         : $(python3 --version)"
echo ""

# Pre setup
mkdir -p "$EXT"

# ─── 1. GLFW ─────────────────────────────────────────────────────────────────
# We build from source (rather than copying from Homebrew) so we are guaranteed
# to get the static archive (.a). Homebrew's glfw formula may only ship the
# dynamic library (.dylib) depending on the formula version.
echo "[1/3] Building GLFW $GLFW_VERSION static library..."

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT   # clean up on exit

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
    -DCMAKE_C_COMPILER=clang    \
    -G "Unix Makefiles"         \
    > /dev/null 2>&1

cmake --build "$TMP/glfw-build" --parallel > /dev/null 2>&1

# Copy headers and static lib into external/
mkdir -p "$EXT/GLFW/include/GLFW/"
mkdir -p "$EXT/GLFW/lib/"

cp -r "$TMP/glfw-$GLFW_VERSION/include/GLFW/" "$EXT/GLFW/include/GLFW/"
cp    "$TMP/glfw-build/src/libglfw3.a"         "$EXT/GLFW/lib/libglfw3.a"

trap - EXIT; rm -rf "$TMP"   # reset trap before next section
echo "    ✓ headers    → external/GLFW/include/GLFW/"
echo "    ✓ libglfw3.a → external/GLFW/lib/"

# ─── 2. GLM ──────────────────────────────────────────────────────────────────
echo ""
echo "[2/3] Downloading GLM $GLM_VERSION (header-only)..."

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
# GLAD is a code generator. We use the PyPI 'glad' package (v0.1.x) to
# generate an OpenGL 3.3 Core C loader, then commit the three output files.
#
# We use a throw-away venv so we never touch the system Python or Homebrew's
# managed environment (PEP 668 blocks direct `pip install` on modern systems).
echo ""
echo "[3/3] Generating GLAD OpenGL 3.3 Core loader..."

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# Create a self-contained venv just for the glad generator
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

trap - EXIT; rm -rf "$TMP"   # venv disappears with the temp dir
echo "    ✓ glad.h          → external/GLAD/include/glad/"
echo "    ✓ khrplatform.h   → external/GLAD/include/KHR/"
echo "    ✓ glad.c          → external/GLAD/src/"

# ─── Done ────────────────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════"
echo "  All dependencies placed in external/"
echo "  Next step:  make"
echo "══════════════════════════════════════════════════"