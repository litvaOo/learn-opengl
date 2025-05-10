#version 410 core

in vec2 texCoord;
out vec4 outColor;

uniform sampler2D inTexture;
uniform sampler2D inTexture2;
uniform float mixFactor;

void main() {
  outColor = mix(texture(inTexture, texCoord), texture(inTexture2, vec2(texCoord[0], texCoord[1])), mixFactor);
}
