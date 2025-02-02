shader_type spatial;
render_mode unshaded;

uniform sampler2D screen_tex : hint_screen_texture;

void fragment(){
  ALBEDO = texture(screen_tex,SCREEN_UV).xyz;
}