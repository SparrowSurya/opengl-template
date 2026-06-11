// IMPORTANT: glad must always be included BEFORE GLFW.
// glad injects the real OpenGL function pointers; GLFW then uses them
// when it creates the context.
#include <glad/glad.h>
#include <GLFW/glfw3.h>

#include <cstdio>
#include <cstdlib>

// ─── Window constants ────────────────────────────────────────────────────────
static constexpr int         SCR_WIDTH  = 800;
static constexpr int         SCR_HEIGHT = 600;
static constexpr const char* TITLE      = "OpenGL Template";

// ─── Callbacks ───────────────────────────────────────────────────────────────
static void on_resize(GLFWwindow* /*window*/, int width, int height) {
    glViewport(0, 0, width, height);
}

static void on_key(GLFWwindow* window, int key, int /*scan*/, int action, int /*mods*/) {
    if (key == GLFW_KEY_ESCAPE && action == GLFW_PRESS) {
        glfwSetWindowShouldClose(window, GLFW_TRUE);
    }
}

// ─── Entry point ─────────────────────────────────────────────────────────────
int main() {
    // Initialise GLFW
    if (!glfwInit()) {
        fprintf(stderr, "[GLFW] init failed\n");
        return EXIT_FAILURE;
    }

    // Request an OpenGL 3.3 Core Profile context
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

    // macOS requires the forward-compat hint for Core Profile
#ifdef __APPLE__
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GLFW_TRUE);
#endif

    GLFWwindow* window = glfwCreateWindow(SCR_WIDTH, SCR_HEIGHT, TITLE, nullptr, nullptr);
    if (!window) {
        fprintf(stderr, "[GLFW] window creation failed\n");
        glfwTerminate();
        return EXIT_FAILURE;
    }

    glfwSetWindowTitle(window, "Hello OpenGL");
    glfwMakeContextCurrent(window);
    glfwSetFramebufferSizeCallback(window, on_resize);
    glfwSetKeyCallback(window, on_key);
    glfwSwapInterval(1); // enable vsync

    // Load OpenGL function pointers via GLAD
    if (!gladLoadGLLoader(reinterpret_cast<GLADloadproc>(glfwGetProcAddress))) {
        fprintf(stderr, "[GLAD] failed to load OpenGL\n");
        return EXIT_FAILURE;
    }

    printf("OpenGL %s\n", reinterpret_cast<const char*>(glGetString(GL_VERSION)));
    printf("Renderer: %s\n", reinterpret_cast<const char*>(glGetString(GL_RENDERER)));

    // ── Main loop ─────────────────────────────────────────────────────────────
    while (!glfwWindowShouldClose(window)) {
        glClearColor(0.10f, 0.10f, 0.15f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT);

        // TODO: your render calls go here

        glfwSwapBuffers(window);
        glfwPollEvents();
    }

    glfwDestroyWindow(window);
    glfwTerminate();
    return EXIT_SUCCESS;
}