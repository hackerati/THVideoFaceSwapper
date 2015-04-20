precision highp float;

uniform sampler2D tex0, mask;
uniform vec2 direction;
uniform int k;

varying vec2 texCoordVarying;

void main() {
        
    vec2 pos = vec2(texCoordVarying.x, texCoordVarying.y); //gl_TexCoord[0].st;
    vec4 sum = texture2D(tex0, pos);
    int i;
    for(i=1;i<k;i++){
        
        vec2 curOffset;
        curOffset.x = direction.x * float(i);
        curOffset.y = direction.y * float(i);
        
        
        vec4 mask2 = texture2D(mask, pos + curOffset);
        vec4 mask3 = texture2D(mask, pos - curOffset);
        
        if(mask2.r >= 0.5 && mask3.r >= 0.5){
            
            
            sum += texture2D(tex0, pos + curOffset) + texture2D(tex0, pos - curOffset);
            
        }
        else{
            
            break;
            
        }
    }
    int samples = 1 + (i-1)*2;
    sum /= float(samples);

    gl_FragColor = sum;
}

