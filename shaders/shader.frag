#version 410 core

out vec4 FragColor;

in vec3 Normal;
in vec3 FragPos;
in vec2 texCoords;

struct Material {
  sampler2D diffuse;
  sampler2D specular;
  sampler2D emission;
  float shininess;
};

struct Light {
  vec3 position;

  vec3 ambient;
  vec3 diffuse;
  vec3 specular;
};

uniform Material material;
uniform Light light;

uniform vec3 cameraPos;

void main() {
  vec3 norm = normalize(Normal);
  vec3 lightDir = normalize(light.position - FragPos);
  float diff = max(dot(norm, lightDir), 0.0);

  vec3 viewDir = normalize(cameraPos - FragPos);
  vec3 reflectDir = reflect(-lightDir, norm);
  float spec = pow(max(dot(viewDir, reflectDir), 0.0), material.shininess);

  vec3 ambient = texture(material.diffuse, texCoords).rgb * light.ambient;
  vec3 diffuse = diff * light.diffuse * texture(material.diffuse, texCoords).rgb;
  vec3 specular = texture(material.specular, texCoords).rgb * spec * light.specular;

  vec3 emission;
  if (dot(texture(material.specular, texCoords).rgb, vec3(1.0)) <= 0.1) {
    emission = texture(material.emission, texCoords).rgb;
  } else {
    emission = vec3(0.0, 0.0, 0.0);
  }

  vec3 result = ambient + diffuse + specular + emission;
  FragColor = vec4(result, 1.0);
}
