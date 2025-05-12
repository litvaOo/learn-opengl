package main 

import "vendor:glfw"
import "core:math/linalg"
import gl "vendor:OpenGL"

handle_input :: proc(window: glfw.WindowHandle) {
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
