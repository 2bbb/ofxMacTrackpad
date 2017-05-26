//
//  ofxMacTrackpad.mm
//
//  Created by ISHII 2bit on 2017/04/04.
//
//

#include "ofxMacTrackpad.h"

#import <AppKit/AppKit.h>
#import <ApplicationServices/ApplicationServices.h>

#ifndef MAC_OS_X_VERSION_10_7
#   error this addon requires osx 10.7+
#endif

NSEventMask eventMask   = NSEventMaskGesture
                        | NSEventMaskBeginGesture
                        | NSEventMaskEndGesture
                        | NSEventMaskMagnify
                        | NSEventMaskSwipe
                        | NSEventMaskRotate
#ifdef MAC_OS_X_VERSION_10_8
                        | NSEventMaskSmartMagnify
#endif
#ifdef MAC_OS_X_VERSION_10_12_1
                        | NSEventMaskDirectTouch
#endif
#ifdef MAC_OS_X_VERSION_10_10_3
                        | NSEventMaskPressure
#endif
;

namespace ofx {
    namespace MacTrackpad {
        ofEvent<TouchedFinger> touch;
        ofEvent<TouchedFinger> release;
        ofEvent<TouchArg> multitouch;
        
        ofEvent<TouchedFinger> touchTouchbar;
        ofEvent<TouchedFinger> releaseTouchbar;
        ofEvent<TouchArg> multitouchTouchbar;
        
        ofEvent<PressureArg> pressure;
        ofEvent<PinchArg> pinch;
        ofEvent<RotateArg> rotate;
        ofEvent<SwipeArg> swipe;
        ofEvent<TwoFingerDoubleTapArg> twoFingerDoubleTap;
        
        std::map<std::uint64_t, TouchedFinger> currentFingers;
        std::map<std::uint64_t, TouchedFinger> currentTouchbarFingers;
        CGEventRef eventTapCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef eventRef, void *refcon);
        bool stopListening(ofEventArgs &arg);
        CFRunLoopRef runLoop;
        CFMachPortRef eventTap;
        CFRunLoopSourceRef runLoopSource;
        
        void startListening() {
            runLoop = CFRunLoopGetCurrent();
            eventTap = CGEventTapCreate(kCGSessionEventTap,
                                        kCGHeadInsertEventTap,
                                        kCGEventTapOptionListenOnly,
                                        kCGEventMaskForAllEvents,
                                        eventTapCallback,
                                        nil);
            runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0);
            CFRunLoopAddSource(runLoop, runLoopSource, kCFRunLoopCommonModes);
            CGEventTapEnable(eventTap, true);
            
