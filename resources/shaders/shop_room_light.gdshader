shader_type canvas_item;
render_mode unshaded, blend_add;

uniform vec2 fountain_center = vec2(317.0, 183.0);
uniform vec2 fountain_radius = vec2(125.0, 88.0);
uniform vec2 furnace_center = vec2(109.0, 101.0);
uniform vec2 furnace_radius = vec2(220.0, 172.0);
uniform vec4 fountain_color : source_color = vec4(0.18, 0.50, 1.0, 1.0);
uniform vec4 furnace_color : source_color = vec4(1.0, 0.66, 0.18, 1.0);
uniform vec4 surge_color : source_color = vec4(1.0, 0.31, 0.055, 1.0);
uniform float fountain_strength = 0.055;
uniform float furnace_strength = 0.15;
uniform float room_strength = 0.0;
uniform float warmth = 0.0;
uniform float enabled = 1.0;
uniform float pixel_grid = 1.0;
uniform float light_bands = 5.0;
uniform sampler2D floor_mask : filter_nearest, repeat_disable;
uniform sampler2D water_mask : filter_nearest, repeat_disable;
uniform bool water_receiver_ready = false;
uniform sampler2D foreground_mask : filter_nearest, repeat_disable;
uniform bool foreground_enabled = false;
uniform bool shadows_enabled = false;
uniform float shadow_strength = 0.65;
uniform float shadow_length_scale = 1.0;
uniform vec4 shadow_footprints[12];
uniform float shadow_lengths[12];

float stepped(float value) {
    // Six held levels including darkness at the default five intervals.
    return floor(clamp(value, 0.0, 1.0) * light_bands + 0.5) / light_bands;
}

vec2 clip_slab(vec2 interval, float origin, float ray, float limit) {
    if (abs(ray)<0.00001) {
        return abs(origin)<=limit ? interval : vec2(1.0,0.0);
    }
    vec2 ends = vec2(-limit-origin,limit-origin)/ray;
    return vec2(max(interval.x,min(ends.x,ends.y)),min(interval.y,max(ends.x,ends.y)));
}

float bench_projection(vec2 p, vec2 source, vec4 footprint, float length) {
    // Homothetic projection: every corner follows its own ray from the emitter.
    // The centre travels the authored 40/44px; silhouettes diverge naturally.
    float scale = 1.0+length*shadow_length_scale/max(distance(footprint.xy,source),1.0);
    vec2 origin = (source-footprint.xy)/footprint.zw;
    vec2 ray = (p-source)/footprint.zw;
    vec2 interval = vec2(1.0/scale,1.0);
    interval = clip_slab(interval,origin.x,ray.x,1.0);
    interval = clip_slab(interval,origin.y,ray.y,1.0);
    interval = clip_slab(interval,origin.x+origin.y,ray.x+ray.y,1.82);
    interval = clip_slab(interval,origin.x-origin.y,ray.x-ray.y,1.82);
    return step(interval.x,interval.y);
}

float cast_shadow(vec2 p, vec2 source, bool water_source) {
    float blocked = 0.0;
    for (int i=0; i<12; i++) {
        if (water_source && i==0) { continue; }
        vec4 footprint = shadow_footprints[i];
        if (i==1 || i==2) {
            blocked = max(blocked,bench_projection(p,source,footprint,shadow_lengths[i]));
            continue;
        }
        vec2 direction = normalize(footprint.xy-source);
        vec2 tail = direction*shadow_lengths[i]*shadow_length_scale/footprint.zw;
        vec2 q = (p-footprint.xy)/footprint.zw;
        float t = clamp(dot(q,tail)/max(dot(tail,tail),0.0001),0.0,1.0);
        vec2 distance_to_sweep = q-t*tail;
        float silhouette = dot(distance_to_sweep,distance_to_sweep);
        blocked = max(blocked,step(silhouette,1.0));
    }
    return blocked;
}

#include "res://resources/shaders/shop_water_occlusion.gdshaderinc"

void fragment() {
    // Coordinates stay on the authored 640x360 grid regardless of window scale.
    vec2 p = (floor(UV * vec2(640.0, 360.0) / pixel_grid) + vec2(0.5)) * pixel_grid;
    float blue = stepped(exp(-2.5 * dot((p-fountain_center)/fountain_radius, (p-fountain_center)/fountain_radius)));
    float yellow = stepped(exp(-2.2 * dot((p-furnace_center)/furnace_radius, (p-furnace_center)/furnace_radius)));
    // Room bounce also holds discrete tones, never a blurred continuous gradient.
    float bounce = mix(0.55, 1.0, stepped(1.0 - clamp(p.x/640.0, 0.0, 1.0)));
    float blue_visibility = 1.0;
    float warm_visibility = 1.0;
    if (shadows_enabled && texture(floor_mask,p/vec2(640.0,360.0)).a > 0.5) {
        blue_visibility -= shadow_strength*cast_shadow(p,fountain_center,true);
        warm_visibility -= shadow_strength*cast_shadow(p,furnace_center,false);
    }
    if (shadows_enabled && water_receiver_ready && texture(water_mask,p/vec2(640.0,360.0)).a > 0.5) {
        // Cyan self-emission and the original animated texture remain untouched.
        warm_visibility -= shadow_strength*water_shadow(p);
    }
    vec3 light = fountain_color.rgb * fountain_strength * blue * blue_visibility;
    light += mix(furnace_color.rgb, surge_color.rgb, warmth) * furnace_strength * yellow * warm_visibility;
    light += surge_color.rgb * room_strength * bounce * warm_visibility;
    if (foreground_enabled && texture(foreground_mask,p/vec2(640.0,360.0)).a>0.5) {
        light = vec3(0.0);
    }
    COLOR = vec4(light * enabled, 1.0);
}
