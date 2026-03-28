shader_type canvas_item;

// Mana Anomaly: erratic version of Mana Residue with glitch effects.
// Base is similar blue orb but with random color shifts (magenta, green, white)
// and rectilinear glitch distortions that break the round shape momentarily.

uniform vec4 base_color : source_color = vec4(0.4, 0.7, 1.0, 0.6);
uniform vec4 core_color : source_color = vec4(0.6, 0.85, 1.0, 0.75);
uniform vec4 glitch_color_a : source_color = vec4(0.9, 0.1, 0.6, 0.8); // Magenta
uniform vec4 glitch_color_b : source_color = vec4(0.1, 1.0, 0.4, 0.8); // Green
uniform vec4 glitch_color_c : source_color = vec4(1.0, 1.0, 1.0, 0.9); // White flash
uniform float pulse_speed : hint_range(0.5, 4.0) = 2.0;
uniform float flame_speed : hint_range(0.5, 4.0) = 2.5;
uniform float flame_intensity : hint_range(0.0, 1.0) = 0.3;
uniform float radius : hint_range(0.1, 0.5) = 0.36;
uniform float softness : hint_range(0.01, 0.3) = 0.1;
uniform float glitch_frequency : hint_range(0.5, 8.0) = 3.0;
uniform float glitch_strength : hint_range(0.0, 1.0) = 0.6;
uniform float glitch_block_size : hint_range(2.0, 20.0) = 8.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float hash1(float p) {
	return fract(sin(p * 127.1) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

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

// Generates a glitch intensity that bursts periodically
// Returns 0.0 most of the time, spikes to ~1.0 during glitch moments
float glitch_trigger(float time) {
	float t = time * glitch_frequency;
	float slow_wave = sin(t * 0.7) * sin(t * 1.3);
	// Trigger glitch only when wave exceeds threshold
	float trigger = smoothstep(0.6, 0.9, slow_wave);
	// Add rapid flicker during glitch
	float flicker = step(0.7, hash1(floor(time * 30.0)));
	return trigger * mix(0.5, 1.0, flicker);
}

// Rectangular block distortion for glitch lines
vec2 glitch_offset(vec2 uv, float time, float intensity) {
	if (intensity < 0.01) return vec2(0.0);

	// Divide into horizontal blocks
	float block_y = floor(uv.y * glitch_block_size);
	float block_hash = hash1(block_y + floor(time * 12.0));

	// Only some blocks glitch
	float active = step(0.6, block_hash);

	// Horizontal shift amount
	float shift = (hash1(block_y * 3.7 + floor(time * 20.0)) - 0.5) * 0.25;

	return vec2(shift * active * intensity * glitch_strength, 0.0);
}

void fragment() {
	float glitch_t = glitch_trigger(TIME);

	// Apply block glitch displacement to UVs
	vec2 uv_raw = UV;
	vec2 offset = glitch_offset(UV, TIME, glitch_t);
	uv_raw += offset;

	vec2 uv = uv_raw - 0.5;
	float dist = length(uv);

	// Base circular mask
	float circle = 1.0 - smoothstep(radius - softness, radius + softness, dist);

	// Flame distortion (same as residue but slightly faster/erratic)
	float time = TIME * flame_speed;
	vec2 flame_uv = uv * 4.0 + vec2(0.0, -time * 0.5);
	float flame = fbm(flame_uv);
	float flame2 = fbm(flame_uv * 1.3 + vec2(3.7, 1.2));
	float fire_shape = flame * 0.6 + flame2 * 0.4;
	fire_shape *= flame_intensity;

	// Edge distortion with noise
	float angle = atan(uv.y, uv.x);
	float edge_noise = fbm(vec2(angle * 2.0, TIME * 1.2)) * 0.1;

	// During glitch: add straight-line edges (rectangular distortion)
	float rect_mask = 0.0;
	if (glitch_t > 0.1) {
		// Create rectangular slices that show through
		float slice_y = step(0.5, hash1(floor(UV.y * glitch_block_size) + floor(TIME * 15.0)));
		float slice_x = step(0.4, hash1(floor(UV.x * glitch_block_size * 0.7) + floor(TIME * 11.0)));
		rect_mask = slice_y * slice_x * glitch_t * 0.5;
	}

	float distorted_circle = 1.0 - smoothstep(
		radius - softness + edge_noise,
		radius + softness + edge_noise,
		dist
	);

	// Merge round shape with rectangular glitch fragments
	float shape = max(distorted_circle, rect_mask * step(dist, 0.48));

	// Pulsation (more erratic than residue)
	float pulse = sin(TIME * pulse_speed) * 0.1 + 0.9;
	pulse += glitch_t * 0.15 * sin(TIME * 17.0); // jitter during glitch

	// Core glow
	float core = 1.0 - smoothstep(0.0, radius * 0.55, dist);
	core = core * core;

	// Base color mixing
	vec4 color = mix(base_color, core_color, core);
	color.rgb += fire_shape * vec3(0.15, 0.25, 0.35);

	// Glitch color injection: cycle through glitch colors
	if (glitch_t > 0.1) {
		float color_select = hash1(floor(TIME * 18.0));
		vec4 g_color;
		if (color_select < 0.33) {
			g_color = glitch_color_a; // Magenta
		} else if (color_select < 0.66) {
			g_color = glitch_color_b; // Green
		} else {
			g_color = glitch_color_c; // White
		}
		// Mix glitch color based on intensity and position
		float g_mix = glitch_t * step(0.5, hash1(floor(UV.y * glitch_block_size * 2.0) + floor(TIME * 25.0)));
		color.rgb = mix(color.rgb, g_color.rgb, g_mix * 0.7);
	}

	// Final alpha
	float alpha = shape * pulse;
	alpha += fire_shape * distorted_circle * 0.25;
	alpha = clamp(alpha, 0.0, 1.0);

	// Chromatic aberration during glitch
	if (glitch_t > 0.2) {
		float aberration = glitch_t * 0.015;
		// Shift red channel slightly
		color.r = mix(color.r, color.r + aberration * 2.0, glitch_t);
	}

	COLOR = vec4(color.rgb, color.a * alpha);
}
