package ui

import "core:strings"
import "vendor:glfw"
import gl "vendor:OpenGL"

Errors :: enum {
    InitSucceeded,
    InitFailed,
    CreateWindowFailed,
}

Window :: struct {
    glfw_handle: glfw.WindowHandle,
    shader: u32,
    vao: u32,
    vbo: u32,
}

init :: proc(title: string, width: i32, height: i32) -> (frame: ^Window, err: Errors) {
    if !glfw.Init() {
        return nil, .InitFailed
    }
    window := new(Window)

    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 3)
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 3)
    glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

    window.glfw_handle = glfw.CreateWindow(width, height, strings.clone_to_cstring(title), nil, nil)
    if window.glfw_handle == nil {
        return nil, .CreateWindowFailed
    }

    glfw.MakeContextCurrent(window.glfw_handle)
    gl.load_up_to(4, 5, glfw.gl_set_proc_address)
    return window, .InitSucceeded
}

destroy :: proc(window: ^Window) {
    glfw.DestroyWindow(window.glfw_handle)
    glfw.Terminate()
    free(window)
}

draw :: proc(window: ^Window) {
    gl.ClearColor(0.2, 0.3, 0.3, 1.0)
    gl.Clear(gl.COLOR_BUFFER_BIT)
    glfw.PollEvents()
}

should_exit :: proc(window: ^Window) -> bool {
    return glfw.WindowShouldClose(window.glfw_handle) == true
}
