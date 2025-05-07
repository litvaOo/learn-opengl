package main

import gl "vendor:OpenGL"
import glfw "vendor:glfw"
import "core:strings"
import "core:math"

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

  vertices := []f32{
     0.5, -0.5, 0.0,  1.0, 0.0, 0.0,
    -0.5, -0.5, 0.0,  0.0, 1.0, 0.0,
     0.0,  0.5, 0.0,  0.0, 0.0, 1.0 
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

  vao, vbo: u32
  gl.GenVertexArrays(1, &vao)
  gl.GenBuffers(1, &vbo)

  gl.BindVertexArray(vao)

  gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
  gl.BufferData(gl.ARRAY_BUFFER, len(vertices) * size_of(f32), raw_data(vertices), gl.STATIC_DRAW)

  gl.VertexAttribPointer(0, 3, gl.FLOAT, false, 6 * size_of(f32), 0)
  gl.EnableVertexAttribArray(0)

  gl.VertexAttribPointer(1, 3, gl.FLOAT, false, 6 * size_of(f32), 3 * size_of(f32))
  gl.EnableVertexAttribArray(1)

  wireframe_mode := false
  space_pressed := false

  gl.UseProgram(shader_program)
  vertex_offset_location := gl.GetUniformLocation(shader_program, "offsetVec")
  vertex_offset := []f32{0.5, 0.5, 0.5}
  gl.Uniform3fv(vertex_offset_location, 1, raw_data(vertex_offset))

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
    gl.BindVertexArray(vao)
    gl.DrawArrays(gl.TRIANGLES, 0, 3)

    glfw.SwapBuffers(window)
    glfw.PollEvents()
  }

  glfw.Terminate()
}
