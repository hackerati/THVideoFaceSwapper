#include "ofApp.h"

THPhotoPickerViewController *photoPicker;
NSMutableArray *facesArray;

//--------------------------------------------------------------
void ofApp::setup(){
    faces.allowExt("jpg");
    faces.allowExt("jpeg");
    faces.allowExt("png");
    faces.open("faces/");
    faces.listDir();
    currentFace = 0;
    
    facesArray = [NSMutableArray array];
    if(faces.size() != 0){
        for (int i = 0; i < faces.size(); i++) {
            NSString *pathToCurrentFace = [NSString stringWithCString:faces.getPath(i).c_str()
                                                             encoding:[NSString defaultCStringEncoding]];
            [facesArray addObject:pathToCurrentFace];
        }
    }
    photoPicker = [[THPhotoPickerViewController alloc] initWithFaces:facesArray];
    
    ofSetVerticalSync(true);
    cloneReady = false;
    
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
    
//    dispatch_async(dispatch_get_main_queue(), ^{
        cloneReady = false;
        src.clear();
        srcPoints.clear();
        srcTracker.setup();
//    });
    
    if(input.getWidth() > 0) {
        
        if(input.getWidth() > input.getHeight()){
            input.resize(ofGetWidth(), input.getHeight()*ofGetWidth() /input.getWidth());
        }
        else{
            input.resize(input.getWidth()*ofGetHeight()/input.getHeight(), ofGetHeight());
        }
        
//        dispatch_async(dispatch_get_main_queue(), ^{
            src = input;
            srcTracker.update(toCv(input));
            srcPoints = srcTracker.getImagePoints();
            cloneReady = true;
//        });
    }
}

void ofApp::setupCam(int width, int height) {
    cam.setDesiredFrameRate(24);
    cam.setDeviceID(1); // front facing camera
    cam.initGrabber(width, height);
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
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:photoPicker];
    [ofxiOSGetViewController() presentViewController:navController animated:YES completion:nil];
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
