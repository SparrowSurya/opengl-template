// IMPORTANT: glad must always be included BEFORE GLFW.
// glad injects the real OpenGL function pointers; GLFW then uses them
// when it creates the context.
#include <glad/glad.h>
#include <GLFW/glfw3.h>

#include <imgui/imgui.h>
#include <imgui/backends/imgui_impl_glfw.h>
#include <imgui/backends/imgui_impl_opengl3.h>

#include <cstdio>
#include <cstdlib>

// ─── Window constants ────────────────────────────────────────────────────────
static constexpr int         SCR_WIDTH  = 800;
static constexpr int         SCR_HEIGHT = 600;
static constexpr const char* TITLE      = "Hello World";

// ─── Callbacks ───────────────────────────────────────────────────────────────
static bool show_control_panel = true;

static void on_resize(GLFWwindow* /*window*/, int width, int height) {
    glViewport(0, 0, width, height);
}

static void on_key(GLFWwindow* window, int key, int /*scan*/, int action, int /*mods*/) {
    if (key == GLFW_KEY_ESCAPE && action == GLFW_PRESS) {
        glfwSetWindowShouldClose(window, GLFW_TRUE);
    }
    if (key == GLFW_KEY_F5 && action == GLFW_PRESS) {
        show_control_panel = !show_control_panel;
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
        // Terminate GLFW
        glfwTerminate();
        return EXIT_FAILURE;
    }

    glfwSetWindowTitle(window, "Hello World");
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

    // ── Setup Dear ImGui context ──────────────────────────────────────────────
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO(); (void)io;
    io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;     // Enable Keyboard Controls
    io.ConfigFlags |= ImGuiConfigFlags_NavEnableGamepad;      // Enable Gamepad Controls

    // Setup Dear ImGui style
    ImGui::StyleColorsDark();

    // Setup Platform/Renderer backends
    ImGui_ImplGlfw_InitForOpenGL(window, true);
    ImGui_ImplOpenGL3_Init("#version 330");

    char text_buffer[128] = "Hello OpenGL";

    // ── Main loop ─────────────────────────────────────────────────────────────
    while (!glfwWindowShouldClose(window)) {
        glClearColor(0.10f, 0.10f, 0.15f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT);

        // Start the Dear ImGui frame
        ImGui_ImplOpenGL3_NewFrame();
        ImGui_ImplGlfw_NewFrame();
        ImGui::NewFrame();

        // 1. Transparent background overlay window for the centered text
        ImGui::SetNextWindowPos(ImVec2(0, 0));
        ImGui::SetNextWindowSize(io.DisplaySize);
        ImGui::Begin("BackgroundText", nullptr,
            ImGuiWindowFlags_NoTitleBar |
            ImGuiWindowFlags_NoResize |
            ImGuiWindowFlags_NoMove |
            ImGuiWindowFlags_NoCollapse |
            ImGuiWindowFlags_NoScrollbar |
            ImGuiWindowFlags_NoBackground |
            ImGuiWindowFlags_NoInputs |
            ImGuiWindowFlags_NoNav |
            ImGuiWindowFlags_NoBringToFrontOnFocus
        );
        ImGui::SetWindowFontScale(3.0f); // Make text nice and large
        ImVec2 text_size = ImGui::CalcTextSize(text_buffer);
        ImGui::SetCursorPos(ImVec2((io.DisplaySize.x - text_size.x) * 0.5f, (io.DisplaySize.y - text_size.y) * 0.5f));
        ImGui::Text("%s", text_buffer);
        ImGui::End();

        // 2. Control Panel ImGui window
        if (show_control_panel) {
            ImGui::Begin("Control Panel");
            ImGui::InputText("Realtime Text", text_buffer, IM_ARRAYSIZE(text_buffer));
            ImGui::End();
        }

        // Render ImGui
        ImGui::Render();
        ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());

        glfwSwapBuffers(window);
        glfwPollEvents();
    }

    // ── Cleanup Dear ImGui ────────────────────────────────────────────────────
    ImGui_ImplOpenGL3_Shutdown();
    ImGui_ImplGlfw_Shutdown();
    ImGui::DestroyContext();

    glfwDestroyWindow(window);
    glfwTerminate();
    return EXIT_SUCCESS;
}