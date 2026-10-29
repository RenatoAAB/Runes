shader_type canvas_item;
render_mode unshaded;
uniform sampler2D water_mask : filter_nearest, repeat_disable;
uniform vec2 water_origin = vec2(225.0,110.0);
uniform vec2 furnace_center = vec2(109.0,101.0);
uniform float shadow_length_scale = 1.0;
uniform float surface_depth = 0.0;
varying vec2 local_position;
#include "res://resources/shaders/shop_water_occlusion.gdshaderinc"
void vertex() {
    local_position = VERTEX;
}
void fragment() {
    vec4 surface = COLOR;
    vec2 p = floor(water_origin+local_position)+vec2(0.5);
    float receiver = step(0.5,texture(water_mask,p/vec2(640.0,360.0)).a);
    float shade = surface_depth*water_shadow(p)*receiver;
    // Retain a cyan emission floor, including the authored darker edge colors.
    vec3 emission_floor = min(surface.rgb,vec3(0.22,0.65,0.58));
    COLOR = vec4(max(surface.rgb*(1.0-shade),emission_floor),surface.a);
}
