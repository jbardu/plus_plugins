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
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BinaryMessenger;
import org.json.JSONArray;
import org.json.JSONException;
import io.flutter.plugin.common.JSONMethodCodec;

// new StreamHandlerImpl( (SensorManager) context.getSystemService(Context.SENSOR_SERVICE), Sensor.TYPE_MAGNETIC_FIELD);

// 
// Alternate stream handler that munges
// two sensors together to get rotation materix
//
class StreamHandlerImpl2 implements EventChannel.StreamHandler {
  private SensorEventListener sensorEventListener;
  private SensorEventListener listener1;
  private final SensorManager sensorManager;
//  private final Sensor sensor;
  private final Sensor accelerometer;
  private final Sensor magneticfield;
  private final float[] rotationMatrix = new float[9];
  private final float[] accelerometerReading = new float[3];
  private final float[] magnetometerReading = new float[3];
  private int failure = 0;
  private int _typ = 0;
  private float _gyro = 0.5f;
  private float _accel = 0.5f;
  private float accexp1 = 0.98f;
  private float magexp1 = 0.9f;

  StreamHandlerImpl2(SensorManager sensorManager, int sensorType) {
    this.sensorManager = sensorManager;

    //sensor = sensorManager.getDefaultSensor(sensorType);
    accelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER);
    //accelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_GRAVITY);
    magneticfield = sensorManager.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD);
    //magneticfield = sensorManager.getDefaultSensor(Sensor.TYPE_GRAVITY);
    //if (sensor == null) {
	// Log.d("myTag", "Failed to start rotation sensors");
	// failure = 1;
    //}
    if (accelerometer == null) {
	 Log.d("myTag", "Failed to find accel sensor");
	 failure = 2;
    }
    if (magneticfield == null) {
	 Log.d("myTag", "Failed to find magfield sensor");
	 failure = 3;
    }
  }

  @Override
  public void onListen(Object arguments, EventChannel.EventSink events) {
    //sensorEventListener = createSensorEventListener(events);
    //sensorManager.registerListener(sensorEventListener, sensor, sensorManager.SENSOR_DELAY_GAME);
 
    listener1 = createOther(events);
    sensorManager.registerListener(listener1, accelerometer, sensorManager.SENSOR_DELAY_GAME);
    sensorManager.registerListener(listener1, magneticfield, sensorManager.SENSOR_DELAY_GAME);

    if (failure > 0) {
        double[] t = new double[9];
        for (int i = 0; i < 9; i++) {
		t[i] = -1.0;
	}
	t[8] = failure;
	Log.d("myTag", "signal failure mode");
    	events.success(t);
    }

  }

  public void setSmoothing(int typ, double gyro, double accel) {
	_typ = typ;
	_gyro = (float)gyro;
	_accel = (float)accel; 	   // 0 .. 0.5 .. 1

	if (_accel >= 0.5) {
		accexp1 = 0.980f + (0.015f*(_accel-0.5f))*2.0f;
	} else {
		accexp1 = 0.980f * (_accel/0.5f);
	}
	if (_gyro >= 0.5) {
		magexp1 = 0.9f + (0.09f*(_gyro-0.5f))*2.0f;
	} else {
		magexp1 = 0.9f * (_gyro/0.5f);
	}
  }

  @Override
  public void onCancel(Object arguments) {
    //sensorManager.unregisterListener(sensorEventListener);
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
	  float exp2 = 1.0f - accexp1;

	  accelerometerReading[0] = accelerometerReading[0] * accexp1 + event.values[0] * exp2;
	  accelerometerReading[1] = accelerometerReading[1] * accexp1 + event.values[1] * exp2;
	  accelerometerReading[2] = accelerometerReading[2] * accexp1 + event.values[2] * exp2;

          //System.arraycopy(event.values, 0, accelerometerReading, 0, accelerometerReading.length);
	  //Log.d("myTag", String.format("acc %f,%f,%f", event.values[0], event.values[1], event.values[2]));
	  //Log.d("myTag", String.format("acc %f", accelerometerReading[0]));
        //} else if (event.sensor.getType() == Sensor.TYPE_GRAVITY) {

        } else if (event.sensor.getType() == Sensor.TYPE_MAGNETIC_FIELD) {
	  float exp2 = 1.0f - magexp1;

	  magnetometerReading[0] = magnetometerReading[0] * magexp1 + event.values[0] * exp2;
	  magnetometerReading[1] = magnetometerReading[1] * magexp1 + event.values[1] * exp2;
	  magnetometerReading[2] = magnetometerReading[2] * magexp1 + event.values[2] * exp2;

	  //Log.d("myTag", String.format("mag %f,%f,%f", magnetometerReading[0], event.values[1], event.values[2]));
          //System.arraycopy(event.values, 0, magnetometerReading, 0, magnetometerReading.length);
        }

        SensorManager.getRotationMatrix(rotationMatrix, null, accelerometerReading, magnetometerReading);
        double[] sensorValues = new double[rotationMatrix.length];
        for (int i = 0; i < rotationMatrix.length; i++) {
          sensorValues[i] = rotationMatrix[i];
        }
        events.success(sensorValues);

      }
    };
  };

  SensorEventListener createSensorEventListener(final EventChannel.EventSink events) {

    return new SensorEventListener() {
      @Override
      public void onAccuracyChanged(Sensor sensor, int accuracy) {}

      @Override
      public void onSensorChanged(SensorEvent event) {
      }
    };

  }
}

/** SensorsPlugin */
public class SensorsPlugin implements FlutterPlugin, MethodCallHandler {
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
  private StreamHandlerImpl2 magicStreamHandler;

  private MethodChannel methodChannel;
  private int typ = 0;
  private float accel = 0.5f;
  private float gyro = 0.5f;

  @Override
  public void onAttachedToEngine(FlutterPluginBinding binding) {
    onAttachedToEngine(binding.getApplicationContext(), binding.getBinaryMessenger());

    final Context context = binding.getApplicationContext();
    setupEventChannels(context, binding.getBinaryMessenger());
  }

  private void onAttachedToEngine(Context applicationContext, BinaryMessenger messenger) {
    //this.applicationContext = applicationContext;
    methodChannel = new MethodChannel(messenger, "plugins.flutter.io/magic");
    methodChannel.setMethodCallHandler(this);
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    teardownEventChannels();

    methodChannel.setMethodCallHandler(null);
    methodChannel = null;
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    if (call.method.equals("smoothing")) {
      final int typ = call.argument("type");
      final double accel = call.argument("accel");
      final double gyro = call.argument("gyro");
      magicStreamHandler.setSmoothing(typ, accel, gyro);
      Log.d("myTag", "onMethod");
      result.success("ok");
    } else {
      result.notImplemented();
    }
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

    magicChannel = new EventChannel(messenger, MAGIC_CHANNEL_NAME);
    magicStreamHandler =
	new StreamHandlerImpl2(
	    (SensorManager) context.getSystemService(Context.SENSOR_SERVICE),
	    Sensor.TYPE_GEOMAGNETIC_ROTATION_VECTOR);
    magicChannel.setStreamHandler(magicStreamHandler);
  }

  private void teardownEventChannels() {
    accelerometerChannel.setStreamHandler(null);
    userAccelChannel.setStreamHandler(null);
    gyroscopeChannel.setStreamHandler(null);
    magnetometerChannel.setStreamHandler(null);
    magicChannel.setStreamHandler(null);
  }
}

