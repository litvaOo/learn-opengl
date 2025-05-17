package main

import gl "vendor:OpenGL"
import glfw "vendor:glfw"
import "core:strings"
import "core:math"
import "core:math/linalg"

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
    gl.Enable(gl.DEPTH_TEST)
  }

  vertices := []f32{
    -0.5, -0.5, -0.5,  0.0,  0.0, -1.0,  0.0, 0.0,
     0.5, -0.5, -0.5,  0.0,  0.0, -1.0,  1.0, 0.0,
     0.5,  0.5, -0.5,  0.0,  0.0, -1.0,  1.0, 1.0,
     0.5,  0.5, -0.5,  0.0,  0.0, -1.0,  1.0, 1.0,
    -0.5,  0.5, -0.5,  0.0,  0.0, -1.0,  0.0, 1.0,
    -0.5, -0.5, -0.5,  0.0,  0.0, -1.0,  0.0, 0.0,

    -0.5, -0.5,  0.5,  0.0,  0.0, 1.0,   0.0, 0.0,
     0.5, -0.5,  0.5,  0.0,  0.0, 1.0,   1.0, 0.0,
     0.5,  0.5,  0.5,  0.0,  0.0, 1.0,   1.0, 1.0,
     0.5,  0.5,  0.5,  0.0,  0.0, 1.0,   1.0, 1.0,
    -0.5,  0.5,  0.5,  0.0,  0.0, 1.0,   0.0, 1.0,
    -0.5, -0.5,  0.5,  0.0,  0.0, 1.0,   0.0, 0.0,

    -0.5,  0.5,  0.5, -1.0,  0.0,  0.0,  1.0, 0.0,
    -0.5,  0.5, -0.5, -1.0,  0.0,  0.0,  1.0, 1.0,
    -0.5, -0.5, -0.5, -1.0,  0.0,  0.0,  0.0, 1.0,
    -0.5, -0.5, -0.5, -1.0,  0.0,  0.0,  0.0, 1.0,
    -0.5, -0.5,  0.5, -1.0,  0.0,  0.0,  0.0, 0.0,
    -0.5,  0.5,  0.5, -1.0,  0.0,  0.0,  1.0, 0.0,

     0.5,  0.5,  0.5,  1.0,  0.0,  0.0,  1.0, 0.0,
     0.5,  0.5, -0.5,  1.0,  0.0,  0.0,  1.0, 1.0,
     0.5, -0.5, -0.5,  1.0,  0.0,  0.0,  0.0, 1.0,
     0.5, -0.5, -0.5,  1.0,  0.0,  0.0,  0.0, 1.0,
     0.5, -0.5,  0.5,  1.0,  0.0,  0.0,  0.0, 0.0,
     0.5,  0.5,  0.5,  1.0,  0.0,  0.0,  1.0, 0.0,

    -0.5, -0.5, -0.5,  0.0, -1.0,  0.0,  0.0, 1.0,
     0.5, -0.5, -0.5,  0.0, -1.0,  0.0,  1.0, 1.0,
     0.5, -0.5,  0.5,  0.0, -1.0,  0.0,  1.0, 0.0,
     0.5, -0.5,  0.5,  0.0, -1.0,  0.0,  1.0, 0.0,
    -0.5, -0.5,  0.5,  0.0, -1.0,  0.0,  0.0, 0.0,
    -0.5, -0.5, -0.5,  0.0, -1.0,  0.0,  0.0, 1.0,

    -0.5,  0.5, -0.5,  0.0,  1.0,  0.0,  0.0, 1.0,
     0.5,  0.5, -0.5,  0.0,  1.0,  0.0,  1.0, 1.0,
     0.5,  0.5,  0.5,  0.0,  1.0,  0.0,  1.0, 0.0,
     0.5,  0.5,  0.5,  0.0,  1.0,  0.0,  1.0, 0.0,
    -0.5,  0.5,  0.5,  0.0,  1.0,  0.0,  0.0, 0.0,
    -0.5,  0.5, -0.5,  0.0,  1.0,  0.0,  0.0, 1.0,
  }


  shader_program := create_shader_program("shaders/shader.vert", "shaders/shader.frag")
  light_shader_program := create_shader_program("shaders/light_shader.vert", "shaders/light_shader.frag")

  light_vao, cube_vao, vbo: u32
  vaos := []u32{light_vao, cube_vao}
  buffer_setup: {
    gl.GenVertexArrays(1, &cube_vao)
    gl.GenBuffers(1, &vbo)

    gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
    gl.BufferData(gl.ARRAY_BUFFER, len(vertices) * size_of(f32), raw_data(vertices), gl.STATIC_DRAW)

    gl.BindVertexArray(cube_vao)

    gl.VertexAttribPointer(0, 3, gl.FLOAT, false, 8 * size_of(f32), 0)
    gl.EnableVertexAttribArray(0)
    gl.VertexAttribPointer(1, 3, gl.FLOAT, false, 8 * size_of(f32), 3 * size_of(f32))
    gl.EnableVertexAttribArray(1)
    gl.VertexAttribPointer(2, 2, gl.FLOAT, false, 8 * size_of(f32), 6 * size_of(f32))
    gl.EnableVertexAttribArray(2)

    gl.GenVertexArrays(1, &light_vao)
    gl.BindVertexArray(light_vao)
    gl.BindBuffer(gl.ARRAY_BUFFER, vbo)

    gl.VertexAttribPointer(0, 3, gl.FLOAT, false, 8 * size_of(f32), 0)
    gl.EnableVertexAttribArray(0)
  }

  light_pos := Vector3{1.2, 1.0, 2.0}
  gl.UseProgram(shader_program)

  cube_texture := create_texture("assets/container2.png")
  cube_specular := create_texture("assets/container2_specular.png")
  cube_emission := create_texture("assets/matrix.jpg")

  gl.UseProgram(shader_program)
  gl.Uniform1i(gl.GetUniformLocation(shader_program, "material.diffuse"), 0)
  gl.Uniform1i(gl.GetUniformLocation(shader_program, "material.specular"), 1)
  gl.Uniform1i(gl.GetUniformLocation(shader_program, "material.emission"), 2)
  for !glfw.WindowShouldClose(window) {
    handle_input(window)
    current_frame := glfw.GetTime()
    delta_time = current_frame - last_frame
    last_frame = current_frame
    gl.ClearColor(0.1, 0.1, 0.1, 1.0)
    gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
    gl.UseProgram(shader_program)
    shininess := f32(32)
    gl.Uniform1f(gl.GetUniformLocation(shader_program, "material.shininess"), shininess)

    light_color: Vector3
    light_color.r = math.sin(f32( current_frame * 2.0 )) / 2.0 + 0.5
    light_color.g = math.sin(f32( current_frame * 0.7 )) / 2.0 + 0.5
    light_color.b = math.sin(f32( current_frame * 1.3 )) / 2.0 + 0.5
    light_diffuse := light_color * 0.5
    light_ambient := light_color * 0.2
    light_specular := Vector3{1.0, 1.0, 1.0}
    gl.Uniform3fv(gl.GetUniformLocation(shader_program, "light.ambient"), 1, raw_data(&light_ambient))
    gl.Uniform3fv(gl.GetUniformLocation(shader_program, "light.diffuse"), 1, raw_data(&light_diffuse))
    gl.Uniform3fv(gl.GetUniformLocation(shader_program, "light.specular"), 1, raw_data(&light_specular))

    light_pos.y = math.sin(f32(current_frame))
    light_pos.x = math.cos(f32(current_frame))
    light_pos.z = math.cos(f32(current_frame))

    projection := linalg.matrix4_perspective_f32(math.to_radians_f32(fov), 800.0 / 600.0, 0.1, 100.0)
    view := linalg.matrix4_look_at_f32(camera_pos, camera_pos + camera_front, camera_up)
    gl.UniformMatrix4fv(gl.GetUniformLocation(shader_program, "projection"), 1, false, raw_data(&projection))
    gl.UniformMatrix4fv(gl.GetUniformLocation(shader_program, "view"), 1, false, raw_data(&view))

    model := linalg.identity(matrix[4, 4]f32)
    gl.UniformMatrix4fv(gl.GetUniformLocation(shader_program, "model"), 1, false, raw_data(&model))
    gl.Uniform3fv(gl.GetUniformLocation(shader_program, "light.position"), 1, raw_data(&light_pos))
    gl.Uniform3fv(gl.GetUniformLocation(shader_program, "cameraPos"), 1, raw_data(&camera_pos))

    gl.ActiveTexture(gl.TEXTURE0)
    gl.BindTexture(gl.TEXTURE_2D, cube_texture)
    gl.ActiveTexture(gl.TEXTURE1)
    gl.BindTexture(gl.TEXTURE_2D, cube_specular)
    gl.ActiveTexture(gl.TEXTURE2)
    gl.BindTexture(gl.TEXTURE_2D, cube_emission)
    gl.BindVertexArray(cube_vao)
    gl.DrawArrays(gl.TRIANGLES, 0, 36)

    gl.UseProgram(light_shader_program)
    gl.Uniform3fv(gl.GetUniformLocation(light_shader_program, "lightColor"), 1, raw_data(&light_color))
    gl.UniformMatrix4fv(gl.GetUniformLocation(light_shader_program, "projection"), 1, false, raw_data(&projection))
    gl.UniformMatrix4fv(gl.GetUniformLocation(light_shader_program, "view"), 1, false, raw_data(&view))
    model = linalg.matrix_mul(linalg.matrix4_translate_f32(light_pos), linalg.matrix4_scale_f32(0.2))
    gl.UniformMatrix4fv(gl.GetUniformLocation(light_shader_program, "model"), 1, false, raw_data(&model))
    gl.BindVertexArray(light_vao)
    gl.DrawArrays(gl.TRIANGLES, 0, 36)

    glfw.SwapBuffers(window)
    glfw.PollEvents()
  }

  glfw.Terminate()
}
