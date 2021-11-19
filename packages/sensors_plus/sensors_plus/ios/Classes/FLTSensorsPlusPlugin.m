// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "FLTSensorsPlusPlugin.h"
#import <CoreMotion/CoreMotion.h>

@implementation FLTSensorsPlusPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FLTAccelerometerStreamHandlerPlus* accelerometerStreamHandler =
      [[FLTAccelerometerStreamHandlerPlus alloc] init];
  FlutterEventChannel* accelerometerChannel =
      [FlutterEventChannel eventChannelWithName:@"dev.fluttercommunity.plus/sensors/accelerometer"
                                binaryMessenger:[registrar messenger]];
  [accelerometerChannel setStreamHandler:accelerometerStreamHandler];

  FLTUserAccelStreamHandlerPlus* userAccelerometerStreamHandler =
      [[FLTUserAccelStreamHandlerPlus alloc] init];
  FlutterEventChannel* userAccelerometerChannel =
      [FlutterEventChannel eventChannelWithName:@"dev.fluttercommunity.plus/sensors/user_accel"
                                binaryMessenger:[registrar messenger]];
  [userAccelerometerChannel setStreamHandler:userAccelerometerStreamHandler];

  FLTGyroscopeStreamHandlerPlus* gyroscopeStreamHandler =
      [[FLTGyroscopeStreamHandlerPlus alloc] init];
  FlutterEventChannel* gyroscopeChannel =
      [FlutterEventChannel eventChannelWithName:@"dev.fluttercommunity.plus/sensors/gyroscope"
                                binaryMessenger:[registrar messenger]];
  [gyroscopeChannel setStreamHandler:gyroscopeStreamHandler];

  FLTMagnetometerStreamHandlerPlus* magnetometerStreamHandler =
      [[FLTMagnetometerStreamHandlerPlus alloc] init];
  FlutterEventChannel* magnetometerChannel =
      [FlutterEventChannel eventChannelWithName:@"dev.fluttercommunity.plus/sensors/magnetometer"
                                binaryMessenger:[registrar messenger]];
  [magnetometerChannel setStreamHandler:magnetometerStreamHandler];

  FLTMagicStreamHandlerPlus* magicStreamHandler =
      [[FLTMagicStreamHandlerPlus alloc] init];
  FlutterEventChannel* magicChannel =
      [FlutterEventChannel eventChannelWithName:@"dev.fluttercommunity.plus/sensors/magic"
                                binaryMessenger:[registrar messenger]];
  [magicChannel setStreamHandler:magicStreamHandler];
}

@end

const double GRAVITY = 9.8;
CMMotionManager* _motionManager;

void _initMotionManager() {
  if (!_motionManager) {
    _motionManager = [[CMMotionManager alloc] init];

    //if (([CMMotionManager availableAttitudeReferenceFrames] & CMAttitudeReferenceFrameXTrueNorthZVertical) != 0) {
	//
    //}
  }
}

static void sendTriplet(Float64 x, Float64 y, Float64 z, FlutterEventSink sink) {
  NSMutableData* event = [NSMutableData dataWithCapacity:3 * sizeof(Float64)];
  [event appendBytes:&x length:sizeof(Float64)];
  [event appendBytes:&y length:sizeof(Float64)];
  [event appendBytes:&z length:sizeof(Float64)];
  sink([FlutterStandardTypedData typedDataWithFloat64:event]);
}

@implementation FLTAccelerometerStreamHandlerPlus

- (FlutterError*)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)eventSink {
  _initMotionManager();
  [_motionManager
      startAccelerometerUpdatesToQueue:[[NSOperationQueue alloc] init]
                           withHandler:^(CMAccelerometerData* accelerometerData, NSError* error) {
                             CMAcceleration acceleration = accelerometerData.acceleration;
                             // Multiply by gravity, and adjust sign values to
                             // align with Android.
                             sendTriplet(-acceleration.x * GRAVITY, -acceleration.y * GRAVITY,
                                         -acceleration.z * GRAVITY, eventSink);
                           }];
  return nil;
}

- (FlutterError*)onCancelWithArguments:(id)arguments {
  [_motionManager stopAccelerometerUpdates];
  return nil;
}

