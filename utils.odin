package main

import "core:os"

read_file :: proc (filename: string) -> []u8 {
  file := os.open(filename) or_else panic("Failed to open file")
  file_size := os.file_size(file) or_else panic("Failed to get file size")
  data := make([]u8, file_size)
  total_read := os.read(file, data) or_else panic("Failed to read file")

  return data
}
