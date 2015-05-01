#pragma once

#include "ofMain.h"
#include "ofxiOS.h"
#include "ofxiOSExtras.h"
#include "ofxOpenCv.h"
#include "ofxCv.h"
#include "Clone.h"
#include "ofxFaceTracker.h"
#include "ofxFaceTrackerThreaded.h"
#include "ofxiOSVideoWriter.h"

#include "THPhotoPickerViewController.h"

using namespace ofxCv;
using namespace cv;

class ofApp : public ofxiOSApp {
    
public:
    void setup();
    void update();
    void draw();
    void exit();

    void touchDown(ofTouchEventArgs & touch);
    void touchMoved(ofTouchEventArgs & touch);
    void touchUp(ofTouchEventArgs & touch);
    void touchDoubleTap(ofTouchEventArgs & touch);
    void touchCancelled(ofTouchEventArgs & touch);

    void lostFocus();
    void gotFocus();
    void gotMemoryWarning();
    void deviceOrientationChanged(int newOrientation);
    
    void setupCam(int width, int height);
    void dragEvent(ofDragInfo dragInfo);
    void loadFace(string face);
    void loadOFImage(ofImage image);

    ofxFaceTrackerThreaded camTracker;
    ofVideoGrabber cam;
    ofxCvColorImage colorCv;
    ofxCvColorImage srcColorCv;
    ofxiOSVideoWriter videoRecorder;
    ofxiOSVideoPlayer videoPlayer;
    
    ofxFaceTracker srcTracker;
    ofImage src;
    vector<ofVec2f> srcPoints;
    
    bool cloneReady;
    Clone clone;
    ofFbo srcFbo, maskFbo;
    
    ofDirectory faces;
};


