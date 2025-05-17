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
  vec3 direction;
  float cutOff;
  float outerCutOff;

  vec3 ambient;
  vec3 diffuse;
  vec3 specular;

  float constant;
  float linear;
  float quadratic;
};

uniform Material material;
uniform Light light;

uniform vec3 cameraPos;

void main() {
  vec3 lightDir = normalize(light.position - FragPos);
  float theta = dot(lightDir, normalize(-light.direction));
  float epsilon = light.cutOff - light.outerCutOff;
  float intensity = clamp((theta - light.outerCutOff) / epsilon, 0.0, 1.0);
  vec3 emission;
  if (dot(texture(material.specular, texCoords).rgb, vec3(1.0)) <= 0.1) {
    emission = texture(material.emission, texCoords).rgb;
  } else {
    emission = vec3(0.0, 0.0, 0.0);
  }
  if (theta > light.cutOff) {
    vec3 ambient = light.ambient * texture(material.diffuse, texCoords).rgb;
    vec3 norm = normalize(Normal);
    float diff = max(dot(norm, lightDir), 0.0);
    vec3 diffuse = light.diffuse * diff * texture(material.diffuse, texCoords).rgb;  
    vec3 viewDir = normalize(cameraPos - FragPos);
    vec3 reflectDir = reflect(-lightDir, norm);  
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), material.shininess);
    vec3 specular = light.specular * spec * texture(material.specular, texCoords).rgb;  
    float distance    = length(light.position - FragPos);
    float attenuation = 1.0 / (light.constant + light.linear * distance + light.quadratic * (distance * distance));    

    vec3 result = ambient + ( diffuse + specular ) * attenuation * intensity + emission;
    FragColor = vec4(result, 1.0);

  } else {
    FragColor = vec4(light.ambient * texture(material.diffuse, texCoords).rgb + emission, 1.0);
  }
}
