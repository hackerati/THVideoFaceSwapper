precision highp float;

uniform sampler2D src, srcBlur, dstBlur;

varying vec2 texCoordVarying;

void main() {
    vec2 pos = vec2(texCoordVarying.x, texCoordVarying.y);
    vec4 srcColorBlur = texture2D(srcBlur, pos);
    if(srcColorBlur.a > 0.){
        
        vec3 srcColor = texture2D(src, pos).rgb;
        vec4 dstColorBlur = texture2D(dstBlur, pos);
        vec3 offset = dstColorBlur.rgb - srcColorBlur.rgb;
        
        gl_FragColor = vec4(srcColor + offset, 1.);
    
    }
    else{
    
        gl_FragColor = vec4(0.);
        
    }
    
}
