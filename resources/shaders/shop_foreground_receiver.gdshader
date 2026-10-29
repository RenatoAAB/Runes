shader_type canvas_item;
render_mode unshaded;
uniform sampler2D foreground_mask : filter_nearest, repeat_disable;
uniform float shadow_depth = 0.1;
varying vec2 local_position;
void vertex() { local_position = VERTEX; }
void fragment() {
    vec4 surface = COLOR;
    vec2 p = floor(local_position)+vec2(0.5);
    float receiver = step(0.5,texture(foreground_mask,p/vec2(640.0,360.0)).a);
    COLOR = vec4(surface.rgb*(1.0-shadow_depth*receiver),surface.a);
}
