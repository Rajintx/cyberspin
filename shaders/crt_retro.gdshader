shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float scanline_count : hint_range(100.0, 1200.0) = 420.0;
uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.16;
uniform float curvature : hint_range(0.0, 0.2) = 0.025;
uniform float vignette_intensity : hint_range(0.0, 2.0) = 0.32;
uniform float chromatic_aberration : hint_range(0.0, 0.01) = 0.002;
uniform float crt_brightness : hint_range(0.5, 2.0) = 1.06;

vec2 curve(vec2 uv) {
	vec2 d = uv - 0.5;
	float r2 = dot(d, d);
	uv = uv + d * (r2 * curvature * 2.0);
	return uv;
}

void fragment() {
	vec2 uv = curve(SCREEN_UV);

	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		COLOR = vec4(0.0, 0.0, 0.0, 0.0);
	} else {
		// Chromatic Aberration (RGB Channel Shift)
		vec4 center_sample = texture(screen_texture, uv);
		float r = texture(screen_texture, uv + vec2(chromatic_aberration, 0.0)).r;
		float g = center_sample.g;
		float b = texture(screen_texture, uv - vec2(chromatic_aberration, 0.0)).b;
		vec3 col = vec3(r, g, b) * crt_brightness;

		// Subtle Scanlines
		float scanline = sin(uv.y * scanline_count * 3.14159);
		col -= col * (scanline * scanline_intensity);

		// Vignette (Darkened screen edges)
		float vig = uv.x * (1.0 - uv.x) * uv.y * (1.0 - uv.y) * 15.0;
		vig = clamp(pow(vig, vignette_intensity), 0.0, 1.0);
		col *= vig;

		COLOR = vec4(col, center_sample.a);
	}
}
