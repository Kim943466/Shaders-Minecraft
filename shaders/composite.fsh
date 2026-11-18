#version 330 compatibility

uniform sampler2D colortex0;

varying vec2 vTexCoord;

void main() {
    gl_FragColor = vec4(texture2D(colortex0, vTexCoord).rgb, 1.0);
}
