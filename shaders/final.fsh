#version 330 compatibility

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform float viewWidth;
uniform float viewHeight;
uniform float worldTime;
uniform float rainStrength;
uniform float thunderStrength;
uniform int dimension;
uniform int isEyeInWater;
uniform int frameCounter;

varying vec2 vTexCoord;

vec3 viewPosition(vec2 uv, float depth) {
    depth = min(depth, 0.999999);
    vec4 clip = vec4(uv * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
    vec4 view = gbufferProjectionInverse * clip;
    return view.xyz / view.w;
}

vec2 projectView(vec3 position) {
    vec4 clip = gbufferProjection * vec4(position, 1.0);
    if (clip.w <= 0.0) return vec2(-1.0);
    return clip.xy / clip.w * 0.5 + 0.5;
}

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float exposedToRain(vec3 position, vec3 upView) {
    for (int i = 1; i <= 32; ++i) {
        vec3 probe = position + upView * float(i);
        vec2 uv = projectView(probe);
        if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
            return 0.0;
        }

        float sceneDepth = texture2D(depthtex0, uv).r;
        if (sceneDepth < 0.999999) {
            vec3 scenePosition = viewPosition(uv, sceneDepth);
            if (scenePosition.z > probe.z + 0.04 &&
                length(scenePosition.xy - probe.xy) < 0.45) {
                return 0.0;
            }
        }
    }
    return 1.0;
}

vec3 screenReflection(vec3 position, vec3 normal, vec3 fallbackColor) {
    vec3 direction = normalize(reflect(normalize(position), normal));
    vec3 ray = position + normal * 0.04;
    for (int i = 0; i < 20; ++i) {
        ray += direction * (0.18 + float(i) * 0.055);
        vec2 uv = projectView(ray);
        if (uv.x < 0.002 || uv.x > 0.998 || uv.y < 0.002 || uv.y > 0.998) {
            break;
        }

        float sceneDepth = texture2D(depthtex0, uv).r;
        if (sceneDepth < 0.999999) {
            vec3 scenePosition = viewPosition(uv, sceneDepth);
            float depthGap = scenePosition.z - ray.z;
            float lateralGap = length(scenePosition.xy - ray.xy);
            if (depthGap >= 0.0 && depthGap < 0.5 && lateralGap < 0.45) {
                return texture2D(colortex0, uv).rgb;
            }
        }
    }
    return fallbackColor;
}

void main() {
    vec2 uv = vTexCoord;
    vec3 color = texture2D(colortex0, uv).rgb;
    float depth = texture2D(depthtex1, uv).r;
    vec4 materialData = texture2D(colortex1, uv);
    float material = materialData.a;

    if (depth < 0.999999 && material > 0.5) {
        vec3 position = viewPosition(uv, depth);
        vec3 normal = normalize(materialData.rgb * 2.0 - 1.0);
        if (dot(normal, normalize(position)) > 0.0) normal = -normal;

        vec3 reflected = screenReflection(position, normal, color);
        float fresnel = pow(1.0 - clamp(abs(dot(normal, normalize(position))), 0.0, 1.0), 5.0);
        color = mix(color, reflected, 0.32 * (0.55 + 0.45 * fresnel));
    }

    if (depth < 0.999999 && rainStrength > 0.001) {
        vec3 position = viewPosition(uv, depth);
        vec3 normal = normalize(texture2D(colortex1, uv).rgb * 2.0 - 1.0);
        vec3 upView = normalize(mat3(gbufferModelView) * vec3(0.0, 1.0, 0.0));

        if (dot(normal, upView) > 0.72 &&
            exposedToRain(position, upView) > 0.5) {
            vec3 worldPosition = (gbufferModelViewInverse * vec4(position, 1.0)).xyz + cameraPosition;
            vec2 cell = floor(worldPosition.xz * 4.0);
            float randomValue = hash21(cell);
            float phase = fract(float(frameCounter) / 18.0 + randomValue);
            float hit = step(phase, rainStrength * 0.12);
            vec2 local = fract(worldPosition.xz * 4.0) - 0.5;
            vec2 rippleCenter = vec2(randomValue, hash21(cell + 7.1)) * 0.7;
            float radius = length(local - rippleCenter);
            float ripple = sin(radius * 42.0 - phase * 18.0) * exp(-radius * 5.0);
            float drop = hit * max(ripple, 0.0) * rainStrength;
            color += vec3(0.055, 0.065, 0.075) * drop *
                     (1.0 + clamp(thunderStrength, 0.0, 1.0) * 0.2);
        }
    }

    if (isEyeInWater == 1) {
        vec2 pixel = vec2(1.0 / viewWidth, 1.0 / viewHeight);
        float centerDepth = length(viewPosition(uv, depth));
        float depthEdge = 0.0;
        depthEdge = max(depthEdge, abs(centerDepth - length(viewPosition(uv + vec2(pixel.x, 0.0), texture2D(depthtex1, uv + vec2(pixel.x, 0.0)).r))));
        depthEdge = max(depthEdge, abs(centerDepth - length(viewPosition(uv - vec2(pixel.x, 0.0), texture2D(depthtex1, uv - vec2(pixel.x, 0.0)).r))));
        depthEdge = max(depthEdge, abs(centerDepth - length(viewPosition(uv + vec2(0.0, pixel.y), texture2D(depthtex1, uv + vec2(0.0, pixel.y)).r))));
        depthEdge = max(depthEdge, abs(centerDepth - length(viewPosition(uv - vec2(0.0, pixel.y), texture2D(depthtex1, uv - vec2(0.0, pixel.y)).r))));

        float screenEdge = smoothstep(0.64, 1.0,
            max(abs(uv.x * 2.0 - 1.0), abs(uv.y * 2.0 - 1.0)));
        float edgeMask = screenEdge *
            (0.35 + 0.65 * smoothstep(0.05, 0.5, depthEdge));
        vec3 blurred = color * 0.4;
        blurred += texture2D(colortex0, uv + vec2(pixel.x * 2.0, 0.0)).rgb * 0.15;
        blurred += texture2D(colortex0, uv - vec2(pixel.x * 2.0, 0.0)).rgb * 0.15;
        blurred += texture2D(colortex0, uv + vec2(0.0, pixel.y * 2.0)).rgb * 0.15;
        blurred += texture2D(colortex0, uv - vec2(0.0, pixel.y * 2.0)).rgb * 0.15;
        color = mix(color, blurred, edgeMask * 0.45);
        color *= 1.0 - edgeMask * 0.08;
    }

    float night = smoothstep(12500.0, 14000.0, worldTime) *
                  (1.0 - smoothstep(22000.0, 23500.0, worldTime));
    float weatherDarkness = mix(1.0, 0.8333333,
                                 clamp(rainStrength, 0.0, 1.0));
    weatherDarkness = mix(weatherDarkness, 0.6666667,
                          clamp(thunderStrength, 0.0, 1.0));

    float brightness = 0.987 * mix(1.0, 0.5, night) *
                       weatherDarkness;
    float contrast = 1.0135;
    if (dimension == -1) {
        brightness *= 0.988;
        contrast *= 1.0115;
    } else if (dimension == 1) {
        brightness *= 1.011;
        contrast *= 1.0115;
        float luminance = dot(color,
            vec3(0.2126, 0.7152, 0.0722));
        color = mix(vec3(luminance), color, 0.988);
    }

    color = (color - 0.5) * contrast + 0.5;
    color *= brightness;
    gl_FragColor = vec4(color, 1.0);
}
