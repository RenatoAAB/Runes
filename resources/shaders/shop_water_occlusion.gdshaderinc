// Shared authored structure silhouettes on the water surface.
float water_caster(vec2 p, vec2 source, vec4 base, float length) {
    vec2 direction = normalize(base.xy-source);
    vec2 tail = direction*length*shadow_length_scale/base.zw;
    vec2 q = (p-base.xy)/base.zw;
    float t = clamp(dot(q,tail)/max(dot(tail,tail),0.0001),0.0,1.0);
    vec2 d = abs(q-t*tail);
    return step(max(max(d.x,d.y),(d.x+d.y)/1.65),1.0);
}

float cross_2d(vec2 a, vec2 b) { return a.x*b.y-a.y*b.x; }
float in_triangle(vec2 p,vec2 a,vec2 b,vec2 c) {
    vec3 side = vec3(cross_2d(b-a,p-a),cross_2d(c-b,p-b),cross_2d(a-c,p-c));
    return (min(min(side.x,side.y),side.z)>=0.0 || max(max(side.x,side.y),side.z)<=0.0) ? 1.0 : 0.0;
}
float lateral_rim(vec2 p,vec2 a,vec2 b) {
    float scale = 1.0+7.0*shadow_length_scale/max(distance((a+b)*0.5,furnace_center),1.0);
    vec2 far_a = furnace_center+(a-furnace_center)*scale;
    vec2 far_b = furnace_center+(b-furnace_center)*scale;
    return max(in_triangle(p,a,b,far_b),in_triangle(p,a,far_b,far_a));
}

float water_shadow(vec2 p) {
    // Only the furnace-facing upper/left structures project into the basin.
    // The right/lower columns cast outwards and are clipped out of this receiver.
    float blocked = water_caster(p,furnace_center,vec4(319.0,117.0,13.0,8.0),34.0);
    blocked = max(blocked,water_caster(p,furnace_center,vec4(239.0,145.0,12.0,10.0),44.0));
    // Shallow broken NW rim, following its stepped diagonal rather than a ring.
    blocked = max(blocked,water_caster(p,furnace_center,vec4(254.0,129.0,7.0,4.0),9.0));
    blocked = max(blocked,water_caster(p,furnace_center,vec4(270.0,122.0,9.0,4.0),8.0));
    blocked = max(blocked,water_caster(p,furnace_center,vec4(289.0,115.0,9.0,4.0),7.0));
    // Low left-side retaining wall: a short connected strip, distinct from pillars.
    blocked = max(blocked,lateral_rim(p,vec2(237.0,150.0),vec2(231.0,162.0)));
    blocked = max(blocked,lateral_rim(p,vec2(231.0,162.0),vec2(226.0,178.0)));
    blocked = max(blocked,lateral_rim(p,vec2(226.0,178.0),vec2(225.0,183.0)));
    blocked = max(blocked,lateral_rim(p,vec2(225.0,183.0),vec2(227.0,190.0)));
    return blocked;
}

