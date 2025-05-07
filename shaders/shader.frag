#version 410 core

in vec3 fragColor;
in vec4 fragPos;
out vec4 outColor;

void main() {
  outColor = fragPos;
}
