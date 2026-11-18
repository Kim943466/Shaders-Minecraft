#version 330 compatibility
/* DRAWBUFFERS:0 */

uniform sampler2D colortex0;

varying vec2 vTexCoord;

void main() {
    gl_FragData[0] = vec4(texture2D(colortex0, vTexCoord).rgb, 1.0);
}
