package main

import stbi "vendor:stb/image"
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
