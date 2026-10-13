shader_type canvas_item;

uniform float mouth_open : hint_range(0.0, 1.0) = 0.0;
uniform float eye_blink : hint_range(0.0, 1.0) = 0.0;
uniform float idle_breath : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 uv = UV;

	// Organic breathing micro-sway (shifts interior subpixels without blurring retro pixel borders)
	if (idle_breath > 0.0 && uv.x > 0.05 && uv.x < 0.95 && uv.y > 0.05 && uv.y < 0.95) {
		uv.y += sin(TIME * 2.4) * 0.0035 * idle_breath;
	}

	vec4 col = texture(TEXTURE, uv);

	// 1. Eye Blink Animation (Eyelid closure across eye line)
	if (eye_blink > 0.05) {
		float eye_left = abs(uv.x - 0.43);
		float eye_right = abs(uv.x - 0.57);
		if ((eye_left < 0.055 || eye_right < 0.055) && uv.y >= 0.390 && uv.y <= 0.445) {
			float line_dist = abs(uv.y - 0.418);
			if (line_dist < 0.0075) {
				// Eyelid seam crease
				col.rgb = mix(col.rgb, vec3(0.18, 0.12, 0.10), eye_blink);
			} else {
				// Eyelid skin tone blend
				col.rgb = mix(col.rgb, col.rgb * 0.65 + vec3(0.16, 0.11, 0.09), eye_blink * 0.88);
			}
		}
	}

	// 2. Talking Mouth Flap Animation
	if (mouth_open > 0.05) {
		float mouth_dx = (uv.x - 0.50) * 1.65;
		float mouth_dy = (uv.y - 0.548) * 2.6;
		float mouth_ellipse = mouth_dx * mouth_dx + mouth_dy * mouth_dy;
		if (mouth_ellipse < 0.0085 * mouth_open) {
			// Dark interior of open mouth
			col.rgb = mix(col.rgb, vec3(0.20, 0.06, 0.08), mouth_open * 0.92);
		} else if (mouth_ellipse < 0.014 * mouth_open && uv.y > 0.548) {
			// Lower lip highlight
			col.rgb = mix(col.rgb, vec3(0.42, 0.18, 0.18), mouth_open * 0.70);
		}
	}

	COLOR = col;
}
