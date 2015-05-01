#include "ofApp.h"

THPhotoPickerViewController *photoPicker;

//--------------------------------------------------------------
void ofApp::setup(){
    cout << ofxiOSGetUIWindow().bounds.size.width << " : " << ofxiOSGetUIWindow().bounds.size.height << endl;
    faces.allowExt("jpg");
    faces.allowExt("jpeg");
    faces.allowExt("png");
    faces.open("faces/");
    faces.listDir();
    
    ofSetVerticalSync(true);
    cloneReady = false;
    
    photoPicker = [[THPhotoPickerViewController alloc] init];
    
    int screenWidth = [UIScreen mainScreen].bounds.size.width;
    int screenHeight = [UIScreen mainScreen].bounds.size.height;
    setupCam(screenWidth, screenHeight);
    
    ofFbo::Settings settings;
    settings.width = cam.getWidth();
    settings.height = cam.getHeight();
    maskFbo.allocate(settings);
    srcFbo.allocate(settings);
    clone.setup(cam.getWidth(), cam.getHeight());
    
    camTracker.setup();
    srcTracker.setup();
    srcTracker.setIterations(15);
    srcTracker.setAttempts(4);
    
    if ( faces.size() > 0 ) {
        loadFace(faces.getPath(0));
    }
    
    colorCv.allocate(cam.getWidth(), cam.getHeight());
    
    videoRecorder = ofxiOSVideoWriter();
    videoRecorder.setup(ofGetWidth(), ofGetHeight());
    videoRecorder.setFPS(30);
    
//    videoPlayer = ofxiOSVideoPlayer();
    
}

//--------------------------------------------------------------
void ofApp::update(){
    cam.update();
    if(cam.isFrameNew()) {
        colorCv = cam.getPixels();
        camTracker.update(toCv(colorCv));
        
        cloneReady = camTracker.getFound();
        if(cloneReady) {
            ofMesh camMesh = camTracker.getImageMesh();
            camMesh.clearTexCoords();
            camMesh.addTexCoords(srcPoints);
            
            maskFbo.begin();
            ofClear(0, 255);
            camMesh.draw();
            maskFbo.end();
            
            srcFbo.begin();
            ofClear(0, 255);
            src.bind();
            camMesh.draw();
            src.unbind();
            srcFbo.end();
            
            clone.setStrength(16);
            clone.update(srcFbo.getTextureReference(), cam.getTextureReference(), maskFbo.getTextureReference());
        }
    }
}

//--------------------------------------------------------------
void ofApp::draw(){
    ofSetColor(255);
    cam.draw(0, 0);
    
    if ( src.getWidth() == 0 ) {
        ofDrawBitmapStringHighlight("SELECT OR TAKE AN IMAGE", 10, 30);
    }
    else if( !srcTracker.getFound() ) {
        ofDrawBitmapStringHighlight("SELECTED IMAGE FACE CANNOT BE FOUND", 10, 30);
    }
    else if ( !camTracker.getFound() ) {
        ofDrawBitmapStringHighlight("CAMERA FACE NOT FOUND", 10, 30);
    }
    else {
        if( cloneReady ) {
            clone.draw(0, 0);
            ofMesh objectMesh = camTracker.getObjectMesh();
            for(int i=0; i< objectMesh.getTexCoords().size(); i++) {
                ofVec2f & texCoord = objectMesh.getTexCoords()[i];
                texCoord.x /= ofNextPow2(cam.getWidth());
                texCoord.y /= ofNextPow2(cam.getHeight());
            }

            ofMesh imgMesh = srcTracker.getObjectMesh();
            for(int i=0; i< imgMesh.getTexCoords().size(); i++) {
                ofVec2f & texCoord = imgMesh.getTexCoords()[i];
                texCoord.x /= ofNextPow2(src.getWidth());
                texCoord.y /= ofNextPow2(src.getHeight());
            }
            
            for(int i = 0; i < objectMesh.getNumVertices();i++){
                ofVec3f vertex = objectMesh.getVertex(i);
                imgMesh.setVertex(i, vertex);
            }
            
            ofVec2f position = camTracker.getPosition();
            float scale = camTracker.getScale();
            ofVec3f orientation = camTracker.getOrientation();
            ofPushMatrix();
            ofTranslate(position.x, position.y);
            ofScale(scale, scale, scale);
            ofRotateX(orientation.x * 45.0f);
            ofRotateY(orientation.y * 45.0f);
            ofRotateZ(orientation.z * 45.0f);
            ofSetColor(255,255,255,255);
            src.getTextureReference().bind();
            imgMesh.draw();
            src.getTextureReference().unbind();
            ofPopMatrix();
            src.draw(0, 0, 100, 100);
        }
    }
}

void ofApp::loadFace(string face){
    cloneReady = false;
    src.clear();
    src.loadImage(face);
        
    if(src.getWidth() > 0) {
        Mat cvImage = toCv(src);
        srcTracker.update(cvImage);
        srcPoints = srcTracker.getImagePoints();
        cloneReady = true;
    }
    
}

void ofApp::loadOFImage(ofImage input) {
    
    cloneReady = false;
    src.clear();
    srcPoints.clear();
    srcTracker.setup();
    
    if(input.getWidth() > 0) {
        
        if(input.getWidth() > input.getHeight()){
            
            input.resize(ofGetWidth(), input.getHeight()*ofGetWidth() /input.getWidth());
        }
        else{
            
            input.resize(input.getWidth()*ofGetHeight()/input.getHeight(), ofGetHeight());
        }
        
        src = input;
        Mat cvImage = toCv(input);
        srcTracker.update(cvImage);
        srcPoints = srcTracker.getImagePoints();
        cloneReady = true;
    }
}

void ofApp::setupCam(int width, int height) {
    
    cam.setDesiredFrameRate(24);
    
    if ( cam.listDevices().size() > 1 ) {
        cam.setDeviceID(1); // front facing camera
    }
    else {
        cam.setDeviceID(0); // rear facing camera
    }
    
    cam.initGrabber(width, height);

    
    if ( !camTracker.isThreadRunning() ) {
        camTracker.startThread();
    }
}

void ofApp::dragEvent(ofDragInfo dragInfo) {
    
}

//--------------------------------------------------------------
void ofApp::exit(){
    camTracker.waitForThread();
}

//--------------------------------------------------------------
void ofApp::touchDown(ofTouchEventArgs & touch){
}

//--------------------------------------------------------------
void ofApp::touchMoved(ofTouchEventArgs & touch){

}

//--------------------------------------------------------------
void ofApp::touchUp(ofTouchEventArgs & touch){

}

//--------------------------------------------------------------
void ofApp::touchDoubleTap(ofTouchEventArgs & touch){
    if ( videoRecorder.isRecording() ) {
        videoRecorder.finishRecording();
    }
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:photoPicker];
    UIViewController *vc = (UIViewController *)ofxiOSGetViewController();
    [vc presentViewController:navController animated:YES completion:^{
        cam.close();
        camTracker.stopThread();
    }];
}

//--------------------------------------------------------------
void ofApp::touchCancelled(ofTouchEventArgs & touch){
    
}

//--------------------------------------------------------------
void ofApp::lostFocus(){

}

//--------------------------------------------------------------
void ofApp::gotFocus(){

}

//--------------------------------------------------------------
void ofApp::gotMemoryWarning(){

}

//--------------------------------------------------------------
void ofApp::deviceOrientationChanged(int newOrientation){

}