@end

@implementation FLTUserAccelStreamHandlerPlus

- (FlutterError*)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)eventSink {
  _initMotionManager();
  [_motionManager
      startDeviceMotionUpdatesToQueue:[[NSOperationQueue alloc] init]
                          withHandler:^(CMDeviceMotion* data, NSError* error) {
                            CMAcceleration acceleration = data.userAcceleration;
                            // Multiply by gravity, and adjust sign values to align with Android.
                            sendTriplet(-acceleration.x * GRAVITY, -acceleration.y * GRAVITY,
                                        -acceleration.z * GRAVITY, eventSink);
                          }];
  return nil;
}

- (FlutterError*)onCancelWithArguments:(id)arguments {
  [_motionManager stopDeviceMotionUpdates];
  return nil;
}

@end

@implementation FLTGyroscopeStreamHandlerPlus

- (FlutterError*)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)eventSink {
  _initMotionManager();
  [_motionManager
      startGyroUpdatesToQueue:[[NSOperationQueue alloc] init]
                  withHandler:^(CMGyroData* gyroData, NSError* error) {
                    CMRotationRate rotationRate = gyroData.rotationRate;
                    sendTriplet(rotationRate.x, rotationRate.y, rotationRate.z, eventSink);
                  }];
  return nil;
}

- (FlutterError*)onCancelWithArguments:(id)arguments {
  [_motionManager stopGyroUpdates];
  return nil;
}

@end

@implementation FLTMagnetometerStreamHandlerPlus

- (FlutterError*)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)eventSink {
  _initMotionManager();
  [_motionManager startMagnetometerUpdatesToQueue:[[NSOperationQueue alloc] init]
                                      withHandler:^(CMMagnetometerData* magData, NSError* error) {
                                        CMMagneticField magneticField = magData.magneticField;
                                        sendTriplet(magneticField.x, magneticField.y,
                                                    magneticField.z, eventSink);
                                      }];
  return nil;
}

- (FlutterError*)onCancelWithArguments:(id)arguments {
  [_motionManager stopMagnetometerUpdates];
  return nil;
}

@end

	// motionManager.AccelerometerUpdateInterval = 0.01; // 100Hz

@implementation FLTMagicStreamHandlerPlus

- (FlutterError*)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)eventSink {
  _initMotionManager();
  [_motionManager startDeviceMotionUpdatesUsingReferenceFrame: CMAttitudeReferenceFrameXTrueNorthZVertical
                                                      toQueue: [[NSOperationQueue alloc] init]
                                      		  withHandler:^(CMDeviceMotion* motion, NSError* error) {

	 				//CMRotationRate AA = motion.rotationRate;
	 				//CMAcceleration BB = motion.gravity;
	 				//CMAcceleration CC = motion.userAcceleration;

	 				CMAttitude *DD = motion.attitude;
					//CMAttitude *attitude = motion.attitude;
        				//CMRotationMatrix rm = attitude.rotationMatrix;

//Describes a reference frame in which the Z axis is vertical and the X axis points toward true north. Note that using this reference frame may require device movement to calibrate the magnetometer. It also requires the location to be available in order to calculate the difference between magnetic and true north
                                        // CMMagneticField magneticField = magData.magneticField;
// a device's original orientation is lying flat on a table, with the bottom of the device facing the user:
//Change:	Rotation Around:	Caused By:
//+Yaw	Z	The device is rotated counter-clockwise without lifting any edges.
//+Pitch	X	The device is rotated towards its bottom.
//+Roll	Y	The device is rotated towards its right side.

                                        sendTriplet(DD.pitch, DD.roll, DD.yaw, eventSink);

                                      }];

  //[_motionManager startMagnetometerUpdatesToQueue:[[NSOperationQueue alloc] init]
  //                                    withHandler:^(CMMagnetometerData* magData, NSError* error) {
  //                                     CMMagneticField magneticField = magData.magneticField;
  //                                      sendTriplet(magneticField.x, magneticField.y,
  //                                                  magneticField.z, eventSink);
  return nil;
}

- (FlutterError*)onCancelWithArguments:(id)arguments {
  [_motionManager stopDeviceMotionUpdates];
  return nil;
}

@end
