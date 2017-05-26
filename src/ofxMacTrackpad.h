//
//  ofxMacTrackpad.hpp
//
//  Created by ISHII 2bit on 2017/04/04.
//
//

#ifndef ofxMacTrackpad_h
#define ofxMacTrackpad_h

#include "ofMain.h"

namespace ofx {
    namespace MacTrackpad {
        enum class EventPhase : std::uint8_t {
            None       = 0,
            Began      = 0x1 << 0,
            Stationary = 0x1 << 1,
            Changed    = 0x1 << 2,
            Ended      = 0x1 << 3,
            Cancelled  = 0x1 << 4,
            MayBegin   = 0x1 << 5
        };
        
        struct BaseArg {
            EventPhase phase;
            double timestamp;
        };
        
        enum class TouchPhase : std::uint8_t {
            Began = 1 << 0,
            Moved = 1 << 1,
            Stationary = 1 << 2,
            Ended = 1 << 3,
            Cancelled = 1 << 4,
            Touching = Began | Moved | Stationary,
            Any = 255
        };
        
        struct TouchedFinger {
            TouchPhase phase;
            std::uint64_t identity;
            ofPoint position;
            ofVec2f delta;
            bool isResting;
            
            operator ofPoint &() { return position; }
            operator ofPoint() const { return position; }
        };
        
        struct TouchArg : BaseArg {
            std::vector<TouchedFinger> fingers;
            std::vector<TouchedFinger> releasedFingers;
        };
        
        enum class PressureBehavior : std::int8_t {
            Unknown = -1,
            PrimaryDefault = 0,
            PrimaryClick = 1,
            PrimaryGeneric = 2,
            PrimaryAccelerator = 3,
            PrimaryDeepClick = 5,
            PrimaryDeepDrag = 6
        };
        
        struct PressureArg : BaseArg {
            float pressure;
            PressureBehavior behavior;
            std::uint8_t stage;
            float stageTransition;
            
            inline float normalizedPressure() const {
                return (phase == EventPhase::Ended) ? 0.0f : ofClamp(0.5f * (pressure + stage - 1), 0.0f, 1.0f);
            }
        };
        
        struct PinchArg : BaseArg {
            float magnification;
        };
        
        struct RotateArg : BaseArg {
            float rotation;
        };
        
        struct SwipeArg : BaseArg {
            ofPoint delta;
        };
        
        struct TwoFingerDoubleTapArg : BaseArg {};
        
        extern ofEvent<TouchedFinger> touch;
        extern ofEvent<TouchedFinger> release;
        extern ofEvent<TouchArg> multitouch;
        
        extern ofEvent<TouchedFinger> touchTouchbar;
        extern ofEvent<TouchedFinger> releaseTouchbar;
        extern ofEvent<TouchArg> multitouchTouchbar;
        
        extern ofEvent<PressureArg> pressure;
        extern ofEvent<PinchArg> pinch;
        extern ofEvent<RotateArg> rotate;
        extern ofEvent<SwipeArg> swipe;
        extern ofEvent<TwoFingerDoubleTapArg> twoFingerDoubleTap;
        
        void startListening();
        void stopListening();
            
        std::vector<TouchedFinger> getTouchedFingers();
        std::vector<TouchedFinger> getTouchbarFingers();
    };
};

namespace ofxMacTrackpad = ofx::MacTrackpad;

using ofxMacTrackpadEventPhase = ofxMacTrackpad::EventPhase;

using ofxMacTrackpadTouchPhase = ofxMacTrackpad::TouchPhase;
using ofxMacTrackpadTouchedFinger = ofxMacTrackpad::TouchedFinger;
using ofxMacTrackpadTouchArg = ofxMacTrackpad::TouchArg;

using ofxMacTrackpadPressureBehavior = ofxMacTrackpad::PressureBehavior;
using ofxMacTrackpadPressureArg = ofxMacTrackpad::PressureArg;

using ofxMacTrackpadPinchArg = ofxMacTrackpad::PinchArg;
using ofxMacTrackpadRotateArg = ofxMacTrackpad::RotateArg;
using ofxMacTrackpadSwipeArg = ofxMacTrackpad::SwipeArg;
using ofxMacTrackpadTwoFingerDoubleTapArg = ofxMacTrackpad::TwoFingerDoubleTapArg;

#endif /* ofxMacTrackpad_h */
