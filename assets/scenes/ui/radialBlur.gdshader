shader_type canvas_item;

uniform vec2 center = vec2(0.5);
uniform float power: hint_range(-10.0,10.0,0.01) = 2.0;
uniform float iterations: hint_range(1.0, 20.0, 1.0) = 10;
uniform sampler2D screen_texture :hint_screen_texture;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 dir = center - uv;
	vec2 blur = dir * power * 0.01;
	vec4 color = vec4(0.0);
	for (float i = 0.0; i < iterations; i++) {
		color += texture(screen_texture,uv);
		uv += blur;
	}
	
	color /= iterations;
	COLOR = color;
}
