/* DRAWBUFFERS:01 */
uniform sampler2D texture;
uniform sampler2D lightmap;

varying vec2 vTexCoord;
varying vec2 vLightCoord;
varying vec4 vColor;
varying vec3 vNormal;
varying float vMaterial;
varying float vFogDistance;

void main() {
    vec4 albedo = texture2D(texture, vTexCoord) * vColor;
    if (albedo.a < 0.0039) discard;

    vec3 lighting = texture2D(lightmap, vLightCoord).rgb;
    gl_FragData[0] = vec4(albedo.rgb * lighting, albedo.a);
    gl_FragData[1] = vec4(normalize(vNormal) * 0.5 + 0.5, vMaterial);
}
