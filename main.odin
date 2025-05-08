package main

import gl "vendor:OpenGL"
import glfw "vendor:glfw"
import "core:strings"
import "core:math"

framebuffer_resize_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
  gl.Viewport(0, 0, width, height)
}

main :: proc() {
  window: glfw.WindowHandle
  init: {
    glfw.Init()
    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 4)
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 1)
    glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
    
    window = glfw.CreateWindow(800, 600, "Hello World", nil, nil)
    if window == nil {
      panic("Failed to create GLFW window")
    }
    glfw.MakeContextCurrent(window)
    glfw.SetFramebufferSizeCallback(window, framebuffer_resize_callback)
    gl.load_up_to(4, 1, glfw.gl_set_proc_address)
  }

  vertices := []f32{
     0.5,  0.5, 0.0,   1.0, 0.0, 0.0,   1.0, 1.0,
     0.5, -0.5, 0.0,   0.0, 1.0, 0.0,   1.0, 0.0,
    -0.5, -0.5, 0.0,   0.0, 0.0, 1.0,   0.0, 0.0,
    -0.5,  0.5, 0.0,   1.0, 1.0, 0.0,   0.0, 1.0,
  }

  indices := []i32{
      0, 1, 3,
      1, 2, 3,
  };

  shader_program := gl.CreateProgram()
  shaders: {
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

    gl.AttachShader(shader_program, vertex_shader)
    gl.AttachShader(shader_program, fragment_shader)
    gl.LinkProgram(shader_program)
  }


  vao, vbo, ebo: u32
  gl.GenBuffers(1, &ebo)
  gl.GenVertexArrays(1, &vao)
  gl.GenBuffers(1, &vbo)

  gl.BindVertexArray(vao)

  gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
  gl.BufferData(gl.ARRAY_BUFFER, len(vertices) * size_of(f32), raw_data(vertices), gl.STATIC_DRAW)

  gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
  gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(indices) * size_of(i32), raw_data(indices), gl.STATIC_DRAW)

  gl.VertexAttribPointer(0, 3, gl.FLOAT, false, 8 * size_of(f32), 0)
  gl.EnableVertexAttribArray(0)

  gl.VertexAttribPointer(1, 3, gl.FLOAT, false, 8 * size_of(f32), 3 * size_of(f32))
  gl.EnableVertexAttribArray(1)

  gl.VertexAttribPointer(2, 2, gl.FLOAT, false, 8 * size_of(f32), 6 * size_of(f32))
  gl.EnableVertexAttribArray(2)

  wireframe_mode := false
  space_pressed := false

  gl.UseProgram(shader_program)
  gl.Uniform1i(gl.GetUniformLocation(shader_program, "inTexture"), 0)
  gl.Uniform1i(gl.GetUniformLocation(shader_program, "inTexture2"), 1)

  vertex_offset_location := gl.GetUniformLocation(shader_program, "offsetVec")
  vertex_offset := []f32{0.5, 0.5, 0.5}
  gl.Uniform3fv(vertex_offset_location, 1, raw_data(vertex_offset))

  texture_1, texture_2: u32
  textures: {
    gl.GenTextures(1, &texture_1)
    gl.BindTexture(gl.TEXTURE_2D, texture_1)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
    width, height, texture_data_1 := read_texture("assets/container.jpg")
    gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGB, width, height, 0, gl.RGB, gl.UNSIGNED_BYTE, texture_data_1)
    gl.GenerateMipmap(gl.TEXTURE_2D)

    gl.GenTextures(1, &texture_2)
    gl.BindTexture(gl.TEXTURE_2D, texture_2)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
    texture_data_2: [^]u8
    width, height, texture_data_2 = read_texture("assets/awesomeface.png")
    gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, width, height, 0, gl.RGBA, gl.UNSIGNED_BYTE, texture_data_2)
    gl.GenerateMipmap(gl.TEXTURE_2D)
  }


  mix_factor_location := gl.GetUniformLocation(shader_program, "mixFactor")
  mix_factor :f32 = 0.2
  for !glfw.WindowShouldClose(window) {
    input: {
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
      if glfw.GetKey(window, glfw.KEY_UP) == glfw.PRESS {
        if mix_factor < 1.0 {
          mix_factor += 0.01
        }
      }
      if glfw.GetKey(window, glfw.KEY_DOWN) == glfw.PRESS {
        if mix_factor > 0.0 {
          mix_factor -= 0.01
        }
      }
    }
    gl.ClearColor(0.2, 0.3, 0.3, 1.0)
    gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
    gl.ActiveTexture(gl.TEXTURE0)
    gl.BindTexture(gl.TEXTURE_2D, texture_1)
    gl.ActiveTexture(gl.TEXTURE1)
    gl.BindTexture(gl.TEXTURE_2D, texture_2)
    gl.BindVertexArray(vao)
    gl.Uniform1f(mix_factor_location, mix_factor)
    gl.DrawElements(gl.TRIANGLES, i32(len(indices)), gl.UNSIGNED_INT, nil)
    glfw.SwapBuffers(window)
    glfw.PollEvents()
  }

  glfw.Terminate()
}
