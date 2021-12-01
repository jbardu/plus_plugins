// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package dev.fluttercommunity.plus.sensors;

import android.content.Context;
import android.hardware.Sensor;
import android.hardware.SensorManager;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import androidx.annotation.NonNull;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import android.util.Log;
import android.os.Build;

// new StreamHandlerImpl( (SensorManager) context.getSystemService(Context.SENSOR_SERVICE), Sensor.TYPE_MAGNETIC_FIELD);

// 
// Alternate stream handler that munges
// two sensors together to get rotation materix
//
class StreamHandlerImpl2 implements EventChannel.StreamHandler {
  private SensorEventListener sensorEventListener;
  private SensorEventListener listener1;
  private final SensorManager sensorManager;
  private final Sensor sensor;
  private final Sensor accelerometer;
  private final Sensor magneticfield;
  private final float[] rotationMatrix = new float[9];
  private final float[] accelerometerReading = new float[3];
  private final float[] magnetometerReading = new float[3];

  StreamHandlerImpl2(SensorManager sensorManager, int sensorType) {
    this.sensorManager = sensorManager;

    sensor = sensorManager.getDefaultSensor(sensorType);
    accelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER);
    magneticfield = sensorManager.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD);
  }

  @Override
  public void onListen(Object arguments, EventChannel.EventSink events) {
    sensorEventListener = createSensorEventListener(events);
    listener1 = createOther(events);

    sensorManager.registerListener(sensorEventListener, sensor, sensorManager.SENSOR_DELAY_GAME);
    sensorManager.registerListener(listener1, accelerometer, sensorManager.SENSOR_DELAY_GAME);
    sensorManager.registerListener(listener1, magneticfield, sensorManager.SENSOR_DELAY_GAME);
  }

  @Override
  public void onCancel(Object arguments) {
    sensorManager.unregisterListener(sensorEventListener);
    sensorManager.unregisterListener(listener1);
  }

  SensorEventListener createOther(final EventChannel.EventSink events) {

    return new SensorEventListener() {
      @Override
      public void onAccuracyChanged(Sensor sensor, int accuracy) {
      }

      @Override
      public void onSensorChanged(SensorEvent event) {
        if (event.sensor.getType() == Sensor.TYPE_ACCELEROMETER) {
	  accelerometerReading[0] = accelerometerReading[0] * 0.9 + event.values[0] * 0.1;
	  accelerometerReading[1] = accelerometerReading[1] * 0.9 + event.values[1] * 0.1;
	  accelerometerReading[2] = accelerometerReading[2] * 0.9 + event.values[2] * 0.1;

          System.arraycopy(event.values, 0, accelerometerReading, 0, accelerometerReading.length);
	  //Log.d("myTag", String.format("acc %f,%f,%f", event.values[0], event.values[1], event.values[2]));
        } else if (event.sensor.getType() == Sensor.TYPE_MAGNETIC_FIELD) {
	  magnetometerReading[0] = magnetometerReading[0] * 0.9 + event.values[0] * 0.1;
	  magnetometerReading[1] = magnetometerReading[1] * 0.9 + event.values[1] * 0.1;
	  magnetometerReading[2] = magnetometerReading[2] * 0.9 + event.values[2] * 0.1;

          System.arraycopy(event.values, 0, magnetometerReading, 0, magnetometerReading.length);
	  ////Log.d("myTag", String.format("mag %f,%f,%f", event.values[0], event.values[1], event.values[2]));
        }
      }
    };
  };

  SensorEventListener createSensorEventListener(final EventChannel.EventSink events) {

    return new SensorEventListener() {
      @Override
      public void onAccuracyChanged(Sensor sensor, int accuracy) {}

      @Override
      public void onSensorChanged(SensorEvent event) {
        SensorManager.getRotationMatrix(rotationMatrix, null, accelerometerReading, magnetometerReading);
        double[] sensorValues = new double[rotationMatrix.length];
	// Should invert the matrix to match IOS here.
        for (int i = 0; i < rotationMatrix.length; i++) {
          sensorValues[i] = rotationMatrix[i];
        } 
        events.success(sensorValues);
      }
    };

  }
}


