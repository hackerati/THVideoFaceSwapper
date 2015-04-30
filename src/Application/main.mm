#include "ofMain.h"
#include "ofApp.h"

int main(){
    ofSetCurrentRenderer(ofGLProgrammableRenderer::TYPE);
	ofSetupOpenGL(750,1334,OF_FULLSCREEN);			// <-------- setup the GL context
    ofRunApp(new ofApp());
}
