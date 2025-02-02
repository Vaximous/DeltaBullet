shader_type spatial;
render_mode unshaded, cull_front;

uniform float distortFactor = 0;
uniform float distortSpeed = 0;
uniform sampler2D noiseTexture;
//uniform sampler2D noiseTexture2;
uniform sampler2D screen_tex : hint_screen_texture,repeat_disable,filter_linear_mipmap;


void fragment(){
	float dotp = dot(vec3(0.0, 0.0, 1.0), NORMAL);
	float fresnel = smoothstep(0.5, 1.0, dotp) * smoothstep(0.8, 0.7, dotp) + smoothstep(0.7, 1.0, dotp) * 0.25 * distortFactor;
	vec3 uv_off = NORMAL * fresnel * 0.1;
	ALBEDO = textureLod(screen_tex,SCREEN_UV + uv_off.xy, 1.0).rgb;
	ALBEDO += texture(noiseTexture, UV + vec2(TIME * distortSpeed)).rgb * distortFactor;
	//ALBEDO = vec3(fresnel);
}