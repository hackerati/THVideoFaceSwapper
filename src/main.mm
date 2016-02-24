#include "ofMain.h"
#include "ofApp.h"

int main(){
    ofGLWindowSettings s;
    s.setGLVersion(3,2);
    ofCreateWindow(s);
    
	ofSetupOpenGL(1024,720,OF_FULLSCREEN);			// <-------- setup the GL context
    ofRunApp(new ofApp());
}
