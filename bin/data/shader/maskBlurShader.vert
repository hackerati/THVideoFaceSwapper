// these are for the programmable pipeline system
uniform mat4 modelViewProjectionMatrix;
attribute vec4 position;
attribute vec2 texcoord;

// this is something we're creating for this shader
varying vec2 texCoordVarying;


void main()
{
    
    texCoordVarying = texcoord;
    
    gl_Position = modelViewProjectionMatrix * position;
    
    
}