#version 330 compatibility

varying vec2 vTexCoord;

void main() {
    gl_Position = ftransform();
    vTexCoord = gl_MultiTexCoord0.st;
}
