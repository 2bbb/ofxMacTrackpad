#include "ofMain.h"
#include "ofxMacTrackpad.h"

class ofApp : public ofBaseApp {
    ofxMacTrackpadTouchArg touch;
    ofxMacTrackpadTouchArg touchbar;
    ofxMacTrackpadPressureArg pressure;
    static constexpr int size = 20;
    float rotation{0.0f};
    float zoom{1.0f};
    ofPoint delta;
public:
    void setup() {
        ofAddListener(ofxMacTrackpad::multitouch, this, &ofApp::receiveTouch);
        ofAddListener(ofxMacTrackpad::multitouchTouchbar, this, &ofApp::receiveTouchbar);
        ofAddListener(ofxMacTrackpad::pressure, this, &ofApp::receivePressure);
        ofAddListener(ofxMacTrackpad::rotate, this, &ofApp::didRotate);
        ofAddListener(ofxMacTrackpad::pinch, this, &ofApp::didPinch);
        ofAddListener(ofxMacTrackpad::swipe, this, &ofApp::didSwipe);
        
        ofxMacTrackpad::startListening();
        
        ofSetBackgroundAuto(false);
    }
    void update() {
        
    }
    void draw() {
        ofBackground(0, 0, 0);
        
        ofSetColor(0, 32);
        ofDrawRectangle(ofGetWindowRect());
        
        ofSetColor(0, 255, 0, 255);
        for(const auto &finger : touchbar.fingers) {
            float x = ofMap(finger.position.x, 0, 1080, 0, ofGetWidth(), true);
            ofDrawLine(x, 0, x, ofGetHeight());
        }
        
        ofPushMatrix();
        ofTranslate(ofGetWidth() / 2 + delta.x, ofGetHeight() / 2 + delta.y);
        ofRotate(-rotation);
        ofScale(zoom, zoom);
        ofTranslate(-ofGetWidth() / 2, -ofGetHeight() / 2);
        float colorScale = pressure.normalizedPressure();
        ofSetColor(255 * (1.0f - colorScale), 255 * (1.0f - colorScale), 255);
        ofDrawRectangle(ofGetWidth() / 2 - 100, ofGetHeight() / 2 - 100, 200, 200);
        ofPopMatrix();
        
        ofSetColor(255, 0, 0, 128);
        for(auto &finger : touch.fingers) {
            ofPoint last = finger.position - finger.delta * 10;
            ofSetColor(255, 0, 0, 128);
            float x0 = ofMap(finger.position.x, 0, 1, size, ofGetWidth() - size),
                  y0 = ofMap(finger.position.y, 0, 1, size, ofGetHeight() - size),
                  x1 = ofMap(last.x, 0, 1, size, ofGetWidth() - size),
                  y1 = ofMap(last.y, 0, 1, size, ofGetHeight() - size);
            ofDrawLine(x0, y0, x1, y1);
            ofDrawCircle(x0, y0, size);
            ofSetColor(255, 255, 255, 128);
            ofDrawBitmapString(ofVAArgsToString("id: %lu", finger.deviceID), x0, y0);
        }
        
        ofSetColor(255);
        ofDrawBitmapString(ofVAArgsToString("phase:      %d", pressure.phase), 20, 20);
        ofDrawBitmapString(ofVAArgsToString("pressure:   %f", pressure.pressure), 20, 40);
        ofDrawBitmapString(ofVAArgsToString("stage:      %d", pressure.stage), 20, 60);
        ofDrawBitmapString(ofVAArgsToString("transition: %f", pressure.stageTransition), 20, 80);
        ofDrawBitmapString(ofVAArgsToString("behavior:   %d", pressure.behavior), 20, 100);
    }
    void exit() {}
    
    void receiveTouch(ofxMacTrackpadTouchArg &touch) {
        this->touch = touch;
    }
    
    void receiveTouchbar(ofxMacTrackpadTouchArg &touch) {
        this->touchbar = touch;
    }
    
    void receivePressure(ofxMacTrackpadPressureArg &pressure) {
        this->pressure = pressure;
    }
    
    void didRotate(ofxMacTrackpad::RotateArg &arg) {
        rotation += arg.rotation;
    }
    
    void didPinch(ofxMacTrackpad::PinchArg &arg) {
        zoom += arg.magnification;
        if(zoom <= 0.1f) zoom = 0.1f;
        if(4.0f < zoom) zoom = 4.0f;
    }
    
    void didSwipe(ofxMacTrackpad::SwipeArg &arg) {
        delta += arg.delta;
    }
    
    void keyPressed(int key) {}
    void keyReleased(int key) {}
    void mouseMoved(int x, int y ) {}
    void mouseDragged(int x, int y, int button) {}
    void mousePressed(int x, int y, int button) {}
    void mouseReleased(int x, int y, int button) {}
    void mouseEntered(int x, int y) {}
    void mouseExited(int x, int y) {}
    void windowResized(int w, int h) {}
    void dragEvent(ofDragInfo dragInfo) {}
    void gotMessage(ofMessage msg) {}
};

int main() {
    ofSetupOpenGL(1280, 720, OF_WINDOW);
    ofRunApp(new ofApp());
}
