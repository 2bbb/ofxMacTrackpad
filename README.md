# ofxMacTrackpad

using MBP Trackpad events on openFrameworks.

( alternative of [ofxMultiTouchPad](https://github.com/jens-a-e/ofxMultiTouchPad) )

## Requirement

* Basic: OSX 10.7 and later
* Force touch: OSX 10.10.3 and later
* Touchbar: OSX 10.12.1 and later

## Tested env

* macOS 10.12.3 + of 0.9.8 + MBP 2016
* macOS 10.12.3 + of 0.9.8 + MBP 2016 + Magic Trackpad
* Mac OSX 10.10.3 + of 0.9.6 + MBP 2013

## Known issue

* Swipe event won't be received.

## How to use

```cpp

class ofApp {
	ofxMacTrackpadTouchArg touches;
public:
	void receiveTouches(ofxMacTrackpadTouchArg &arg) {
		touches = arg;
	}
	
	void setup() {
		ofAddListener(ofxMacTrackpad::multitouch, this, &ofApp::receiveTouches);
		
		ofxMacTrackpad::startListen();
	}
	
	void draw() {
		for(auto &finger : touches.fingers) {
			ofDrawCircle(
				ofMap(finger.position.x, 0.0f, 1.0f, 0.0f, ofGetWidth()),
				ofMap(finger.position.y, 0.0f, 1.0f, 0.0f, ofGetHeight()),
				40
			);
		}
	}
};

```

see example and source code.

## API

### Events

* ofEvent<TouchedFinger> touch;
* ofEvent<TouchedFinger> release;
* ofEvent<TouchArg> multitouch;

* ofEvent<TouchedFinger> touchTouchbar;
* ofEvent<TouchedFinger> releaseTouchbar;
* ofEvent<TouchArg> multitouchTouchbar;

* ofEvent<PressureArg> pressure;
* ofEvent<PinchArg> pinch;
* ofEvent<RotateArg> rotate;
* ofEvent<SwipeArg> swipe;
* ofEvent<TwoFingerDoubleTapArg> twoFingerDoubleTap;

### enum class ofxMacTrackpadEventPhase

* None
* Began
* Stationary
* Changed
* Ended
* Cancelled
* MayBegan

### struct ofxMacTrackpadTouchedFinger

* TouchPhase phase
* std::uint64_t identity
* std::uint64_t deviceID
* ofPoint position
* ofVec2f delta
* bool isResting

### struct ofxMacTrackpadTouchArg

* std::vector<ofxMacTrackpadTouchedFinger> fingers
* std::vector<ofxMacTrackpadTouchedFinger> releasedFingers
* ofxMacTrackpadEventPhase phase
* double timestamp

### struct ofxMacTrackpadPressureArg

* float pressure
* PressureBehavior behavior
* std::uint8_t stage
* float stageTransition
* float normalizedPressure()
* ofxMacTrackpadEventPhase phase
* double timestamp

### struct ofxMacTrackpadPinchArg

* float magnification
* ofxMacTrackpadEventPhase phase
* double timestamp

### struct RotateArg

* float rotation
* ofxMacTrackpadEventPhase phase
* double timestamp

### struct SwipeArg

* ofPoint delta
* ofxMacTrackpadEventPhase phase
* double timestamp

### TwoFingerDoubleTapArg

* ofxMacTrackpadEventPhase phase
* double timestamp

## Update history

### 2017/04/06 ver 0.01 release

## License

MIT License.

## Author

- ISHII 2bit [bufferRenaiss co., ltd.]
- ishii[at]buffer-renaiss.com

## At the last

Please create new issue, if there is a problem. And please throw pull request, if you have a cool idea!!
