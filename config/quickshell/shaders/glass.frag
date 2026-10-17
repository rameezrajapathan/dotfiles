#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 size;
    vec2 backdropSize;
    vec4 backdropA;
    vec4 backdropB;
    vec4 tint;
    vec4 rimColor;
    vec4 shadowColor;
    vec2 lightDir;
    vec2 shadowOffset;
    float band;
    float rim;
    float refraction;
    float chroma;
    float lens;
    float shadowSpread;
    float fill;
};

layout(binding = 1) uniform sampler2D shape;
layout(binding = 2) uniform sampler2D backdrop;

const float TAU = 6.28318530718;

float coverage(vec2 uv) {
    return texture(shape, uv).a;
}

vec3 backdropAt(vec2 uv) {
    vec2 o = vec2(1.5) / max(backdropSize, vec2(1.0));
    vec3 c = texture(backdrop, uv).rgb * 0.4;
    c += texture(backdrop, uv + vec2(o.x, 0.0)).rgb * 0.15;
    c += texture(backdrop, uv - vec2(o.x, 0.0)).rgb * 0.15;
    c += texture(backdrop, uv + vec2(0.0, o.y)).rgb * 0.15;
    c += texture(backdrop, uv - vec2(0.0, o.y)).rgb * 0.15;
    return c;
}

vec3 rings(vec2 uv, float reach, vec2 px) {
    vec2 grad = vec2(0.0);
    float miss = 0.0;
    float total = 0.0;
    for (int r = 1; r <= 3; ++r) {
        float radius = reach * float(r) / 3.0;
        float w = 1.0 / float(r);
        for (int i = 0; i < 12; ++i) {
            float ang = (float(i) + 0.5 * float(r)) * TAU / 12.0;
            vec2 d = vec2(cos(ang), sin(ang));
            float out_ = 1.0 - coverage(uv + d * radius * px);
            miss += out_ * w;
            grad += d * out_ * w;
            total += w;
        }
    }
    return vec3(grad, miss / total);
}

vec4 shadowAt(vec2 uv, vec2 px) {
    if (shadowSpread <= 0.0 || shadowColor.a <= 0.0)
        return vec4(0.0);
    vec2 c = uv - shadowOffset * px;
    float s = shadowSpread;
    float near = coverage(c) + coverage(c + vec2(s, 0.0) * px) + coverage(c - vec2(s, 0.0) * px)
        + coverage(c + vec2(0.0, s) * px) + coverage(c - vec2(0.0, s) * px);
    if (near <= 0.0)
        return vec4(0.0);
    float cov = 1.0 - rings(c, s, px).z;
    float k = cov * cov * shadowColor.a;
    return vec4(shadowColor.rgb * k, k);
}

void main() {
    vec2 uv = qt_TexCoord0;
    vec2 px = 1.0 / size;
    float a = coverage(uv);
    vec4 shadow = shadowAt(uv, px) * (1.0 - a);
    if (a <= 0.002) {
        fragColor = shadow * qt_Opacity;
        return;
    }

    vec3 ring = rings(uv, band, px);
    float e = clamp(ring.z * 2.0, 0.0, 1.0);
    float gl = length(ring.xy);
    vec2 n = gl > 0.0001 ? ring.xy / gl : vec2(0.0);

    float m = min(min(coverage(uv + vec2(px.x, 0.0)), coverage(uv - vec2(px.x, 0.0))),
                  min(coverage(uv + vec2(0.0, px.y)), coverage(uv - vec2(0.0, px.y))));
    float line = clamp(1.0 - m, 0.0, 1.0);

    vec3 color = tint.rgb;
    float alpha = tint.a;
    vec2 base = backdropA.xy + uv.x * backdropA.zw + uv.y * backdropB.xy;

    if (lens > 0.5 && fill > 0.5) {
        color = mix(backdropAt(base), tint.rgb, tint.a);
        alpha = 1.0;
    }

    if (lens > 0.5 && refraction > 0.0) {
        float bend = refraction * pow(e, 1.5);
        vec2 d = -n * bend * band * 3.0 * px;
        vec2 shift = d.x * backdropA.zw + d.y * backdropB.xy;
        vec3 refr;
        refr.r = backdropAt(base + shift * (1.0 + chroma * 0.35)).r;
        refr.g = backdropAt(base + shift).g;
        refr.b = backdropAt(base + shift * (1.0 - chroma * 0.35)).b;
        float w = clamp(pow(e, 1.1) * refraction, 0.0, 0.92);
        vec3 tinted = mix(refr * (1.0 + 0.25 * e), tint.rgb, tint.a * 0.35);
        float outA = mix(alpha, 1.0, w);
        color = (color * alpha * (1.0 - w) + tinted * w) / max(outA, 0.001);
        alpha = outA;
    }

    float facing = max(dot(n, lightDir), 0.0);
    float away = max(dot(n, -lightDir), 0.0);
    float spec = pow(facing, 2.0) * smoothstep(0.45, 1.0, e) * 0.9 + pow(away, 3.0) * smoothstep(0.6, 1.0, e) * 0.3;
    float glow = (line * (0.35 + 0.9 * pow(facing, 1.5) + 0.3 * pow(away, 2.0)) + spec + pow(e, 3.0) * 0.08) * rim;
    glow = clamp(glow, 0.0, 1.0) * rimColor.a;

    vec3 premul = color * alpha;
    premul = premul * (1.0 - glow) + rimColor.rgb * glow;
    float outAlpha = alpha + glow * (1.0 - alpha);

    fragColor = (vec4(premul, outAlpha) * a + shadow) * qt_Opacity;
}