/** SensorsPlugin */
public class SensorsPlugin implements FlutterPlugin {
  private static final String ACCELEROMETER_CHANNEL_NAME =
      "dev.fluttercommunity.plus/sensors/accelerometer";
  private static final String GYROSCOPE_CHANNEL_NAME =
      "dev.fluttercommunity.plus/sensors/gyroscope";
  private static final String USER_ACCELEROMETER_CHANNEL_NAME =
      "dev.fluttercommunity.plus/sensors/user_accel";
  private static final String MAGNETOMETER_CHANNEL_NAME =
      "dev.fluttercommunity.plus/sensors/magnetometer";
  private static final String MAGIC_CHANNEL_NAME =
      "dev.fluttercommunity.plus/sensors/magic";

  private EventChannel accelerometerChannel;
  private EventChannel userAccelChannel;
  private EventChannel gyroscopeChannel;
  private EventChannel magnetometerChannel;
  private EventChannel magicChannel;

  @Override
  public void onAttachedToEngine(FlutterPluginBinding binding) {
    final Context context = binding.getApplicationContext();
    setupEventChannels(context, binding.getBinaryMessenger());
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    teardownEventChannels();
  }

  private void setupEventChannels(Context context, BinaryMessenger messenger) {
    accelerometerChannel = new EventChannel(messenger, ACCELEROMETER_CHANNEL_NAME);
    final StreamHandlerImpl accelerationStreamHandler =
        new StreamHandlerImpl(
            (SensorManager) context.getSystemService(Context.SENSOR_SERVICE),
            Sensor.TYPE_ACCELEROMETER);
    accelerometerChannel.setStreamHandler(accelerationStreamHandler);

    userAccelChannel = new EventChannel(messenger, USER_ACCELEROMETER_CHANNEL_NAME);
    final StreamHandlerImpl linearAccelerationStreamHandler =
        new StreamHandlerImpl(
            (SensorManager) context.getSystemService(Context.SENSOR_SERVICE),
            Sensor.TYPE_LINEAR_ACCELERATION);
    userAccelChannel.setStreamHandler(linearAccelerationStreamHandler);

    gyroscopeChannel = new EventChannel(messenger, GYROSCOPE_CHANNEL_NAME);
    final StreamHandlerImpl gyroScopeStreamHandler =
        new StreamHandlerImpl(
            (SensorManager) context.getSystemService(Context.SENSOR_SERVICE),
            Sensor.TYPE_GYROSCOPE);
    gyroscopeChannel.setStreamHandler(gyroScopeStreamHandler);

    magnetometerChannel = new EventChannel(messenger, MAGNETOMETER_CHANNEL_NAME);
    final StreamHandlerImpl magnetometerStreamHandler =
        new StreamHandlerImpl( (SensorManager) context.getSystemService(Context.SENSOR_SERVICE), Sensor.TYPE_MAGNETIC_FIELD);
    magnetometerChannel.setStreamHandler(magnetometerStreamHandler);

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
	    magicChannel = new EventChannel(messenger, MAGIC_CHANNEL_NAME);
	    final StreamHandlerImpl2 magicStreamHandler =
		new StreamHandlerImpl2(
		    (SensorManager) context.getSystemService(Context.SENSOR_SERVICE),
		    Sensor.TYPE_GEOMAGNETIC_ROTATION_VECTOR);
	    magicChannel.setStreamHandler(magicStreamHandler);

    } else {
    	   Log.d("myTag", "SDK not KitKat or greater for rotation matrix");
    }
  }

  private void teardownEventChannels() {
    accelerometerChannel.setStreamHandler(null);
    userAccelChannel.setStreamHandler(null);
    gyroscopeChannel.setStreamHandler(null);
    magnetometerChannel.setStreamHandler(null);
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
    	magicChannel.setStreamHandler(null);
    }
  }
}
