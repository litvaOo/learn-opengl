package main

import gl "vendor:OpenGL"
import glfw "vendor:glfw"


framebuffer_resize_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
  gl.Viewport(0, 0, width, height)
}

main :: proc() {
  glfw.Init()
  glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 4)
  glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 1)
  glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
  
  window := glfw.CreateWindow(800, 600, "Hello World", nil, nil)
  if window == nil {
    panic("Failed to create GLFW window")
  }
  glfw.MakeContextCurrent(window)
  glfw.SetFramebufferSizeCallback(window, framebuffer_resize_callback)
  gl.load_up_to(4, 1, glfw.gl_set_proc_address)

  gl.Viewport(0, 0, 800, 600)

  for !glfw.WindowShouldClose(window) {
    if glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS {
      glfw.SetWindowShouldClose(window, true)
    }
    gl.ClearColor(0.2, 0.3, 0.3, 1.0)
    gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
    glfw.SwapBuffers(window)
    glfw.PollEvents()
  }

  glfw.Terminate()
}
