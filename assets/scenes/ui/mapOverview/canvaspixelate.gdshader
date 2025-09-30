shader_type canvas_item;


uniform float pixel_density : hint_range(0.001, 1.0, 0.001);


void fragment() {
	float mod_pix_density = (pixel_density * pixel_density) / TEXTURE_PIXEL_SIZE.x;
	vec2 uv_rounded = floor(UV * mod_pix_density) / mod_pix_density;
	vec4 tex_pixelated = texture(TEXTURE, uv_rounded);
	COLOR = tex_pixelated;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
