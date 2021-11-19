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

static void sendMat(GLKMatrix4 m, FlutterEventSink sink) {
  NSMutableData* event = [NSMutableData dataWithCapacity:16 * sizeof(float)];
  [event appendBytes:&m.m00 length:sizeof(float)];
  [event appendBytes:&m.m01 length:sizeof(float)];
  [event appendBytes:&m.m02 length:sizeof(float)];
  [event appendBytes:&m.m03 length:sizeof(float)];
  [event appendBytes:&m.m10 length:sizeof(float)];
  [event appendBytes:&m.m11 length:sizeof(float)];
  [event appendBytes:&m.m12 length:sizeof(float)];
  [event appendBytes:&m.m13 length:sizeof(float)];
  [event appendBytes:&m.m20 length:sizeof(float)];
  [event appendBytes:&m.m21 length:sizeof(float)];
  [event appendBytes:&m.m22 length:sizeof(float)];
  [event appendBytes:&m.m23 length:sizeof(float)];
  [event appendBytes:&m.m30 length:sizeof(float)];
  [event appendBytes:&m.m31 length:sizeof(float)];
  [event appendBytes:&m.m32 length:sizeof(float)];
  [event appendBytes:&m.m33 length:sizeof(float)];
  sink([FlutterStandardTypedData typedDataWithFloat32:event]);
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

					  if (error) {

					  } else {
// https://math.stackexchange.com/questions/1637464/find-unit-vector-given-roll-pitch-and-yaw
						float aspect = fabsf(self.view.bounds.size.width / self.view.bounds.size.height);
						GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(45.0f), aspect, 0.1f, 100.0f);

						CMRotationMatrix r = self.motionManager.deviceMotion.attitude.rotationMatrix;
						float elevation = fabsf(self.motionManager.deviceMotion.attitude.roll);

						GLKMatrix4 camFromIMU = GLKMatrix4Make(r.m11, r.m12, r.m13, 0,
										       r.m21, r.m22, r.m23, 0,
										       r.m31, r.m32, r.m33, 0,
										       0,     0,     0,     1);

						GLKMatrix4 viewFromCam = GLKMatrix4Translate(GLKMatrix4Identity, 0, 0, 0);
						GLKMatrix4 imuFromModel = GLKMatrix4Identity;
						GLKMatrix4 viewModel = GLKMatrix4Multiply(imuFromModel, GLKMatrix4Multiply(camFromIMU, viewFromCam));
						bool isInvertible;
						GLKMatrix4 modelView = GLKMatrix4Invert(viewModel, &isInvertible);

						int viewport[4];
						viewport[0] = 0.0f;
						viewport[1] = 0.0f;
						viewport[2] = self.view.frame.size.width;
						viewport[3] = self.view.frame.size.height;

						bool success;

						//
						// assume center of the view
						//
						GLKVector3 vector3 = GLKVector3Make(self.view.frame.size.width/2, self.view.frame.size.height/2, 1.0);     
						GLKVector3 calculatedPoint = GLKMathUnproject(vector3, modelView, projectionMatrix, viewport, &success);

						if(success) {
						    //
						    // CMAttitudeReferenceFrameXTrueNorthZVertical always point x to true north
						    // with that, -y become east in 3D world
						    //
						    float angleInRadian = atan2f(-calculatedPoint.y, calculatedPoint.x);
						    camFromIMU.m32 = angleInRadian;
						    camFromIMU.m33 = elevation;
					  	}
						sendMat(camFromIMU, eventSink);
//
//Describes a reference frame in which the Z axis is vertical 
//and the X axis points toward true north. 
//Note that using this reference frame may require device movement 
//to calibrate the magnetometer. It also requires the location to be 
//available in order to calculate the difference between magnetic and true north
// 
// a device's original orientation is lying flat on a table, with the bottom of the device facing the user:
//Change:	Rotation Around:	Caused By:
//+Yaw	Z	The device is rotated counter-clockwise without lifting any edges.
//+Pitch	X	The device is rotated towards its bottom.
//+Roll	Y	The device is rotated towards its right side.
                                      }];

  return nil;
}

- (FlutterError*)onCancelWithArguments:(id)arguments {
  [_motionManager stopDeviceMotionUpdates];
  return nil;
}

@end
