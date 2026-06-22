# opengl-template

Personal C++ / OpenGL 3.3 Core project starter template for macOS.

**Compiler:** clang / clang++ (via Xcode Command Line Tools)
**Build system:** CMake 3.20+ with `CMakePresets.json`
**C++ standard:** C++17

---

## Dependencies

### GLFW
**What it does:** GLFW (Graphics Library Framework) handles everything *outside* the OpenGL
render loop — creating a window, creating an OpenGL context tied to that window, and processing
keyboard/mouse/gamepad input events. Without it you would have to write platform-specific code
(Cocoa on macOS, Win32 on Windows, X11 on Linux) just to get a window on screen.

**Why a static library?** `libglfw3.a` is compiled once and baked into your binary.
No `.dylib` needs to travel with your app; the binary is self-contained.

**Version in this template:** 3.4
**Where it lives:** `external/GLFW/include/GLFW/` (headers) and `external/GLFW/lib/libglfw3.a`

**macOS system frameworks GLFW links against** (added in `CMakeLists.txt`; nothing to install):

| Framework | Role |
|-----------|------|
| `OpenGL.framework` | The actual OpenGL implementation provided by macOS / the GPU driver |
| `Cocoa.framework` | macOS native window creation and the event run-loop |
| `IOKit.framework` | Keyboard, mouse, and gamepad/joystick input |
| `CoreVideo.framework` | Display-link timing used for vsync (`glfwSwapInterval`) |

---

### GLAD
**What it does:** On desktop, OpenGL function addresses are not known at compile time — they
must be queried from the driver at runtime. GLAD is a *loader generator*: it produces a small
`.c` file plus a header that, at startup, walks through every `gl*` function you use and
fetches its real address from the driver. After `gladLoadGLLoader(...)` returns you can call
`glDrawArrays`, `glCreateShader`, etc. directly.

**Why a source file instead of a `.a`?** GLAD is generated per-platform and per-profile.
The tiny `glad.c` file in `external/GLAD/src/` is compiled by CMake into an internal static
library (`libglad.a`) automatically — you never touch it after `setup.sh` runs.

