package main

import gl "vendor:OpenGL"
import glfw "vendor:glfw"
import "core:strings"
import "core:math"
import "core:math/linalg"
import "core:fmt"

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

  shader_program := create_shader_program("shaders/shader.vert", "shaders/shader.frag")
  light_shader_program := create_shader_program("shaders/light_shader.vert", "shaders/light_shader.frag")
  cube_texture := create_texture("assets/container2.png")
  cube_specular := create_texture("assets/container2_specular.png")
  cube_emission := create_texture("assets/matrix.jpg")

  light_vao, cube_vao, vbo: u32
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


  gl.UseProgram(shader_program)
  static_uniforms: {
    gl.Uniform1i(gl.GetUniformLocation(shader_program, "material.diffuse"), 0)
    gl.Uniform1i(gl.GetUniformLocation(shader_program, "material.specular"), 1)
    gl.Uniform1i(gl.GetUniformLocation(shader_program, "material.emission"), 2)
    gl.Uniform1f(gl.GetUniformLocation(shader_program, "material.shininess"), shininess)
  }

  for !glfw.WindowShouldClose(window) {
    handle_input(window)
    current_frame := glfw.GetTime()
    delta_time = current_frame - last_frame
    last_frame = current_frame
    gl.ClearColor(0.1, 0.1, 0.1, 1.0)
    gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
    gl.UseProgram(shader_program)

    gl.Uniform3fv(gl.GetUniformLocation(shader_program, "dirLight.direction"), 1, raw_data([]f32{-0.2, -1.0, -0.3}));
    gl.Uniform3fv(gl.GetUniformLocation(shader_program, "dirLight.ambient"), 1, raw_data([]f32{0.05, 0.05, 0.05}));
    gl.Uniform3fv(gl.GetUniformLocation(shader_program, "dirLight.diffuse"), 1, raw_data([]f32{ 0.4, 0.4, 0.4 }));
    gl.Uniform3fv(gl.GetUniformLocation(shader_program, "dirLight.specular"), 1, raw_data([]f32{ 0.5, 0.5, 0.5}));
    gl.Uniform3fv(gl.GetUniformLocation(shader_program, "pointLights[0].position"), 1, raw_data(&point_light_positions[0]));
    gl.Uniform3fv(gl.GetUniformLocation(shader_program, "pointLights[0].ambient"), 1, raw_data([]f32{ 0.05, 0.05, 0.05}));
    gl.Uniform3fv(gl.GetUniformLocation(shader_program, "pointLights[0].diffuse"), 1, raw_data([]f32{0.8, 0.8, 0.8}));
    gl.Uniform3fv(gl.GetUniformLocation(shader_program, "pointLights[0].specular"), 1, raw_data([]f32{1.0, 1.0, 1.0}));
    gl.Uniform1f(gl.GetUniformLocation(shader_program, "pointLights[0].constant"), 1.0);
    gl.Uniform1f(gl.GetUniformLocation(shader_program, "pointLights[0].linear"), 0.09);
    gl.Uniform1f(gl.GetUniformLocation(shader_program, "pointLights[0].quadratic"), 0.032);
    gl.Uniform3fv(gl.GetUniformLocation(shader_program, "pointLights[1].position"), 1, raw_data(&point_light_positions[1] ));
    gl.Uniform3fv(gl.GetUniformLocation(shader_program, "pointLights[1].ambient"), 1, raw_data([]f32{0.05, 0.05, 0.05}));
    gl.Uniform3fv(gl.GetUniformLocation(shader_program, "pointLights[1].diffuse"), 1, raw_data([]f32{0.8, 0.8, 0.8}))
    gl.Uniform3fv(gl.GetUniformLocation(shader_program, "pointLights[1].specular"), 1, raw_data([]f32{1.0, 1.0, 1.0})) 
    gl.Uniform1f(gl.GetUniformLocation(shader_program, "pointLights[1].constant"), 1.0);
    gl.Uniform1f(gl.GetUniformLocation(shader_program, "pointLights[1].linear"), 0.09);
    gl.Uniform1f(gl.GetUniformLocation(shader_program, "pointLights[1].quadratic"), 0.032);
    gl.Uniform3fv(gl.GetUniformLocation(shader_program, "pointLights[2].position"), 1, raw_data(&point_light_positions[2] ));
    gl.Uniform3fv(gl.GetUniformLocation(shader_program, "pointLights[2].ambient"), 1, raw_data([]f32{0.05, 0.05, 0.05}));
    gl.Uniform3fv(gl.GetUniformLocation(shader_program, "pointLights[2].diffuse"), 1, raw_data([]f32{0.8, 0.8, 0.8}));
    gl.Uniform3fv(gl.GetUniformLocation(shader_program, "pointLights[2].specular"), 1, raw_data([]f32{1.0, 1.0, 1.0}));
    gl.Uniform1f(gl.GetUniformLocation(shader_program, "pointLights[2].constant"), 1.0);
    gl.Uniform1f(gl.GetUniformLocation(shader_program, "pointLights[2].linear"), 0.09);
    gl.Uniform1f(gl.GetUniformLocation(shader_program, "pointLights[2].quadratic"), 0.032);
    gl.Uniform3fv(gl.GetUniformLocation(shader_program, "pointLights[3].position"), 1, raw_data(&point_light_positions[3]));
    gl.Uniform3fv(gl.GetUniformLocation(shader_program, "pointLights[3].ambient"), 1, raw_data([]f32{0.05, 0.05, 0.05}));
    gl.Uniform3fv(gl.GetUniformLocation(shader_program, "pointLights[3].diffuse"), 1, raw_data([]f32{0.8, 0.8, 0.8}));
    gl.Uniform3fv(gl.GetUniformLocation(shader_program, "pointLights[3].specular"), 1, raw_data([]f32{1.0, 1.0, 1.0}));
    gl.Uniform1f(gl.GetUniformLocation(shader_program, "pointLights[3].constant"), 1.0);
    gl.Uniform1f(gl.GetUniformLocation(shader_program, "pointLights[3].linear"), 0.09);
    gl.Uniform1f(gl.GetUniformLocation(shader_program, "pointLights[3].quadratic"), 0.032);
    gl.Uniform3fv(gl.GetUniformLocation(shader_program, "spotLight.position"), 1, raw_data( &camera_pos ));
    gl.Uniform3fv(gl.GetUniformLocation(shader_program, "spotLight.direction"), 1, raw_data( &camera_front ));
    gl.Uniform3fv(gl.GetUniformLocation(shader_program, "spotLight.ambient"), 1, raw_data([]f32{0.0, 0.0, 0.0}));
    gl.Uniform3fv(gl.GetUniformLocation(shader_program, "spotLight.diffuse"), 1, raw_data([]f32{1.0, 1.0, 1.0}));
    gl.Uniform3fv(gl.GetUniformLocation(shader_program, "spotLight.specular"), 1, raw_data([]f32{1.0, 1.0, 1.0}));
    gl.Uniform1f(gl.GetUniformLocation(shader_program, "spotLight.constant"), 1.0);
    gl.Uniform1f(gl.GetUniformLocation(shader_program, "spotLight.linear"), 0.09);
    gl.Uniform1f(gl.GetUniformLocation(shader_program, "spotLight.quadratic"), 0.032);
    gl.Uniform1f(gl.GetUniformLocation(shader_program, "spotLight.cutOff"), math.cos(math.to_radians_f32(12.5)));
    gl.Uniform1f(gl.GetUniformLocation(shader_program, "spotLight.outerCutOff"), math.cos(math.to_radians_f32(15.0)));     

    projection := linalg.matrix4_perspective_f32(math.to_radians_f32(fov), 800.0 / 600.0, 0.1, 100.0)
    view := linalg.matrix4_look_at_f32(camera_pos, camera_pos + camera_front, camera_up)
    gl.UniformMatrix4fv(gl.GetUniformLocation(shader_program, "projection"), 1, false, raw_data(&projection))
    gl.UniformMatrix4fv(gl.GetUniformLocation(shader_program, "view"), 1, false, raw_data(&view))
    gl.Uniform3fv(gl.GetUniformLocation(shader_program, "cameraPos"), 1, raw_data(&camera_pos))

    gl.ActiveTexture(gl.TEXTURE0)
    gl.BindTexture(gl.TEXTURE_2D, cube_texture)
    gl.ActiveTexture(gl.TEXTURE1)
    gl.BindTexture(gl.TEXTURE_2D, cube_specular)
    gl.ActiveTexture(gl.TEXTURE2)
    gl.BindTexture(gl.TEXTURE_2D, cube_emission)
    gl.BindVertexArray(cube_vao)
    model := linalg.identity(matrix[4, 4]f32)
    for i in 0..<len(&cube_positions) {
      model = linalg.matrix_mul(linalg.identity(matrix[4, 4]f32), linalg.matrix4_translate_f32(cube_positions[i]))
      angle : f32 = 20.0 * f32(math.cos(glfw.GetTime())) * f32(i+1)
      model = linalg.matrix_mul(
          model, linalg.matrix4_rotate_f32(math.to_radians_f32(angle),
            f32(i+1) * Vector3{1.0, f32(math.cos(glfw.GetTime())), f32(math.sin(glfw.GetTime()))}))
      gl.UniformMatrix4fv(gl.GetUniformLocation(shader_program, "model"), 1, false, raw_data(&model))
      gl.DrawArrays(gl.TRIANGLES, 0, 36)
    }


    gl.UseProgram(light_shader_program)
    gl.UniformMatrix4fv(gl.GetUniformLocation(light_shader_program, "projection"), 1, false, raw_data(&projection))
    gl.UniformMatrix4fv(gl.GetUniformLocation(light_shader_program, "view"), 1, false, raw_data(&view))
    gl.BindVertexArray(light_vao)
    for i in 0..<len(point_light_positions) {
      light_color := Vector3{1.0, 1.0, 1.0}
      gl.Uniform3fv(gl.GetUniformLocation(light_shader_program, "lightColor"), 1, raw_data(&light_color))
      model = linalg.matrix_mul(linalg.matrix4_translate_f32(point_light_positions[i]), linalg.matrix4_scale_f32(0.2))
      gl.UniformMatrix4fv(gl.GetUniformLocation(light_shader_program, "model"), 1, false, raw_data(&model))
      gl.DrawArrays(gl.TRIANGLES, 0, 36)
    }

    glfw.SwapBuffers(window)
    glfw.PollEvents()
  }

  glfw.Terminate()
}
