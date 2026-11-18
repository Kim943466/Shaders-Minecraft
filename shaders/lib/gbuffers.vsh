attribute vec4 mc_Entity;

varying vec2 vTexCoord;
varying vec2 vLightCoord;
varying vec4 vColor;
varying vec3 vNormal;
varying float vMaterial;
varying float vFogDistance;

void main() {
    gl_Position = ftransform();
    vTexCoord = gl_MultiTexCoord0.st;
    vLightCoord = gl_MultiTexCoord1.st;
    vColor = gl_Color;
    vNormal = normalize(gl_NormalMatrix * gl_Normal);
    vFogDistance = length((gl_ModelViewMatrix * gl_Vertex).xyz);

    float blockId = mc_Entity.x;
    vMaterial = 0.0;
    if (blockId == 10001.0) vMaterial = 1.0;
    else if (blockId == 10002.0) vMaterial = 2.0;
    else if (blockId == 10003.0) vMaterial = 3.0;
}
