// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "FLTSensorsPlusPlugin.h"
#import <CoreMotion/CoreMotion.h>
#import <GLKit/GLKit.h>

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

    _motionManager.deviceMotionUpdateInterval = 0.05;
    _motionManager.showsDeviceMovementDisplay = YES;

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

//
// motionManager.AccelerometerUpdateInterval = 0.01; // 100Hz
//
// Describes a reference frame in which the Z axis is vertical 
// and the X axis points toward true north. 
//  Note that using this reference frame may require device movement 
//  to calibrate the magnetometer. It also requires the location to be 
//  available in order to calculate the difference between magnetic and true north
// 
// a device's original orientation is lying flat on a table, with the bottom of the device facing the user:
// 
// Change:	Rotation Around:	Caused By:
// +Yaw	Z	The device is rotated counter-clockwise without lifting any edges.
// +Pitch	X	The device is rotated towards its bottom.
// +Roll	Y	The device is rotated towards its right side.
// 
// Z axis is vertical
// X axis points true north
//
@implementation FLTMagicStreamHandlerPlus

- (FlutterError*)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)eventSink {

  //CMMotionManager* _motionManager = [[CMMotionManager alloc] init];

  _initMotionManager();

	// motion.startDeviceMotionUpdates(using: .xMagneticNorthZVertical)

  [_motionManager startDeviceMotionUpdatesUsingReferenceFrame: CMAttitudeReferenceFrameXTrueNorthZVertical
                                                      toQueue: [[NSOperationQueue alloc] init]
                                      		  withHandler:^(CMDeviceMotion* motion, NSError* error) {

					  if (0) {
					  if (error) {

					  } else {
						// float aspect = 1/1.7777; // fabsf(self.view.bounds.size.width / self.view.bounds.size.height);
						float aspect = 1.0;
						// 
						// angle of vertical viewing area 				(45 degrees)
						// aspect ratio between horizontal and vertical view area
						// near clipping distance
						// far clipping distance   (0.1 .. 100.0)
						//
						//   45.0 degress vertical FOV 
						//
						GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(45.0f), aspect, 1.0f, 100.0f);

						CMRotationMatrix r = motion.attitude.rotationMatrix;

						GLKMatrix4 camFromIMU = GLKMatrix4Multiply(
										GLKMatrix4Make(r.m11, r.m12, r.m13, 0,
											       r.m21, r.m22, r.m23, 0,
											       r.m31, r.m32, r.m33, 0,
											       0,     0,     0,     1), GLKMatrix4MakeYRotation(1.5708));

						// Translate the camera from the center of the device (do not, in this case)
						GLKMatrix4 viewFromCam = GLKMatrix4Translate(GLKMatrix4Identity, 0, 0, 0);

						GLKMatrix4 imuFromModel = GLKMatrix4Identity;
						GLKMatrix4 viewModel = GLKMatrix4Multiply(imuFromModel, GLKMatrix4Multiply(camFromIMU, viewFromCam));

						bool isInvertible;
						bool success[4];
						bool success1 = true;

						GLKMatrix4 modelView = GLKMatrix4Invert(viewModel, &isInvertible);
						if (!isInvertible) {
							success1 = false;
						}


						// Define total screen size
						int viewport[4];
						viewport[0] = 0;	// bottom left
						viewport[1] = 0;
						viewport[2] = 500; 	// self.view.frame.size.width;
						viewport[3] = 500; 	// self.view.frame.size.height;

						GLKVector3 window_coord = GLKVector3Make(250, 250, 1.0);	// far
						GLKVector3 window_coord1 = GLKVector3Make(250, 250, 0.0);	// near
						// 
						GLKVector3 calculatedPoint = GLKMathUnproject(window_coord, modelView, projectionMatrix, viewport, &success[0]);
						GLKVector3 calculatedPoint1 = GLKMathUnproject(window_coord1, modelView, projectionMatrix, viewport, &success[1]);
					        calculatedPoint = GLKVector3Subtract(calculatedPoint, calculatedPoint1);

						window_coord = GLKVector3Make(100, 250, 1.0);	// far
						window_coord1 = GLKVector3Make(100, 250, 0.0);	// near

						GLKVector3 calculatedPoint2 = GLKMathUnproject(window_coord, modelView, projectionMatrix, viewport, &success[2]);
						GLKVector3 calculatedPoint3 = GLKMathUnproject(window_coord1, modelView, projectionMatrix, viewport, &success[3]);
					        calculatedPoint2 = GLKVector3Subtract(calculatedPoint2, calculatedPoint3);

						if(success1) {
						    //
						    // CMAttitudeReferenceFrameXTrueNorthZVertical always point x to true north
						    // with that, -y become east in 3D world
						    //
						    float angleInRadian = atan2f(-calculatedPoint.y, calculatedPoint.x);
						    //
						    // unit vector result in cube 200x200x200
						    //
						    camFromIMU.m00 = calculatedPoint.x;
						    camFromIMU.m01 = calculatedPoint.y;
						    camFromIMU.m02 = calculatedPoint.z;

						    camFromIMU.m10 = calculatedPoint2.x;
						    camFromIMU.m11 = calculatedPoint2.y;
						    camFromIMU.m12 = calculatedPoint2.z;

						    camFromIMU.m30 = angleInRadian;		// reliable elevation above horizon
						    camFromIMU.m31 = motion.attitude.roll;	// motion.roll value

						    camFromIMU.m31 = motion.attitude.roll;	// motion.roll value
					  	}
						sendMat(camFromIMU, eventSink);
					   }
					}
					  if (error) {
					  } else {
	        			CMMagneticField vec3 = motion.magneticField.field;
					float roll = motion.attitude.roll;

					CMRotationMatrix r = motion.attitude.rotationMatrix; // 0x0 is r.m11
					GLKMatrix4 ans = GLKMatrix4Make(r.m11, r.m12, r.m13, 0,
						       			r.m21, r.m22, r.m23, 0,
								        r.m31, r.m32, r.m33, 0,
								        vec3.x,vec3.y,vec3.y, roll);
					sendMat(ans, eventSink);
					  }
                                      }];

  return nil;
}

- (FlutterError*)onCancelWithArguments:(id)arguments {
  [_motionManager stopDeviceMotionUpdates];
  return nil;
}

@end
