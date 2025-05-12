package main

import gl "vendor:OpenGL"
import glfw "vendor:glfw"
import "core:strings"
import "core:math"
import "core:math/linalg"

mix_factor :f32 = 0.2
wireframe_mode := false
space_pressed := false

delta_time := 0.0
last_frame := 0.0
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

look_at :: proc(position, target, up: Vector3) -> matrix[4, 4]f32{
  camera_matrix := linalg.identity(matrix[4, 4]f32)
  camera_matrix[0][3] = -position.x
  camera_matrix[1][3] = -position.y
  camera_matrix[2][3] = -position.z

  right_vector := linalg.cross(up, target)

  result := linalg.identity(matrix[4, 4]f32)
  result[0][0] = right_vector.x
  result[0][1] = right_vector.y
  result[0][2] = right_vector.z
  result[1][0] = up.x
  result[1][1] = up.y
  result[1][2] = up.z
  result[2][0] = target.x
  result[2][1] = target.y
  result[2][2] = target.z
  return linalg.matrix_mul(camera_matrix, result)
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
    glfw.SetInputMode(window, glfw.CURSOR, glfw.CURSOR_DISABLED)
    glfw.SetCursorPosCallback(window, mouse_callback)
    glfw.SetScrollCallback(window, scroll_callback)
    glfw.MakeContextCurrent(window)
    glfw.SetFramebufferSizeCallback(window, framebuffer_resize_callback)
    gl.load_up_to(4, 1, glfw.gl_set_proc_address)
  }

  vertices := []f32{
    -0.5, -0.5, -0.5, 
    0.5, -0.5, -0.5,  
    0.5,  0.5, -0.5,  
    0.5,  0.5, -0.5,  
    -0.5,  0.5, -0.5, 
    -0.5, -0.5, -0.5, 

    -0.5, -0.5,  0.5, 
    0.5, -0.5,  0.5,  
    0.5,  0.5,  0.5,  
    0.5,  0.5,  0.5,  
    -0.5,  0.5,  0.5, 
    -0.5, -0.5,  0.5, 

    -0.5,  0.5,  0.5, 
    -0.5,  0.5, -0.5, 
    -0.5, -0.5, -0.5, 
    -0.5, -0.5, -0.5, 
    -0.5, -0.5,  0.5, 
    -0.5,  0.5,  0.5, 

    0.5,  0.5,  0.5,  
    0.5,  0.5, -0.5,  
    0.5, -0.5, -0.5,  
    0.5, -0.5, -0.5,  
    0.5, -0.5,  0.5,  
    0.5,  0.5,  0.5,  

    -0.5, -0.5, -0.5, 
    0.5, -0.5, -0.5,  
    0.5, -0.5,  0.5,  
    0.5, -0.5,  0.5,  
    -0.5, -0.5,  0.5, 
    -0.5, -0.5, -0.5, 

    -0.5,  0.5, -0.5, 
    0.5,  0.5, -0.5,  
    0.5,  0.5,  0.5,  
    0.5,  0.5,  0.5,  
    -0.5,  0.5,  0.5, 
    -0.5,  0.5, -0.5, 
  }


  shader_program := gl.CreateProgram()
  light_shader_program := gl.CreateProgram()
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

    vertex_shader_light := gl.CreateShader(gl.VERTEX_SHADER)
    vertex_shader_light_source_raw := read_file("shaders/light_shader.vert")
    vertex_shader_light_source := cstring(raw_data(vertex_shader_light_source_raw))
    gl.ShaderSource(vertex_shader_light, 1, &vertex_shader_light_source, nil)
    gl.CompileShader(vertex_shader_light)

    fragment_shader_light := gl.CreateShader(gl.FRAGMENT_SHADER)
    fragment_shader_light_source_raw := read_file("shaders/light_shader.frag")
    fragment_shader_light_source := cstring(raw_data(fragment_shader_light_source_raw))
    gl.ShaderSource(fragment_shader_light, 1, &fragment_shader_light_source, nil)
    gl.CompileShader(fragment_shader_light)

    gl.AttachShader(light_shader_program, vertex_shader_light)
    gl.AttachShader(light_shader_program, fragment_shader_light)
    gl.LinkProgram(light_shader_program)

    gl.Enable(gl.DEPTH_TEST)
  }

  light_vao, cube_vao, vbo: u32
  vaos := []u32{light_vao, cube_vao}
  buffer_setup: {
    gl.GenVertexArrays(1, &cube_vao)
    gl.GenBuffers(1, &vbo)

    gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
    gl.BufferData(gl.ARRAY_BUFFER, len(vertices) * size_of(f32), raw_data(vertices), gl.STATIC_DRAW)

    gl.BindVertexArray(cube_vao)

    gl.VertexAttribPointer(0, 3, gl.FLOAT, false, 3 * size_of(f32), 0)
    gl.EnableVertexAttribArray(0)

    gl.GenVertexArrays(1, &light_vao)
    gl.BindVertexArray(light_vao)
    gl.BindBuffer(gl.ARRAY_BUFFER, vbo)

    gl.VertexAttribPointer(0, 3, gl.FLOAT, false, 3 * size_of(f32), 0)
    gl.EnableVertexAttribArray(0)
  }

  for !glfw.WindowShouldClose(window) {
    handle_input(window)
    current_frame := glfw.GetTime()
    delta_time = current_frame - last_frame
    last_frame = current_frame
    gl.ClearColor(0.1, 0.1, 0.1, 1.0)
    gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
    gl.UseProgram(shader_program)
    object_color_position := gl.GetUniformLocation(shader_program, "objectColor")
    light_color_position := gl.GetUniformLocation(shader_program, "lightColor")
    light_color := Vector3{1.0, 1.0, 1.0}
    object_color := Vector3{1.0, 0.5, 0.31}
    gl.Uniform3fv(object_color_position, 1, raw_data(&object_color))
    gl.Uniform3fv(light_color_position, 1, raw_data(&light_color))

    projection := linalg.matrix4_perspective_f32(math.to_radians_f32(fov), 800.0 / 600.0, 0.1, 100.0)
    view := linalg.matrix4_look_at_f32(camera_pos, camera_pos + camera_front, camera_up)
    gl.UniformMatrix4fv(gl.GetUniformLocation(shader_program, "projection"), 1, false, raw_data(&projection))
    gl.UniformMatrix4fv(gl.GetUniformLocation(shader_program, "view"), 1, false, raw_data(&view))
    
    model := linalg.identity(matrix[4, 4]f32)
    gl.UniformMatrix4fv(gl.GetUniformLocation(shader_program, "model"), 1, false, raw_data(&model))
    gl.BindVertexArray(cube_vao)
    gl.DrawArrays(gl.TRIANGLES, 0, 36)

    gl.UseProgram(light_shader_program)
    gl.UniformMatrix4fv(gl.GetUniformLocation(light_shader_program, "projection"), 1, false, raw_data(&projection))
    gl.UniformMatrix4fv(gl.GetUniformLocation(light_shader_program, "view"), 1, false, raw_data(&view))
    light_pos := Vector3{1.2, 1.0, 2.0}
    model = linalg.matrix_mul(linalg.matrix4_translate_f32(light_pos), linalg.matrix4_scale_f32(0.2))
    gl.UniformMatrix4fv(gl.GetUniformLocation(light_shader_program, "model"), 1, false, raw_data(&model))
    gl.BindVertexArray(light_vao)
    gl.DrawArrays(gl.TRIANGLES, 0, 36)

    glfw.SwapBuffers(window)
    glfw.PollEvents()
  }

  glfw.Terminate()
}
