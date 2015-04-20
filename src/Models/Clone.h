//
//  Clone.h
//  FaceSubstitutionCamera
//
//  Created by James Lilard on 2014/10/20.
//
//

#ifndef __FaceSubstitutionCamera__Clone__
#define __FaceSubstitutionCamera__Clone__

#include "ofMain.h"

class Clone{

public:
    void setup(int width, int height);
    void setStrength(int strength);
    void update(ofTexture &src, ofTexture &dst, ofTexture &mask);
    void draw(float x, float y);
    
    
//protected:
    void maskedBlur(ofTexture &tex, ofTexture &mask, ofFbo &result);
    ofFbo buffer, srcBlur, dstBlur;
    ofShader maskBlurShader, cloneShader;
    int strength;
    
    
    ofFbo debugFbo,debugResultFbo;
    void debugShader(ofTexture &tex, ofTexture &mask);
    
};

#endif /* defined(__FaceSubstitutionCamera__Clone__) */
