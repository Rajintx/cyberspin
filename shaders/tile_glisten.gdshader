shader_type canvas_item;

uniform vec4 shine_color : source_color = vec4(1.0, 1.0, 1.0, 0.45);
uniform float shine_speed : hint_range(0.1, 5.0) = 0.8;
uniform float shine_width : hint_range(0.01, 1.0) = 0.22;
uniform float shine_angle : hint_range(0.0, 180.0) = 45.0;
uniform float shine_frequency : hint_range(1.0, 10.0) = 3.5;
uniform float border_pulse_speed : hint_range(0.0, 10.0) = 2.0;

void fragment() {
	vec4 base_col = texture(TEXTURE, UV);
	
	// Diagonal shimmer / glisten band
	float radians_angle = radians(shine_angle);
	vec2 dir = vec2(cos(radians_angle), sin(radians_angle));
	float progress = mod(TIME * shine_speed, shine_frequency);
	
	float proj = dot(UV, dir);
	float dist = abs(proj - progress);
	float shimmer = smoothstep(shine_width, 0.0, dist);
	
	// Subtle neon edge pulse
	float edge_dist = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y));
	float border_pulse = sin(TIME * border_pulse_speed) * 0.5 + 0.5;
	float edge_glow = smoothstep(0.08, 0.0, edge_dist) * border_pulse * 0.25;

	vec4 shine_effect = shine_color * shimmer;
	COLOR = base_col + shine_effect + (shine_color * edge_glow);
}