            ofAddListener(ofEvents().exit, &stopListening, OF_EVENT_ORDER_BEFORE_APP);
        }
        
        void stopListening() {
            if(eventTap != NULL) {
                CGEventTapEnable(eventTap, false);
            }
            if(runLoopSource != NULL) {
                CFRunLoopRemoveSource(runLoop, runLoopSource, kCFRunLoopCommonModes);
                CFRelease(runLoopSource);
            }
        }
        
        bool stopListening(ofEventArgs &arg) {
            stopListening();
        }

        std::vector<TouchedFinger> getTouchedFingers() {
            std::vector<TouchedFinger> fingers;
            for(const auto &it : currentFingers) fingers.push_back(it.second);
            return fingers;
        }

        std::vector<TouchedFinger> getTouchbarFingers() {
            std::vector<TouchedFinger> fingers;
            for(const auto &it : currentTouchbarFingers) fingers.push_back(it.second);
            return fingers;
        }
        
        CGEventRef eventTapCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef eventRef, void *refcon) {
            
            if(type == kCGEventTapDisabledByUserInput) return eventRef;
            if(type == kCGEventTapDisabledByTimeout) return eventRef;
            // type == 30 then NSEvent can't be made from eventRef
            if(type == 30) return eventRef;
            NSEvent *event = [NSEvent eventWithCGEvent:eventRef];
            
            // filter out events which do not match the mask
            if(!(eventMask & NSEventMaskFromType(event.type))) return event.CGEvent;
            
            switch(event.type) {
                case NSEventTypeSwipe: {
                    ofLogNotice() << "Swipe";
                    SwipeArg arg;
                    arg.delta.x = event.deltaX;
                    arg.delta.y = event.deltaY;
                    arg.phase = static_cast<EventPhase>(event.phase);
                    arg.timestamp = event.timestamp;
                    
                    ofNotifyEvent(ofxMacTrackpad::swipe, arg);
                    break;
                }
                case NSEventTypeRotate: {
                    RotateArg arg;
                    arg.rotation = event.rotation;
                    arg.phase = static_cast<EventPhase>(event.phase);
                    arg.timestamp = event.timestamp;
                    
                    ofNotifyEvent(ofxMacTrackpad::rotate, arg);
                    break;
                }
                case NSEventTypeMagnify: {
                    PinchArg arg;
                    arg.magnification = event.magnification;
                    arg.phase = static_cast<EventPhase>(event.phase);
                    arg.timestamp = event.timestamp;
                    
                    ofNotifyEvent(ofxMacTrackpad::pinch, arg);
                    break;
                }
#ifdef MAC_OS_X_VERSION_10_8
                case NSEventTypeSmartMagnify: {
                    TwoFingerDoubleTapArg arg;
                    arg.phase = static_cast<EventPhase>(event.phase);
                    arg.timestamp = event.timestamp;
                    ofNotifyEvent(twoFingerDoubleTap, arg);
                    break;
                }
#endif
#ifdef MAC_OS_X_VERSION_10_10_3
                case NSEventTypePressure: {
                    PressureArg arg;
                    arg.pressure = event.pressure;
                    arg.behavior = static_cast<PressureBehavior>(event.pressureBehavior);
                    arg.stage    = event.stage;
                    arg.stageTransition = event.stageTransition;
                    arg.phase    = static_cast<EventPhase>(event.phase);
                    arg.timestamp = event.timestamp;
                    
                    ofNotifyEvent(ofxMacTrackpad::pressure, arg);
                }
#endif
                default:
                    break;
            }
            
            if(event.type == NSEventTypeGesture) {
                NSArray<NSTouch *> *touches = [event touchesMatchingPhase:NSTouchPhaseAny inView:nil].allObjects;
                TouchArg touchEvent;
                touchEvent.phase = static_cast<EventPhase>(event.phase);
                touchEvent.timestamp = event.timestamp;
                for(std::size_t i = 0, size = touches.count; i < size; i++) {
                    NSTouch *touch = touches[i];
#ifdef MAC_OS_X_VERSION_10_12_1
                    if(touch.type == NSTouchTypeDirect) continue;
#endif
                    std::uint64_t identity = reinterpret_cast<std::uint64_t>(touch.identity);
                    if(currentFingers.find(identity) != currentFingers.end()) {
                        TouchedFinger &arg = currentFingers[identity];
                        NSPoint p = touch.normalizedPosition;
                        arg.delta.x = p.x - arg.position.x;
                        arg.delta.y = (1.0f - arg.position.y) - p.y;
                        
                        arg.position.x = p.x;
                        arg.position.y = 1.0f - p.y;
                        
                        arg.deviceID = reinterpret_cast<std::uint64_t>(touch.device);
#ifdef MAC_OS_X_VERSION_10_10
                        arg.isResting = touch.isResting;
#endif
                        arg.phase = (touch.phase == NSTouchPhaseAny)
                                  ? TouchPhase::Any
                                  : static_cast<TouchPhase>(touch.phase);
                    } else {
                        TouchedFinger arg;
                        arg.identity = identity;
                        arg.delta.x = 0.0f;
                        arg.delta.y = 0.0f;
                        
                        NSPoint p = touch.normalizedPosition;
                        arg.position.x = p.x;
                        arg.position.y = 1.0f - p.y;
                        arg.deviceID = reinterpret_cast<std::uint64_t>(touch.device);
                        
#ifdef MAC_OS_X_VERSION_10_10
                        arg.isResting = touch.isResting;
#endif
                        arg.phase = (touch.phase == NSTouchPhaseAny)
                                  ? TouchPhase::Any
                                  : static_cast<TouchPhase>(touch.phase);
                        
                        currentFingers[identity] = arg;
                        ofNotifyEvent(ofxMacTrackpad::touch, arg);
                    }
                    
                    if(!(touch.phase & NSTouchPhaseTouching)) {
                        TouchedFinger &arg = currentFingers[identity];
                        ofNotifyEvent(release, arg);
                        touchEvent.releasedFingers.push_back(arg);
                        currentFingers.erase(identity);
                    }
                }
                
                for(const auto &it : currentFingers) touchEvent.fingers.push_back(it.second);
                ofNotifyEvent(multitouch, touchEvent);
            }
            
#ifdef MAC_OS_X_VERSION_10_12_1
            else if(event.type == NSEventTypeDirectTouch) {
                // Touchbar
                NSArray<NSTouch *> *touches = [event touchesMatchingPhase:NSTouchPhaseAny inView:nil].allObjects;
                TouchArg touchEvent;
                touchEvent.phase = static_cast<EventPhase>(event.phase);
                touchEvent.timestamp = event.timestamp;
                for(std::size_t i = 0, size = touches.count; i < size; i++) {
                    NSTouch *touch = touches[i];
                    std::uint64_t identity = reinterpret_cast<std::uint64_t>(touch.identity);;
                    if(currentTouchbarFingers.find(identity) != currentTouchbarFingers.end()) {
                        TouchedFinger &arg = currentTouchbarFingers[identity];
                        NSPoint p = [touch locationInView:nil];
                        arg.delta.x = p.x - arg.position.x;
                        arg.delta.y = (1.0f - arg.position.y) - p.y;
                        
                        arg.position.x = p.x;
                        arg.position.y = 1.0f - p.y;
#ifdef MAC_OS_X_VERSION_10_10
                        arg.isResting = touch.isResting;
#endif
                        
                        arg.phase = (touch.phase == NSTouchPhaseAny)
                                  ? TouchPhase::Any
                                  : static_cast<TouchPhase>(touch.phase);
                    } else {
                        TouchedFinger arg;
                        arg.identity = identity;
                        arg.delta.x = 0.0f;
                        arg.delta.y = 0.0f;
                        
                        NSPoint p = [touch locationInView:nil];;
                        arg.position.x = p.x;
                        arg.position.y = 1.0f - p.y;
                        arg.isResting = touch.isResting;
                        
                        arg.phase = (touch.phase == NSTouchPhaseAny)
                                  ? TouchPhase::Any
                                  : static_cast<TouchPhase>(touch.phase);

                        currentTouchbarFingers[identity] = arg;
                        ofNotifyEvent(touchTouchbar, arg);
                    }
                    
                    if(!(touch.phase & NSTouchPhaseTouching)) {
                        TouchedFinger &arg = currentTouchbarFingers[identity];
                        ofNotifyEvent(releaseTouchbar, arg);
                        touchEvent.releasedFingers.push_back(arg);
                        currentTouchbarFingers.erase(identity);
                    }
                }
                
                for(const auto &it : currentTouchbarFingers) touchEvent.fingers.push_back(it.second);
                ofNotifyEvent(multitouchTouchbar, touchEvent);
            }
#endif
            return event.CGEvent;
        }
    };
};
