shader_type canvas_item;

// Mana Residue: translucent light-blue fire-like orb with gentle pulsation.
// Round shape, soft edges, organic flame movement.

uniform vec4 base_color : source_color = vec4(0.4, 0.7, 1.0, 0.55);
uniform vec4 core_color : source_color = vec4(0.6, 0.85, 1.0, 0.7);
uniform float pulse_speed : hint_range(0.5, 4.0) = 1.5;
uniform float flame_speed : hint_range(0.5, 4.0) = 2.0;
uniform float flame_intensity : hint_range(0.0, 1.0) = 0.35;
uniform float radius : hint_range(0.1, 0.5) = 0.38;
uniform float softness : hint_range(0.01, 0.3) = 0.12;

// Simple hash-based noise
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

// Value noise with smooth interpolation
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f); // smoothstep
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Fractal Brownian Motion for organic flame look
float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 4; i++) {
		value += amplitude * noise(p);
		p *= 2.1;
		amplitude *= 0.5;
	}
	return value;
}

void fragment() {
	vec2 uv = UV - 0.5; // Center at origin
	float dist = length(uv);

	// Circular mask with soft edge
	float circle = 1.0 - smoothstep(radius - softness, radius + softness, dist);

	// Flame distortion: push UVs upward with noise
	float time = TIME * flame_speed;
	vec2 flame_uv = uv * 4.0 + vec2(0.0, -time * 0.5);
	float flame = fbm(flame_uv);
	float flame2 = fbm(flame_uv * 1.3 + vec2(3.7, 1.2));

	// Combine flame layers for organic movement
	float fire_shape = flame * 0.6 + flame2 * 0.4;
	fire_shape = fire_shape * flame_intensity;

	// Distort the circle edge with flame noise (keeps round overall shape)
	float angle = atan(uv.y, uv.x);
	float edge_noise = fbm(vec2(angle * 2.0, TIME * 1.0)) * 0.08;
	float distorted_circle = 1.0 - smoothstep(radius - softness + edge_noise, radius + softness + edge_noise, dist);

	// Pulsation
	float pulse = sin(TIME * pulse_speed) * 0.08 + 0.92;

	// Core glow (brighter center)
	float core = 1.0 - smoothstep(0.0, radius * 0.6, dist);
	core = core * core;

	// Mix colors: core is brighter, edges fade to base color
	vec4 color = mix(base_color, core_color, core);

	// Add flame brightness variation
	color.rgb += fire_shape * vec3(0.15, 0.25, 0.35);

	// Final alpha: circle mask * pulse * flame contribution
	float alpha = distorted_circle * pulse;
	alpha += fire_shape * distorted_circle * 0.3;
	alpha = clamp(alpha, 0.0, 1.0);

	COLOR = vec4(color.rgb, color.a * alpha);
}
