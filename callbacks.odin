package main

import gl "vendor:OpenGL"
import "vendor:glfw"
import "core:math"
import "core:math/linalg"

framebuffer_resize_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
  gl.Viewport(0, 0, width, height)
}

mouse_callback :: proc "c" (window: glfw.WindowHandle, xpos, ypos: f64) {
  if first_mouse {
    last_x = f32(xpos)
    last_y = f32(ypos)
    first_mouse = false
  }
  x_offset := f32(xpos) - last_x
  y_offset := f32(ypos) - last_y
  last_x = f32(xpos)
  last_y = f32(ypos)

  sensitivity : f32 = 0.1
  x_offset *= sensitivity
  y_offset *= sensitivity

  yaw += x_offset
  pitch += y_offset

  pitch = clamp(pitch, -89.0, 89.0)

  direction : Vector3
  direction.x = math.cos(math.to_radians_f32(yaw)) * math.cos(math.to_radians_f32(pitch))
  direction.y = math.sin(math.to_radians_f32(pitch))
  direction.z = math.sin(math.to_radians_f32(yaw)) * math.cos(math.to_radians_f32(pitch))
  camera_front = linalg.normalize(direction)
} 

scroll_callback :: proc "c" (window: glfw.WindowHandle, x_offset, y_offset: f64) {
  fov -= f32(y_offset)
  fov = clamp(fov, 1.0, 45.0)
}

