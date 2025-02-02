shader_type spatial;
render_mode unshaded;

uniform float distortFactor = 0;
uniform float distortSpeed = 0;
uniform sampler2D noiseTexture;
uniform sampler2D noiseTexture2;
uniform sampler2D albedoTex : hint_screen_texture,repeat_disable;


void fragment(){
	vec2 noise_uv = SCREEN_UV + TIME*distortSpeed;
	vec2 noise_uv2 = SCREEN_UV + TIME*distortSpeed;
	vec2 noise = vec2(texture(noiseTexture,noise_uv).r,texture(noiseTexture2,noise_uv).r);
	vec2 noise2 = vec2(texture(noiseTexture2,noise_uv).r,texture(noiseTexture2,noise_uv2).r);
	vec2 base = SCREEN_UV + (noise+noise2)*distortFactor;
  ALBEDO = texture(albedoTex,base).rgb;
}