package main

import gl "vendor:OpenGL"
import glfw "vendor:glfw"
import "core:strings"
import "core:math"
import "core:math/linalg"

last_x, last_y : f32 = 400, 300
yaw : f32 = -90.0
pitch : f32 = 0
first_mouse := true
camera_pos := Vector3{0.0, 0.0, 3.0}
camera_front := Vector3{0.0, 0.0, -1.0}
camera_up := Vector3{0.0, 1.0, 0.0}
camera_speed : f32 = 0.05
fov : f32 = 45.0

Vector4 :: [4]f32
Vector3 :: [3]f32
Vector2 :: [2]f32

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
    glfw.SetInputMode(window, glfw.CURSOR, glfw.CURSOR_DISABLED)
    glfw.SetCursorPosCallback(window, mouse_callback)
    glfw.SetScrollCallback(window, scroll_callback)
    glfw.MakeContextCurrent(window)
    glfw.SetFramebufferSizeCallback(window, framebuffer_resize_callback)
    gl.load_up_to(4, 1, glfw.gl_set_proc_address)
  }

  vertices := []f32{
    -0.5, -0.5, -0.5,  0.0, 0.0,
     0.5, -0.5, -0.5,  1.0, 0.0,
     0.5,  0.5, -0.5,  1.0, 1.0,
     0.5,  0.5, -0.5,  1.0, 1.0,
    -0.5,  0.5, -0.5,  0.0, 1.0,
    -0.5, -0.5, -0.5,  0.0, 0.0,

    -0.5, -0.5,  0.5,  0.0, 0.0,
     0.5, -0.5,  0.5,  1.0, 0.0,
     0.5,  0.5,  0.5,  1.0, 1.0,
     0.5,  0.5,  0.5,  1.0, 1.0,
    -0.5,  0.5,  0.5,  0.0, 1.0,
    -0.5, -0.5,  0.5,  0.0, 0.0,

    -0.5,  0.5,  0.5,  1.0, 0.0,
    -0.5,  0.5, -0.5,  1.0, 1.0,
    -0.5, -0.5, -0.5,  0.0, 1.0,
    -0.5, -0.5, -0.5,  0.0, 1.0,
    -0.5, -0.5,  0.5,  0.0, 0.0,
    -0.5,  0.5,  0.5,  1.0, 0.0,

     0.5,  0.5,  0.5,  1.0, 0.0,
     0.5,  0.5, -0.5,  1.0, 1.0,
     0.5, -0.5, -0.5,  0.0, 1.0,
     0.5, -0.5, -0.5,  0.0, 1.0,
     0.5, -0.5,  0.5,  0.0, 0.0,
     0.5,  0.5,  0.5,  1.0, 0.0,

    -0.5, -0.5, -0.5,  0.0, 1.0,
     0.5, -0.5, -0.5,  1.0, 1.0,
     0.5, -0.5,  0.5,  1.0, 0.0,
     0.5, -0.5,  0.5,  1.0, 0.0,
    -0.5, -0.5,  0.5,  0.0, 0.0,
    -0.5, -0.5, -0.5,  0.0, 1.0,

    -0.5,  0.5, -0.5,  0.0, 1.0,
     0.5,  0.5, -0.5,  1.0, 1.0,
     0.5,  0.5,  0.5,  1.0, 0.0,
     0.5,  0.5,  0.5,  1.0, 0.0,
    -0.5,  0.5,  0.5,  0.0, 0.0,
    -0.5,  0.5, -0.5,  0.0, 1.0
  }


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

    gl.Enable(gl.DEPTH_TEST)
  }


  vao, vbo: u32
  buffer_setup: {
    gl.GenVertexArrays(1, &vao)
    gl.GenBuffers(1, &vbo)

    gl.BindVertexArray(vao)

    gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
    gl.BufferData(gl.ARRAY_BUFFER, len(vertices) * size_of(f32), raw_data(vertices), gl.STATIC_DRAW)

    gl.VertexAttribPointer(0, 3, gl.FLOAT, false, 5 * size_of(f32), 0)
    gl.EnableVertexAttribArray(0)

    gl.VertexAttribPointer(1, 3, gl.FLOAT, false, 5 * size_of(f32), 3 * size_of(f32))
    gl.EnableVertexAttribArray(1)

  }


  texture_1, texture_2: u32
  textures: {
    gl.UseProgram(shader_program)

    gl.Uniform1i(gl.GetUniformLocation(shader_program, "inTexture"), 0)
    gl.Uniform1i(gl.GetUniformLocation(shader_program, "inTexture2"), 1)
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
  wireframe_mode := false
  space_pressed := false

  delta_time := 0.0
  last_frame := 0.0
  for !glfw.WindowShouldClose(window) {
    current_frame := glfw.GetTime()
    delta_time = current_frame - last_frame
    last_frame = current_frame
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

      camera_processing: {
        camera_speed = 2.5 * f32( delta_time )
        if glfw.GetKey(window, glfw.KEY_W) == glfw.PRESS {
          camera_pos += camera_speed * camera_front
        }
        if glfw.GetKey(window, glfw.KEY_S) == glfw.PRESS {
          camera_pos -= camera_speed * camera_front
        }
        if glfw.GetKey(window, glfw.KEY_A) == glfw.PRESS {
          camera_pos -= linalg.normalize(linalg.cross(camera_front, camera_up)) * camera_speed
        }
        if glfw.GetKey(window, glfw.KEY_D) == glfw.PRESS {
          camera_pos += linalg.normalize(linalg.cross(camera_front, camera_up)) * camera_speed
        }
      }
    }
    gl.Uniform1f(mix_factor_location, mix_factor)
    gl.ClearColor(0.2, 0.3, 0.3, 1.0)
    gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
    gl.ActiveTexture(gl.TEXTURE0)
    gl.BindTexture(gl.TEXTURE_2D, texture_1)
    gl.ActiveTexture(gl.TEXTURE1)
    gl.BindTexture(gl.TEXTURE_2D, texture_2)
    gl.BindVertexArray(vao)
    cubePositions := []Vector3{
      {0.0,  0.0,  0.0},
      {2.0,  5.0, -15.0},
      {-1.5, -2.2, -2.5},
      {-3.8, -2.0, -12.3},
      {2.4, -0.4, -3.5},
      {-1.7,  3.0, -7.5},
      {1.3, -2.0, -2.5},
      {1.5,  2.0, -2.5},
      {1.5,  0.2, -1.5},
      {-1.3,  1.0, -1.5},
    }
    for i in 0..<len(cubePositions) {
      position := cubePositions[i]
      angle := f32(i+1) * 20.0
      model_matrix := linalg.matrix_mul(linalg.matrix4_translate_f32(position), linalg.matrix4_rotate_f32(f32(glfw.GetTime()) * math.to_radians_f32(angle), Vector3{1.0, 0.3, 0.5} ))
      radius : f32 = 10.0
      cam_x := math.sin(f32( glfw.GetTime() )) * radius
      cam_z := math.cos(f32( glfw.GetTime() )) * radius
      view_matrix := linalg.matrix4_look_at_f32(camera_pos, camera_pos + camera_front, camera_up)
      view_matrix = linalg.matrix_mul(view_matrix, linalg.matrix4_translate_f32(Vector3{0.0, 0.0, -3.0} ))
      projection_matrix := linalg.matrix4_perspective_f32(math.to_radians_f32(fov), 800.0/600.0, 0.1, 100.0)

      gl.UniformMatrix4fv(gl.GetUniformLocation(shader_program, "model"), 1, false, raw_data(&model_matrix))
      gl.UniformMatrix4fv(gl.GetUniformLocation(shader_program, "view"), 1, false, raw_data(&view_matrix))
      gl.UniformMatrix4fv(gl.GetUniformLocation(shader_program, "projection"), 1, false, raw_data(&projection_matrix))
      gl.DrawArrays(gl.TRIANGLES, 0, 36)
    }

    glfw.SwapBuffers(window)
    glfw.PollEvents()
  }

  glfw.Terminate()
}
