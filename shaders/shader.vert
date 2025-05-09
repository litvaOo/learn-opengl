#version 410 core

layout(location = 0) in vec3 inPosition;
layout(location = 1) in vec3 inColor;
layout(location = 2) in vec2 inTexCoord;

uniform vec3 offsetVec;

out vec3 fragColor;
out vec4 fragPos;
out vec2 texCoord;

uniform mat4 transform;

void main() {
    gl_Position = transform * vec4(inPosition, 1.0);
    fragColor = inColor;
    fragPos = gl_Position;
    texCoord = inTexCoord;
}
