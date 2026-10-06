shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float grid_intensity : hint_range(0.0, 1.0) = 0.05;
uniform float brightness_boost : hint_range(0.8, 1.4) = 1.04;

void fragment() {
	vec4 color = texture(screen_texture, SCREEN_UV);

	// GBA 240x160 Subpixel Grid Lines
	vec2 pixel_coord = SCREEN_UV * vec2(240.0, 160.0);
	vec2 grid = abs(fract(pixel_coord - 0.5) - 0.5) / fwidth(pixel_coord);
	float line_weight = min(grid.x, grid.y);
	float grid_factor = 1.0 - (1.0 - min(line_weight, 1.0)) * grid_intensity;

	COLOR = vec4(color.rgb * brightness_boost * grid_factor, color.a);
}
