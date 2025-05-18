#version 410 core

out vec4 FragColor;

in vec3 Normal;
in vec3 FragPos;
in vec2 texCoords;

uniform vec3 cameraPos;

struct Material {
  sampler2D diffuse;
  sampler2D specular;
  sampler2D emission;
  float shininess;
};

uniform Material material;

struct DirLight {
  vec3 direction;

  vec3 ambient;
  vec3 diffuse;
  vec3 specular;
};

uniform DirLight dirLight;

vec3 CalcDirLight(DirLight light, vec3 normal, vec3 viewDir) {
  vec3 lightDir = normalize(-light.direction);
  float diff = max(dot(normal, lightDir), 0.0);
  vec3 reflectDir = reflect(-lightDir, normal);
  float spec = pow(max(dot(viewDir, reflectDir), 0.0), material.shininess);

  vec3 ambient = light.ambient * vec3(texture(material.diffuse, texCoords));
  vec3 diffuse = light.diffuse * diff * vec3(texture(material.diffuse, texCoords));
  vec3 specular = light.specular * spec * vec3(texture(material.specular, texCoords));

  return ambient + diffuse + specular;
}

struct PointLight {
  vec3 position;

  float constant;
  float linear;
  float quadratic;

  vec3 ambient;
  vec3 diffuse;
  vec3 specular;
};

#define NR_POINT_LIGHTS 4
uniform PointLight pointLights[NR_POINT_LIGHTS];

vec3 CalcPointLight(PointLight light, vec3 normal, vec3 fragPos, vec3 viewDir) {
  vec3 lightDir = normalize(light.position - fragPos);
  float diff = max(dot(normal, lightDir), 0.0);

  vec3 reflectDir = reflect(-lightDir, normal);
  float spec = pow(max(dot(viewDir, reflectDir), 0.0), material.shininess);

  float distance = length(light.position - fragPos);
  float attenuation = 1.0 / (light.constant + light.linear * distance + light.quadratic * (distance * distance));

  vec3 ambient = light.ambient * texture(material.diffuse, texCoords).rgb;
  vec3 diffuse = light.diffuse * diff * texture(material.diffuse, texCoords).rgb;
  vec3 specular = light.specular * spec * texture(material.specular, texCoords).rgb;

  return (ambient + diffuse + specular) * attenuation;
}
void main() {
  vec3 emission;
  if (dot(texture(material.specular, texCoords).rgb, vec3(1.0)) <= 0.1) {
    emission = texture(material.emission, texCoords).rgb;
  } else {
    emission = vec3(0.0, 0.0, 0.0);
  }
  vec3 norm = normalize(Normal);
  vec3 viewDir = normalize(cameraPos - FragPos);
  vec3 result = CalcDirLight(dirLight, norm, viewDir);
  for (int i = 0; i < NR_POINT_LIGHTS; i++) 
    result += CalcPointLight(pointLights[i], norm, FragPos, viewDir);

  FragColor = vec4(result + emission, 1.0);
}
