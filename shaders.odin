package main

import gl "vendor:OpenGL"

create_shader_program :: proc(vert_path, frag_path: string) -> u32 {
  shader_program := gl.CreateProgram()
  vertex_shader := gl.CreateShader(gl.VERTEX_SHADER)
  vertex_shader_source_raw := read_file(vert_path)
  vertex_shader_source := cstring(raw_data(vertex_shader_source_raw))
  gl.ShaderSource(vertex_shader, 1, &vertex_shader_source, nil)
  gl.CompileShader(vertex_shader)

  fragment_shader := gl.CreateShader(gl.FRAGMENT_SHADER)
  fragment_shader_source_raw := read_file(frag_path)
  fragment_shader_source := cstring(raw_data(fragment_shader_source_raw))
  gl.ShaderSource(fragment_shader, 1, &fragment_shader_source, nil)
  gl.CompileShader(fragment_shader)

  gl.AttachShader(shader_program, vertex_shader)
  gl.AttachShader(shader_program, fragment_shader)
  gl.LinkProgram(shader_program)
  return shader_program
}
