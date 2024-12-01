shader_type canvas_item;


uniform sampler2D screen : hint_screen_texture, filter_linear_mipmap;
uniform lowp float blur_amount : hint_range(0.0, 5.0, 0.0);
uniform vec3 tint : source_color;


void fragment() {
	// Place fragment code here.
	COLOR.rgb = textureLod(screen, SCREEN_UV, blur_amount).rgb * tint;
}
