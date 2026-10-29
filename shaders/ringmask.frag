#version 440
// Kronos ring: samples a ring texture rasterised once in ring-local space,
// rotates it in the fragment stage and multiplies by a world-space alpha
// lookup (focus fade / arc clip / arc-end fade) indexed by screen angle.
// One draw call, no offscreen pass, no per-frame texture upload.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 center;    // dial centre, item px
    vec2 itemSize;  // item px
    float texHalf;  // ring texture half size, item px
    float ringRotation; // ring rotation, radians (screen y-down)
};
layout(binding = 1) uniform sampler2D ringTex;
layout(binding = 2) uniform sampler2D lut;

const float TWO_PI = 6.28318530718;

void main() {
    vec2 p = qt_TexCoord0 * itemSize - center;
    float c = cos(ringRotation);
    float s = sin(ringRotation);
    vec2 uv = vec2(c * p.x + s * p.y, -s * p.x + c * p.y) / (2.0 * texHalf) + 0.5;
    if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) {
        fragColor = vec4(0.0);
        return;
    }
    float a = atan(p.y, p.x);
    if (a < 0.0) a += TWO_PI;
    float m = texture(lut, vec2(a / TWO_PI, 0.5)).a;
    fragColor = texture(ringTex, uv) * (m * qt_Opacity);
}
