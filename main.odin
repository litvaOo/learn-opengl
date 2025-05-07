package main

import gl "vendor:OpenGL"
import glfw "vendor:glfw"
import "core:strings"

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


  vertices := []f32{
     0.5,  0.5, 0.0,
     0.5, -0.5, 0.0,
    -0.5, -0.5, 0.0,
    -0.5,  0.5, 0.0,
  }

  indices := []u32{
    0, 1, 3,
    1, 2, 3,
  }


  vertex_shader := gl.CreateShader(gl.VERTEX_SHADER)
  vertex_shader_source_raw := read_file("shaders/shader.vert")
  vertex_shader_source := cstring(raw_data(vertex_shader_source_raw))
  gl.ShaderSource(vertex_shader, 1, &vertex_shader_source, nil)
  gl.CompileShader(vertex_shader)

  fragment_shader := gl.CreateShader(gl.FRAGMENT_SHADER)
  fragment_shader_source_raw := read_file("shaders/shader.frag")
  fragment_shader_source := cstring(raw_data(fragment_shader_source_raw))
  gl.ShaderSource(fragment_shader, 1, &fragment_shader_source, nil)
  gl.CompileShader(fragment_shader)

  shader_program := gl.CreateProgram()
  gl.AttachShader(shader_program, vertex_shader)
  gl.AttachShader(shader_program, fragment_shader)
  gl.LinkProgram(shader_program)

  vao, vbo, ebo: u32
  gl.GenBuffers(1, &ebo)
  gl.GenVertexArrays(1, &vao)
  gl.GenBuffers(1, &vbo)

  gl.BindVertexArray(vao)

  gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
  gl.BufferData(gl.ARRAY_BUFFER, len(vertices) * size_of(f32), raw_data(vertices), gl.STATIC_DRAW)

  gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
  gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(indices) * size_of(u32), raw_data(indices), gl.STATIC_DRAW)

  gl.VertexAttribPointer(0, 3, gl.FLOAT, false, 3 * size_of(f32), 0)
  gl.EnableVertexAttribArray(0)

  gl.BindBuffer(gl.ARRAY_BUFFER, 0)
  gl.BindVertexArray(0)


  wireframe_mode := false
  space_pressed := false
  for !glfw.WindowShouldClose(window) {
    if glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS {
      glfw.SetWindowShouldClose(window, true)
    }
    if glfw.GetKey(window, glfw.KEY_SPACE) == glfw.PRESS {
      if !space_pressed {
        space_pressed = true
        if wireframe_mode {
          gl.PolygonMode(gl.FRONT_AND_BACK, gl.FILL)
          wireframe_mode = false
        } else {
          gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE)
          wireframe_mode = true
        }
      }
    }
    if glfw.GetKey(window, glfw.KEY_SPACE) == glfw.RELEASE {
      if space_pressed {
        space_pressed = false
      }
    }
    gl.ClearColor(0.2, 0.3, 0.3, 1.0)
    gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
    gl.UseProgram(shader_program)
    gl.BindVertexArray(vao)
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
    gl.DrawElements(gl.TRIANGLES, i32(len(indices)), gl.UNSIGNED_INT, nil)
    glfw.SwapBuffers(window)
    glfw.PollEvents()
  }

  glfw.Terminate()
}
