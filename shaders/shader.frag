#version 410 core

in vec3 fragColor;
in vec4 fragPos;
in vec2 texCoord;
out vec4 outColor;

uniform sampler2D inTexture;
uniform sampler2D inTexture2;

void main() {
  outColor = mix(texture(inTexture, texCoord), texture(inTexture2, texCoord), 0.2);
}
