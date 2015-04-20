//
//  Clone.cpp
//  FaceSubstitutionCamera
//
//  Created by James Lilard on 2014/10/20.
//
//

#include "Clone.h"


void Clone::setup(int width, int height) {
    ofFbo::Settings settings;
    settings.width = width;
    settings.height = height;
    
    buffer.allocate(settings);
    srcBlur.allocate(settings);
    dstBlur.allocate(settings);

    maskBlurShader.load("shader/maskBlurShader");
    cloneShader.load("shader/cloneShader");
    
    strength = 0;
}

void Clone::maskedBlur(ofTexture& tex, ofTexture& mask, ofFbo& result) {
    int k = strength;
    
    buffer.begin();
    maskBlurShader.begin();
    maskBlurShader.setUniformTexture("tex0", tex, 1);
    maskBlurShader.setUniformTexture("mask", mask, 2);
    maskBlurShader.setUniform2f("direction", 1./(tex.getWidth()*2), 0.);
    maskBlurShader.setUniform1i("k", k);
    tex.draw(0, 0);
    maskBlurShader.end();
    buffer.end();

    result.begin();
    maskBlurShader.begin();
    maskBlurShader.setUniformTexture("tex0", buffer, 1);
    maskBlurShader.setUniformTexture("mask", mask, 2);
    maskBlurShader.setUniform2f("direction", 0., 1./(buffer.getHeight()));
    maskBlurShader.setUniform1i("k", k);
    buffer.draw(0, 0);
    maskBlurShader.end();
    buffer.draw(0, 0);
    result.end();
}

void Clone::setStrength(int strength) {
    this->strength = strength;
}

void Clone::update(ofTexture& src, ofTexture& dst, ofTexture& mask) {
    maskedBlur(src, mask, srcBlur);
    maskedBlur(dst, mask, dstBlur);
    
    buffer.begin();
    ofPushStyle();
    ofEnableAlphaBlending();
    dst.draw(0, 0);
    cloneShader.begin();
    cloneShader.setUniformTexture("src", src, 1);
    cloneShader.setUniformTexture("srcBlur", srcBlur, 2);
    cloneShader.setUniformTexture("dstBlur", dstBlur, 3);
    dst.draw(0, 0);
    cloneShader.end();
    ofDisableAlphaBlending();
    ofPopStyle();
    buffer.end();
}

void Clone::draw(float x, float y) {
    buffer.draw(x, y);
}


void Clone::debugShader(ofTexture &tex, ofTexture &mask){

    debugFbo.allocate(buffer.getWidth(), buffer.getHeight());
    debugResultFbo.allocate(buffer.getWidth(), buffer.getHeight());
    ofShader debugShader;
    debugShader.load("shader/maskBlurShader");
    
    setStrength(16);
    

    debugFbo.begin();
    
//    debugShader.begin();
//    
//    //maskBlurShader.setUniformTexture("tex", tex, 1);
//    debugShader.setUniformTexture("tex0", tex, 1);
//    debugShader.setUniformTexture("mask", mask, 2);
//    debugShader.setUniform2f("direction", 0, 1);
//    debugShader.setUniform1i("k", strength);
//    mask.draw(0, 0);
//    
//    debugShader.end();
    maskBlurShader.begin();
    maskBlurShader.setUniformTexture("tex0", tex, 1);
    maskBlurShader.setUniformTexture("mask", mask, 2);
    //maskBlurShader.setUniform2f("direction", 0., 1./tex.getHeight());
    maskBlurShader.setUniform2f("direction", 1./tex.getWidth(), 0.);
    maskBlurShader.setUniform1i("k", strength);
    tex.draw(0, 0);
    maskBlurShader.end();
    
    
    debugFbo.end();
    
//    debugResultFbo.begin();
//    
//    maskBlurShader.setUniformTexture("tex0", debugFbo, 1);
//    maskBlurShader.setUniformTexture("mask", mask, 2);
//    maskBlurShader.setUniform2f("direction", 0., 1./tex.getHeight());
//    maskBlurShader.setUniform1i("k", strength);
//    debugFbo.draw(0, 0);
//    
//    debugResultFbo.end();
    
    
}