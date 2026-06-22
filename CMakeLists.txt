cmake_minimum_required(VERSION 3.20)
project(app CXX C)

# ─── Standards ───────────────────────────────────────────────────────────────
set(CMAKE_C_STANDARD            11)
set(CMAKE_C_STANDARD_REQUIRED   ON)
set(CMAKE_CXX_STANDARD          17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Generates build/compile_commands.json for clangd LSP
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# ─── Paths ───────────────────────────────────────────────────────────────────
set(EXT     ${CMAKE_SOURCE_DIR}/external)
set(SRC_DIR ${CMAKE_SOURCE_DIR}/src)
set(INC_DIR ${CMAKE_SOURCE_DIR}/include)

# ─── GLAD (special: ships as a .c file; CMake compiles it into a static lib) ─
add_library(glad STATIC ${EXT}/GLAD/src/glad.c)
target_include_directories(glad PUBLIC ${EXT}/GLAD/include)

# ─── GLFW (pre-compiled static library) ──────────────────────────────────────
add_library(glfw STATIC IMPORTED GLOBAL)
set_target_properties(glfw PROPERTIES
    IMPORTED_LOCATION             ${EXT}/GLFW/lib/libglfw3.a
    INTERFACE_INCLUDE_DIRECTORIES ${EXT}/GLFW/include
)

# ─── GLM (header-only; no lib file needed) ───────────────────────────────────
add_library(glm INTERFACE)
target_include_directories(glm INTERFACE ${EXT}/GLM/include)

# ─── ImGui (static library) ──────────────────────────────────────────────────
file(GLOB IMGUI_SOURCES ${EXT}/imgui/*.cpp)
list(APPEND IMGUI_SOURCES
    ${EXT}/imgui/backends/imgui_impl_glfw.cpp
    ${EXT}/imgui/backends/imgui_impl_opengl3.cpp
)
add_library(imgui STATIC ${IMGUI_SOURCES})
target_include_directories(imgui PUBLIC
    ${EXT}
    ${EXT}/imgui
    ${EXT}/GLFW/include
    ${EXT}/GLAD/include
)

# ─── Executable ──────────────────────────────────────────────────────────────
file(GLOB_RECURSE SOURCES ${SRC_DIR}/*.cpp)

add_executable(${PROJECT_NAME} ${SOURCES})

target_include_directories(${PROJECT_NAME} PRIVATE ${INC_DIR})

target_link_libraries(${PROJECT_NAME} PRIVATE
    glad
    glfw
    glm
    imgui
)

# ─── Platform-specific system libraries ──────────────────────────────────────
if(APPLE)
    # OpenGL is deprecated since macOS 10.14 (Mojave) but still functional.
    # This definition silences the compiler warnings at the project level.
    target_compile_definitions(${PROJECT_NAME} PRIVATE GL_SILENCE_DEPRECATION)

    # GLFW on macOS uses these native Cocoa/system frameworks
    target_link_libraries(${PROJECT_NAME} PRIVATE
        "-framework OpenGL"     # OpenGL implementation
        "-framework Cocoa"      # GLFW window + event loop backend
        "-framework IOKit"      # GLFW keyboard / mouse / gamepad input
        "-framework CoreVideo"  # GLFW display-link (vsync timing)
    )
elseif(UNIX)
    # Linux: X11 windowing stack + system OpenGL + threading
    target_link_libraries(${PROJECT_NAME} PRIVATE
        GL          # OpenGL (Mesa or proprietary driver)
        X11         # Core X Window System
        Xrandr      # Display mode / resolution switching
        Xinerama    # Multi-monitor topology
        Xcursor     # Cursor shape theming
        Xi          # XInput (gamepad, joystick, touchpad)
        dl          # dlopen — GLAD needs this to load GL symbols
        pthread     # POSIX threading
        m           # libm (math)
    )
endif()