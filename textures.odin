package main

import stbi "vendor:stb/image"
import gl "vendor:OpenGL"
import "core:strings"

read_texture :: proc(file_path: string) -> (i32, i32, i32, [^]u8 ) {
  stbi.set_flip_vertically_on_load(1)
  tex_width, tex_height, tex_channels: i32
  desired_channels : i32 = 0
  data := stbi.load(strings.clone_to_cstring(file_path), &tex_width, &tex_height, &tex_channels, desired_channels)
  if data == nil {
    panic("Failed to load texture")
  }
  return tex_width, tex_height, tex_channels, data
}

create_texture :: proc(file_path: string) -> u32 {
  res: u32
  gl.GenTextures(1, &res)
  tex_width, tex_height, tex_channels, cube_texture_data := read_texture(file_path)
  gl.BindTexture(gl.TEXTURE_2D, res)
  format: u32
  switch tex_channels {
    case 1:
      format = gl.RED
    case 3:
      format = gl.RGB
    case 4:
      format = gl.RGBA
  }
  gl.TexImage2D(gl.TEXTURE_2D, 0, i32(format), tex_width, tex_height, 0, format, gl.UNSIGNED_BYTE, cube_texture_data)
  gl.GenerateMipmap(gl.TEXTURE_2D)
  gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
  gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
  gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR)
  gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
  return res
}