**Profile used:** OpenGL 3.3 Core (compatible with all discrete GPUs made after ~2010 and
Apple's Intel/AMD GPUs; the M-series chips also support it via translation).

**Where it lives:** `external/GLAD/include/` (two headers) and `external/GLAD/src/glad.c`

---

### GLM
**What it does:** GLM (OpenGL Mathematics) is a header-only C++ math library designed to
mirror GLSL's built-in types and functions. It gives you `glm::vec3`, `glm::mat4`,
`glm::perspective`, `glm::lookAt`, `glm::translate`, and so on — exactly the types you need
to build model/view/projection matrices and pass them as uniforms to your shaders.

**Why header-only?** GLM is pure templates; there is nothing to compile. Drop the headers in
and `#include <glm/glm.hpp>`.

**Version in this template:** 1.0.1
**Where it lives:** `external/GLM/include/glm/`

---

### Dear ImGui
**What it does:** Dear ImGui is a bloat-free graphical user interface library for C++. It is used to generate debug GUIs, overlays, and developer control panels in real-time. It runs inside your OpenGL render loop and draws elements dynamically.

**Why a static library?** The core ImGui source files and GLFW/OpenGL3 backends are compiled by CMake directly into a static library (`libimgui.a`) to keep your binary self-contained.

**Version in this template:** 1.92.8
**Where it lives:** `external/imgui/` (core headers/sources) and `external/imgui/backends/` (GLFW and OpenGL3 backend files)

---

## Repository layout

```
opengl-template/
├── external/
│   ├── GLFW/
│   │   ├── include/GLFW/        ← glfw3.h, glfw3native.h
│   │   └── lib/
│   │       └── libglfw3.a       ← pre-compiled static archive
│   ├── GLAD/
│   │   ├── include/
│   │   │   ├── glad/glad.h      ← OpenGL function declarations
│   │   │   └── KHR/khrplatform.h
│   │   └── src/
│   │       └── glad.c           ← compiled by CMake into internal libglad.a
│   ├── GLM/
│   │   └── include/
│   │       └── glm/             ← header-only math library (~1.5 MB of headers)
│   └── imgui/
│       ├── backends/            ← GLFW and OpenGL3 backends
│       └── *                    ← core source and header files
├── include/                     ← YOUR project headers (.h / .hpp)
├── src/
│   └── main.cpp                 ← entry point
├── CMakeLists.txt
├── CMakePresets.json            ← pins clang/clang++; sets build dir to build/
├── Makefile                     ← thin wrapper around cmake commands
├── setup/
│   ├── linux.sh                 ← Linux dependency setup script (run once after clone)
│   └── macos.sh                 ← macOS dependency setup script (run once after clone)
├── .clangd                      ← LSP config for clangd
├── .clang-format                ← code style
├── .gitignore
└── README.md
```

> **Why no full source repos in `external/`?**
> Vendoring full repos (e.g. the entire GLFW or GLM git history) adds hundreds of megabytes
> to the repository. Instead, `setup.sh` downloads only what is needed and places the compiled
> outputs and headers into `external/`. The result is a repo well under 5 MB.

---

## Prerequisites

### 1 — Xcode Command Line Tools
Provides `clang`, `clang++`, `make`, `git`, and the macOS SDK (which includes the
`OpenGL.framework`, `Cocoa.framework`, etc.).

```bash
xcode-select --install
```

A dialog will appear asking you to install; click **Install**. This is a one-time step per Mac.

### 2 — Homebrew
Package manager for macOS. If you don't have it:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

On **Apple Silicon (M1/M2/M3)** Homebrew installs to `/opt/homebrew`.
On **Intel** it installs to `/usr/local`.

### 3 — CMake

```bash
brew install cmake
```

### 4 — Python 3
Required only by `setup.sh` to generate the GLAD loader (one-time only).

```bash
brew install python3
```

---

## First-time setup

### macOS
After installing the prerequisites, run the macOS setup script:
```bash
chmod +x setup/macos.sh
./setup/macos.sh
```

### Linux
Run the Linux setup script (which uses `apt` or `pacman` to install system development packages, and then downloads and compiles local project libraries):
```bash
chmod +x setup/linux.sh
./setup/linux.sh
```

What it does, step by step:

| Step | Action |
|------|--------|
| **1/4 GLFW** | Downloads GLFW 3.4 source, builds `libglfw3.a` with clang, copies headers + lib into `external/GLFW/` |
| **2/4 GLM** | Downloads GLM 1.0.1 release tarball, extracts headers into `external/GLM/include/glm/` |
| **3/4 GLAD** | Installs the `glad` Python package, generates an OpenGL 3.3 Core loader, copies the three output files into `external/GLAD/` |
| **4/4 ImGui** | Downloads Dear ImGui 1.92.8 release, extracts core files and backends into `external/imgui/` |

After the setup finishes, **commit `external/`** to git — you will never need to run the setup script
again unless you wipe the directory.

```bash
git add external/
git commit -m "chore: add pre-built dependencies"
```

---

## Building

```bash
make            # configure (Debug) + build  →  build/app
make release    # configure (Release) + build
make run        # build (Debug) + run immediately
make clean      # rm -rf build/
```

Or drive CMake directly:

```bash
cmake --preset default          # configure; writes build/ and compile_commands.json
cmake --build --preset default  # compile
./build/app
```

Expected output when the window opens:
- The console logs the detected driver profile, e.g.:
  ```
  OpenGL 4.1 Metal - 88
  Renderer: Apple M2
  ```
- A window opens with the large centered text **"Hello OpenGL"** rendered directly onto the viewport background.
- An interactive **"Control Panel"** window is displayed. Typing in the input box updates the centered text in real-time.
- Pressing **`F5`** toggles the visibility of the Control Panel window.

---

## Starting a new project from this template

1. Click **Use this template** on GitHub (creates your new repo without the commit history).
2. Clone the new repo and run `./setup.sh`.
3. In `CMakeLists.txt`, change `project(app …)` to your project name.
4. Write your headers in `include/`, source files in `src/`.
5. `make run`.

---

## Adding more dependencies

Follow the same pattern used for GLFW (pre-compiled static library):

```
external/
└── NEWLIB/
    ├── include/    ← headers
    └── lib/
        └── libnewlib.a
```

Then in `CMakeLists.txt` before the `add_executable` block:

```cmake
add_library(newlib STATIC IMPORTED GLOBAL)
set_target_properties(newlib PROPERTIES
    IMPORTED_LOCATION             ${EXT}/NEWLIB/lib/libnewlib.a
    INTERFACE_INCLUDE_DIRECTORIES ${EXT}/NEWLIB/include
)
```

And add `newlib` to the `target_link_libraries` call.

---

## Notes

### OpenGL deprecation on macOS
Apple deprecated the OpenGL API in macOS 10.14 (Mojave, 2018) in favour of Metal.
OpenGL still works correctly on all current macOS versions — the deprecation just
means Apple will not add new OpenGL features. The `GL_SILENCE_DEPRECATION` definition
in `CMakeLists.txt` and the `GLFW_OPENGL_FORWARD_COMPAT` hint in `main.cpp` silence
the compiler and GLFW warnings about this.

### Static (`.a`) vs dynamic (`.dylib` / `.so`)
| | Static `.a` | Dynamic `.dylib` / `.so` |
|-|-------------|--------------------------|
| Linked at | Compile time — code baked into binary | Runtime — library loaded from disk |
| Binary portability | Self-contained; no extra files needed | Binary needs the `.dylib` present at the same path |
| Binary size | Larger | Smaller |
| Rebuild needed for lib update | Yes | No (swap the `.dylib`) |

This template uses **static** linking so the resulting binary runs anywhere on macOS
without shipping extra files.

### Why `GLFW_OPENGL_FORWARD_COMPAT` on macOS?
macOS only exposes OpenGL 3.3+ through a **Core Profile** context, and that Core Profile
*requires* the forward-compatibility flag. Without it, GLFW cannot create a 3.3 context
on macOS and returns `nullptr`. The flag is guarded with `#ifdef __APPLE__` in `main.cpp`
so it compiles correctly on Linux too.