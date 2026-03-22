import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_client/meshcore_client.dart';

/// Cayenne LPP (Low Power Payload) data parser
/// Used for decoding telemetry sensor data from MeshCore devices
class CayenneLppParser {
  static const int _selfTelemetryChannel = 1;
  static const int _lppGenericSensor = 100;
  static const int _lppCurrent = 117;
  static const int _lppFrequency = 118;
  static const int _lppPercentage = 120;
  static const int _lppAltitude = 121;
  static const int _lppConcentration = 125;
  static const int _lppPower = 128;
  static const int _lppSpeed = 129;
  static const int _lppDistance = 130;
  static const int _lppEnergy = 131;
  static const int _lppDirection = 132;
  static const int _lppUnixTime = 133;
  static const int _lppColour = 135;
  static const int _lppGust = 137;
  static const int _lppDewPoint = 138;
  static const int _lppRain = 139;
  static const int _lppSwitch = 142;
  static const int _lppBinaryBool = 143;
  static const int _lppBinaryPowerSwitch = 144;
  static const int _lppBinaryOpen = 145;
  static const int _lppBinaryBatteryLow = 146;
  static const int _lppBinaryCharging = 147;
  static const int _lppBinaryCarbonMonoxide = 148;
  static const int _lppBinaryCold = 149;
  static const int _lppBinaryConnectivity = 150;
  static const int _lppBinaryDoor = 151;
  static const int _lppBinaryGarageDoor = 152;
  static const int _lppBinaryGas = 153;
  static const int _lppBinaryHeat = 154;
  static const int _lppBinaryLight = 155;
  static const int _lppBinaryLock = 156;
  static const int _lppBinaryMoisture = 157;
  static const int _lppBinaryMotion = 158;
  static const int _lppBinaryMoving = 159;
  static const int _lppBinaryOccupancy = 160;
  static const int _lppBinaryPlug = 161;
  static const int _lppBinaryPresence = 162;
  static const int _lppBinaryProblem = 163;
  static const int _lppBinaryRunning = 164;
  static const int _lppBinarySafety = 165;
  static const int _lppBinarySmoke = 166;
  static const int _lppBinarySound = 167;
  static const int _lppBinaryTamper = 168;
  static const int _lppBinaryVibration = 169;
  static const int _lppBinaryWindow = 170;
  static const int _lppButtonEvent = 171;
  static const int _lppDimmer = 172;
  static const int _lppUv = 173;
  static const int _lppLightLevel = 174;
  static const int _lppPm25 = 175;
  static const int _lppPm10 = 176;
  static const int _lppCo2 = 177;
  static const int _lppTvoc = 178;
  static const int _lppRpm = 179;
  static const int _lppConductivity = 180;
  static const int _lppRotation = 181;
  static const int _lppDuration = 182;
  static const int _lppAcceleration = 183;
  static const int _lppGyroRate = 184;
  static const int _lppVolume = 185;
  static const int _lppFlowRate = 186;
  static const int _lppVolumeStorage = 187;
  static const int _lppWater = 188;
  static const int _lppGasVolume = 189;
  static const int _lppMass = 190;
  static const int _lppSignedSpeed = 191;
  static const int _lppSignedPower = 192;
  static const int _lppSignedCurrent = 193;

  /// Parse Cayenne LPP data into ContactTelemetry
  static ContactTelemetry parse(Uint8List data) {
    debugPrint('  [CayenneLPP] Parsing LPP data...');
    debugPrint('    Data length: ${data.length} bytes');
    debugPrint(
      '    Data (hex): ${data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}',
    );

    final reader = BufferReader(data);

    LatLng? gpsLocation;
    double? batteryPercentage;
    double? batteryMilliVolts;
    double? deferredBatteryMilliVolts;
    double? deferredBatteryPercentage;
    double? temperature;
    double? humidity;
    double? pressure;
    final extraSensorData = <String, dynamic>{};
    bool sawNonSelfChannel = false;

    int fieldCount = 0;
    while (reader.hasRemaining) {
      if (fieldCount > 0 &&
          _isZeroPaddedTail(data, reader.remainingBytesCount)) {
        debugPrint(
          '    Detected zero-padded telemetry tail, stopping parse at position '
          '${data.length - reader.remainingBytesCount}',
        );
        break;
      }

      try {
        fieldCount++;
        debugPrint(
          '    [Field $fieldCount] Position: ${data.length - reader.remainingBytesCount}',
        );

        final channel = reader.readByte();
        debugPrint('      Channel: $channel');
        if (channel != _selfTelemetryChannel) {
          sawNonSelfChannel = true;
        }

        final type = reader.readByte();
        debugPrint(
          '      Type: $type (0x${type.toRadixString(16).padLeft(2, '0')})',
        );

        switch (type) {
          case MeshCoreConstants.lppDigitalInput:
            final value = reader.readByte();
            debugPrint('      Digital Input: $value');
            extraSensorData['digital_input_$channel'] = value;
            break;

          case MeshCoreConstants.lppDigitalOutput:
            final value = reader.readByte();
            debugPrint('      Digital Output: $value');
            extraSensorData['digital_output_$channel'] = value;
            break;

          case MeshCoreConstants.lppAnalogInput:
            final rawValue = reader.readInt16BE();
            final value = rawValue / 100.0;
            debugPrint('      Analog Input (raw): $rawValue');
            debugPrint('      Analog Input (volts): ${value}V');
            if (_isDedicatedBatteryChannel(channel)) {
              batteryMilliVolts = value * 1000;
              batteryPercentage = _calculateBatteryPercentage(value);
              extraSensorData[_sourceChannelKey('battery')] = channel;
              extraSensorData[_sourceChannelKey('voltage')] = channel;
              debugPrint(
                '      → Battery: ${batteryPercentage.toStringAsFixed(1)}% (${batteryMilliVolts.toStringAsFixed(0)}mV)',
              );
            } else if (_isDeferredBatteryChannel(channel)) {
              deferredBatteryMilliVolts = value * 1000;
              deferredBatteryPercentage = _calculateBatteryPercentage(value);
              extraSensorData['analog_input_$channel'] = value;
            } else {
              extraSensorData['analog_input_$channel'] = value;
            }
            break;

          case MeshCoreConstants.lppAnalogOutput:
            final rawValue = reader.readInt16BE();
            final value = rawValue / 100.0;
            debugPrint('      Analog Output (raw): $rawValue');
            debugPrint('      Analog Output (volts): ${value}V');
            extraSensorData['analog_output_$channel'] = value;
            break;

          case MeshCoreConstants.lppIlluminanceSensor:
            final value = reader.readUInt16BE().toDouble();
            debugPrint('      Illuminance: $value lux');
            extraSensorData['illuminance_$channel'] = value;
            break;

          case MeshCoreConstants.lppPresenceSensor:
            final value = reader.readByte();
            debugPrint('      Presence: $value');
            extraSensorData['presence_$channel'] = value;
            break;

          case MeshCoreConstants.lppTemperatureSensor:
            final rawValue = reader.readInt16BE();
            final value = rawValue / 10.0;
            debugPrint('      Temperature (raw): $rawValue');
            debugPrint('      Temperature: ${value.toStringAsFixed(1)}°C');
            if (channel == _selfTelemetryChannel) {
              temperature = value;
              extraSensorData[_sourceChannelKey('temperature')] = channel;
            } else {
              extraSensorData['temperature_$channel'] = value;
              if (temperature == null) {
                temperature = value;
                extraSensorData[_sourceChannelKey('temperature')] = channel;
              }
            }
            break;

          case MeshCoreConstants.lppHumiditySensor:
            final rawValue = reader.readByte();
            final value = rawValue / 2.0;
            debugPrint('      Humidity (raw): $rawValue');
            debugPrint('      Humidity: ${value.toStringAsFixed(1)}%');
            if (channel == _selfTelemetryChannel) {
              humidity = value;
              extraSensorData[_sourceChannelKey('humidity')] = channel;
            } else {
              extraSensorData['humidity_$channel'] = value;
              if (humidity == null) {
                humidity = value;
                extraSensorData[_sourceChannelKey('humidity')] = channel;
              }
            }
            break;

          case MeshCoreConstants.lppAccelerometer:
            final x = reader.readInt16BE() / 1000.0;
            final y = reader.readInt16BE() / 1000.0;
            final z = reader.readInt16BE() / 1000.0;
            debugPrint('      Accelerometer: x=$x, y=$y, z=$z');
            extraSensorData['accelerometer_$channel'] = {
              'x': x,
              'y': y,
              'z': z,
            };
            break;

          case MeshCoreConstants.lppBarometer:
            final rawValue = reader.readUInt16BE();
            final value = rawValue / 10.0;
            debugPrint('      Barometer (raw): $rawValue');
            debugPrint('      Barometer: ${value.toStringAsFixed(1)} hPa');
            if (channel == _selfTelemetryChannel) {
              pressure = value;
              extraSensorData[_sourceChannelKey('pressure')] = channel;
            } else {
              extraSensorData['pressure_$channel'] = value;
              if (pressure == null) {
                pressure = value;
                extraSensorData[_sourceChannelKey('pressure')] = channel;
              }
            }
            break;

          case MeshCoreConstants.lppVoltageSensor:
            final rawValue = reader.readUInt16BE();
            final value = rawValue / 100.0;
            debugPrint('      Voltage (raw): $rawValue');
            debugPrint('      Voltage: ${value}V');
            if (_isDedicatedBatteryChannel(channel)) {
              batteryMilliVolts = value * 1000;
              batteryPercentage = _calculateBatteryPercentage(value);
              extraSensorData[_sourceChannelKey('battery')] = channel;
              extraSensorData[_sourceChannelKey('voltage')] = channel;
              debugPrint(
                '      → Battery: ${batteryPercentage.toStringAsFixed(1)}% (${batteryMilliVolts.toStringAsFixed(0)}mV)',
              );
            } else if (_isDeferredBatteryChannel(channel)) {
              deferredBatteryMilliVolts = value * 1000;
              deferredBatteryPercentage = _calculateBatteryPercentage(value);
              extraSensorData['voltage_$channel'] = value;
            } else {
              extraSensorData['voltage_$channel'] = value;
            }
            break;

          case MeshCoreConstants.lppGyrometer:
            final x = reader.readInt16BE() / 100.0;
            final y = reader.readInt16BE() / 100.0;
            final z = reader.readInt16BE() / 100.0;
            debugPrint('      Gyrometer: x=$x, y=$y, z=$z');
            extraSensorData['gyrometer_$channel'] = {'x': x, 'y': y, 'z': z};
            break;

          case MeshCoreConstants.lppGps:
            // Standard Cayenne LPP GPS format (type 0x88):
            // - Latitude: 3 bytes, signed 24-bit, big-endian, × 10000
            // - Longitude: 3 bytes, signed 24-bit, big-endian, × 10000
            // - Altitude: 3 bytes, signed 24-bit, big-endian, × 100
            // Total: 9 bytes (not the 12 bytes used in MeshCore advertisements!)

            // Read 3-byte signed big-endian integers
            final latBytes = reader.readBytes(3);
            int rawLat = (latBytes[0] << 16) | (latBytes[1] << 8) | latBytes[2];
            // Sign extend from 24-bit to 32-bit
            if (rawLat > 0x7FFFFF) rawLat = rawLat - 0x1000000;

            final lonBytes = reader.readBytes(3);
            int rawLon = (lonBytes[0] << 16) | (lonBytes[1] << 8) | lonBytes[2];
            if (rawLon > 0x7FFFFF) rawLon = rawLon - 0x1000000;

            final altBytes = reader.readBytes(3);
            int rawAlt = (altBytes[0] << 16) | (altBytes[1] << 8) | altBytes[2];
            if (rawAlt > 0x7FFFFF) rawAlt = rawAlt - 0x1000000;

            // Decode: divide by scaling factors
            final lat = rawLat / 10000.0;
            final lon = rawLon / 10000.0;
            final alt = rawAlt / 100.0;

            debugPrint(
              '      GPS Location (raw 24-bit BE): lat=$rawLat (0x${rawLat.toRadixString(16).padLeft(6, '0')}), lon=$rawLon (0x${rawLon.toRadixString(16).padLeft(6, '0')}), alt=$rawAlt (0x${rawAlt.toRadixString(16).padLeft(6, '0')})',
            );
            debugPrint(
              '      GPS Location (decoded): ${lat.toStringAsFixed(6)}°, ${lon.toStringAsFixed(6)}°, altitude=${alt.toStringAsFixed(2)}m',
            );

            // Validate coordinates are in valid range
            if (lat < -90.0 || lat > 90.0) {
              debugPrint('      ⚠️ WARNING: Latitude out of range: $lat°');
            }
            if (lon < -180.0 || lon > 180.0) {
              debugPrint('      ⚠️ WARNING: Longitude out of range: $lon°');
            }

            gpsLocation = LatLng(lat, lon);
            extraSensorData[_sourceChannelKey('gps')] = channel;
            extraSensorData['altitude_$channel'] = alt;
            break;

          case _lppGenericSensor:
            final value = _readUInt32BE(reader).toDouble();
            debugPrint('      Generic Sensor: $value');
            extraSensorData['generic_sensor_$channel'] = value;
            break;

          case _lppCurrent:
            final rawValue = reader.readInt16BE();
            final value = rawValue / 1000.0;
            debugPrint('      Current (raw): $rawValue');
            debugPrint('      Current: ${value}A');
            extraSensorData['current_$channel'] = value;
            break;

          case _lppFrequency:
            final value = _readUInt32BE(reader).toDouble();
            debugPrint('      Frequency: ${value}Hz');
            extraSensorData['frequency_$channel'] = value;
            break;

          case _lppPercentage:
            final value = reader.readByte().toDouble();
            debugPrint('      Percentage: $value%');
            if (_isDedicatedBatteryChannel(channel) || _isDeferredBatteryChannel(channel)) {
              batteryPercentage = value;
              extraSensorData[_sourceChannelKey('battery')] = channel;
            } else {
              extraSensorData['percentage_$channel'] = value;
            }
            break;

          case _lppAltitude:
            final rawValue = reader.readInt16BE();
            final value = rawValue.toDouble();
            debugPrint('      Altitude: ${value}m');
            extraSensorData['altitude_$channel'] = value;
            break;

          case _lppConcentration:
            final value = reader.readUInt16BE().toDouble();
            debugPrint('      Concentration: ${value}ppm');
            extraSensorData['concentration_$channel'] = value;
            break;

          case _lppPower:
            final value = reader.readUInt16BE().toDouble();
            debugPrint('      Power: ${value}W');
            extraSensorData['power_$channel'] = value;
            break;

          case _lppSpeed:
            final rawValue = reader.readUInt16BE();
            final value = rawValue / 100.0;
            debugPrint('      Speed: ${value}m/s');
            extraSensorData['speed_$channel'] = value;
            break;

          case _lppDistance:
            final rawValue = _readUInt32BE(reader);
            final value = rawValue / 1000.0;
            debugPrint('      Distance: ${value}m');
            extraSensorData['distance_$channel'] = value;
            break;

          case _lppEnergy:
            final rawValue = _readUInt32BE(reader);
            final value = rawValue / 1000.0;
            debugPrint('      Energy: ${value}kWh');
            extraSensorData['energy_$channel'] = value;
            break;

          case _lppDirection:
            final value = reader.readUInt16BE().toDouble();
            debugPrint('      Direction: $value°');
            extraSensorData['direction_$channel'] = value;
            break;

          case _lppUnixTime:
            final value = _readUInt32BE(reader);
            debugPrint('      Unix time: $value');
            extraSensorData['unixtime_$channel'] = value;
            break;

          case _lppColour:
            final red = reader.readByte();
            final green = reader.readByte();
            final blue = reader.readByte();
            debugPrint('      Colour: r=$red, g=$green, b=$blue');
            extraSensorData['colour_$channel'] = {
              'r': red,
              'g': green,
              'b': blue,
            };
            break;

          case _lppGust:
            final rawValue = reader.readUInt16BE();
            final value = rawValue / 100.0;
            debugPrint('      Gust: ${value}m/s');
            extraSensorData['gust_$channel'] = value;
            break;

          case _lppDewPoint:
            final rawValue = reader.readInt16BE();
            final value = rawValue / 10.0;
            debugPrint('      Dew point: ${value.toStringAsFixed(1)}°C');
            extraSensorData['dew_$channel'] = value;
            break;

          case _lppRain:
            final rawValue = reader.readUInt16BE();
            final value = rawValue / 10.0;
            debugPrint('      Rain: ${value}mm');
            extraSensorData['rain_$channel'] = value;
            break;

          case _lppBinaryBool:
          case _lppBinaryPowerSwitch:
          case _lppBinaryOpen:
          case _lppBinaryBatteryLow:
          case _lppBinaryCharging:
          case _lppBinaryCarbonMonoxide:
          case _lppBinaryCold:
          case _lppBinaryConnectivity:
          case _lppBinaryDoor:
          case _lppBinaryGarageDoor:
          case _lppBinaryGas:
          case _lppBinaryHeat:
          case _lppBinaryLight:
          case _lppBinaryLock:
          case _lppBinaryMoisture:
          case _lppBinaryMotion:
          case _lppBinaryMoving:
          case _lppBinaryOccupancy:
          case _lppBinaryPlug:
          case _lppBinaryPresence:
          case _lppBinaryProblem:
          case _lppBinaryRunning:
          case _lppBinarySafety:
          case _lppBinarySmoke:
          case _lppBinarySound:
          case _lppBinaryTamper:
          case _lppBinaryVibration:
          case _lppBinaryWindow:
            final value = reader.readByte();
            debugPrint('      Binary state: $value');
            extraSensorData['${_binaryMetricKeyForType(type)}_$channel'] =
                value;
            break;

          case _lppButtonEvent:
            final value = reader.readByte();
            debugPrint('      Button event: $value');
            extraSensorData['button_event_$channel'] = value;
            break;

          case _lppDimmer:
            final value = _readInt8(reader);
            debugPrint('      Dimmer: $value');
            extraSensorData['dimmer_$channel'] = value;
            break;

          case _lppUv:
            final value = reader.readByte() / 10.0;
            debugPrint('      UV index: $value');
            extraSensorData['uv_$channel'] = value;
            break;

          case _lppLightLevel:
            final value = reader.readByte();
            debugPrint('      Light level: $value');
            extraSensorData['light_level_$channel'] = value;
            break;

          case _lppPm25:
            final value = reader.readUInt16BE().toDouble();
            debugPrint('      PM2.5: $value');
            extraSensorData['pm25_$channel'] = value;
            break;

          case _lppPm10:
            final value = reader.readUInt16BE().toDouble();
            debugPrint('      PM10: $value');
            extraSensorData['pm10_$channel'] = value;
            break;

          case _lppCo2:
            final value = reader.readUInt16BE().toDouble();
            debugPrint('      CO2: $value');
            extraSensorData['co2_$channel'] = value;
            break;

          case _lppTvoc:
            final value = reader.readUInt16BE().toDouble();
            debugPrint('      TVOC: $value');
            extraSensorData['tvoc_$channel'] = value;
            break;

          case _lppRpm:
            final value = reader.readUInt16BE().toDouble();
            debugPrint('      RPM: $value');
            extraSensorData['rpm_$channel'] = value;
            break;

          case _lppConductivity:
            final value = reader.readUInt16BE().toDouble();
            debugPrint('      Conductivity: $value');
            extraSensorData['conductivity_$channel'] = value;
            break;

          case _lppRotation:
            final rawValue = reader.readInt16BE();
            final value = rawValue / 10.0;
            debugPrint('      Rotation: $value');
            extraSensorData['rotation_$channel'] = value;
            break;

          case _lppDuration:
            final rawValue = _readUInt32BE(reader);
            final value = rawValue / 1000.0;
            debugPrint('      Duration: $value s');
            extraSensorData['duration_$channel'] = value;
            break;

          case _lppAcceleration:
            final rawValue = _readInt32BE(reader);
            final value = rawValue / 1000000.0;
            debugPrint('      Acceleration: $value');
            extraSensorData['acceleration_$channel'] = value;
            break;

          case _lppGyroRate:
            final rawValue = _readInt32BE(reader);
            final value = rawValue / 1000.0;
            debugPrint('      Gyro rate: $value');
            extraSensorData['gyro_rate_$channel'] = value;
            break;

          case _lppVolume:
            final rawValue = _readUInt32BE(reader);
            final value = rawValue / 1000.0;
            debugPrint('      Volume: $value');
            extraSensorData['volume_$channel'] = value;
            break;

          case _lppFlowRate:
            final rawValue = _readUInt32BE(reader);
            final value = rawValue / 1000.0;
            debugPrint('      Flow rate: $value');
            extraSensorData['flow_rate_$channel'] = value;
            break;

          case _lppVolumeStorage:
            final rawValue = _readUInt32BE(reader);
            final value = rawValue / 1000.0;
            debugPrint('      Storage volume: $value');
            extraSensorData['volume_storage_$channel'] = value;
            break;

          case _lppWater:
            final rawValue = _readUInt32BE(reader);
            final value = rawValue / 1000.0;
            debugPrint('      Water: $value');
            extraSensorData['water_$channel'] = value;
            break;

          case _lppGasVolume:
            final rawValue = _readUInt32BE(reader);
            final value = rawValue / 1000.0;
            debugPrint('      Gas volume: $value');
            extraSensorData['gas_volume_$channel'] = value;
            break;

          case _lppMass:
            final rawValue = _readUInt32BE(reader);
            final value = rawValue / 1000.0;
            debugPrint('      Mass: $value');
            extraSensorData['mass_$channel'] = value;
            break;

          case _lppSignedSpeed:
            final rawValue = _readInt32BE(reader);
            final value = rawValue / 1000000.0;
            debugPrint('      Signed speed: $value');
            extraSensorData['signed_speed_$channel'] = value;
            break;

          case _lppSignedPower:
            final rawValue = _readInt32BE(reader);
            final value = rawValue / 100.0;
            debugPrint('      Signed power: $value');
            extraSensorData['signed_power_$channel'] = value;
            break;

          case _lppSignedCurrent:
            final rawValue = _readInt32BE(reader);
            final value = rawValue / 1000.0;
            debugPrint('      Signed current: $value');
            extraSensorData['signed_current_$channel'] = value;
            break;

          case _lppSwitch:
            final value = reader.readByte();
            debugPrint('      Switch: $value');
            extraSensorData['switch_$channel'] = value;
            break;

          default:
            final size = _payloadSizeForType(type);
            if (size == null || reader.remainingBytesCount < size) {
              debugPrint(
                '      ⚠️ Unknown type $type with unsupported size, stopping parse',
              );
              reader.skip(reader.remainingBytesCount);
              break;
            }
            debugPrint('      ⚠️ Unknown type $type, skipping $size bytes');
            reader.skip(size);
            break;
        }
      } catch (e) {
        debugPrint('      ❌ Parsing error: $e');
        // If we encounter a parsing error, break and return what we have
        break;
      }
    }

    if (batteryMilliVolts == null &&
        batteryPercentage == null &&
        deferredBatteryMilliVolts != null &&
        deferredBatteryPercentage != null &&
        !sawNonSelfChannel) {
      batteryMilliVolts = deferredBatteryMilliVolts;
      batteryPercentage = deferredBatteryPercentage;
      extraSensorData[_sourceChannelKey('battery')] = _selfTelemetryChannel;
      extraSensorData[_sourceChannelKey('voltage')] = _selfTelemetryChannel;
      debugPrint(
        '    Promoted self-channel voltage to battery: '
        '${batteryPercentage.toStringAsFixed(1)}% (${batteryMilliVolts.toStringAsFixed(0)}mV)',
      );
    }

    debugPrint('    Parsed $fieldCount fields');
    debugPrint('  ✅ [CayenneLPP] Parsing complete');
    debugPrint(
      '    GPS: ${gpsLocation != null ? '${gpsLocation.latitude}°, ${gpsLocation.longitude}°' : 'none'}',
    );
    debugPrint(
      '    Battery: ${batteryPercentage != null ? '${batteryPercentage.toStringAsFixed(1)}%' : 'none'}',
    );
    debugPrint(
      '    Temperature: ${temperature != null ? '${temperature.toStringAsFixed(1)}°C' : 'none'}',
    );

    // IMPORTANT: Cayenne LPP format does NOT include a timestamp field.
    // We use DateTime.now() as the timestamp, which represents when the data
    // was RECEIVED/PARSED by the app, NOT when it was collected by the device.
    //
    // This means:
    // - If the device sends cached/old telemetry data, the timestamp will still
    //   show as "recent" (a few seconds ago) because it was just received
    // - The actual age of the telemetry data cannot be determined from the LPP format
    // - Devices may cache telemetry for hours and send it later when requested
    final parseTimestamp = DateTime.now();
    debugPrint(
      '    Timestamp: $parseTimestamp (parse time, NOT device collection time)',
    );

    return ContactTelemetry(
      gpsLocation: gpsLocation,
      batteryPercentage: batteryPercentage,
      batteryMilliVolts: batteryMilliVolts,
      temperature: temperature,
      humidity: humidity,
      pressure: pressure,
      timestamp: parseTimestamp,
      extraSensorData: extraSensorData.isNotEmpty ? extraSensorData : null,
    );
  }

  /// Calculate battery percentage from voltage (V)
  static double _calculateBatteryPercentage(double voltage) {
    // Standard lithium battery curve: 3.0V = 0%, 4.2V = 100%
    if (voltage <= 3.0) return 0.0;
    if (voltage >= 4.2) return 100.0;
    return ((voltage - 3.0) / 1.2) * 100.0;
  }

  static bool _isDedicatedBatteryChannel(int channel) => channel == 0;

  static bool _isDeferredBatteryChannel(int channel) =>
      channel == _selfTelemetryChannel;

  static int _readUInt32BE(BufferReader reader) {
    final bytes = reader.readBytes(4);
    return (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
  }

  static int _readInt32BE(BufferReader reader) {
    final value = _readUInt32BE(reader);
    if ((value & 0x80000000) != 0) {
      return value - 0x100000000;
    }
    return value;
  }

  static int _readInt8(BufferReader reader) {
    final value = reader.readByte();
    if ((value & 0x80) != 0) {
      return value - 0x100;
    }
    return value;
  }

  static String _sourceChannelKey(String fieldKey) =>
      '__source_channel:$fieldKey';

  static String _binaryMetricKeyForType(int type) {
    switch (type) {
      case _lppBinaryBool:
        return 'binary_bool';
      case _lppBinaryPowerSwitch:
        return 'binary_power_switch';
      case _lppBinaryOpen:
        return 'binary_open';
      case _lppBinaryBatteryLow:
        return 'binary_battery_low';
      case _lppBinaryCharging:
        return 'binary_charging';
      case _lppBinaryCarbonMonoxide:
        return 'binary_carbon_monoxide';
      case _lppBinaryCold:
        return 'binary_cold';
      case _lppBinaryConnectivity:
        return 'binary_connectivity';
      case _lppBinaryDoor:
        return 'binary_door';
      case _lppBinaryGarageDoor:
        return 'binary_garage_door';
      case _lppBinaryGas:
        return 'binary_gas';
      case _lppBinaryHeat:
        return 'binary_heat';
      case _lppBinaryLight:
        return 'binary_light';
      case _lppBinaryLock:
        return 'binary_lock';
      case _lppBinaryMoisture:
        return 'binary_moisture';
      case _lppBinaryMotion:
        return 'binary_motion';
      case _lppBinaryMoving:
        return 'binary_moving';
      case _lppBinaryOccupancy:
        return 'binary_occupancy';
      case _lppBinaryPlug:
        return 'binary_plug';
      case _lppBinaryPresence:
        return 'binary_presence';
      case _lppBinaryProblem:
        return 'binary_problem';
      case _lppBinaryRunning:
        return 'binary_running';
      case _lppBinarySafety:
        return 'binary_safety';
      case _lppBinarySmoke:
        return 'binary_smoke';
      case _lppBinarySound:
        return 'binary_sound';
      case _lppBinaryTamper:
        return 'binary_tamper';
      case _lppBinaryVibration:
        return 'binary_vibration';
      case _lppBinaryWindow:
        return 'binary_window';
    }
    return 'binary_state';
  }

  static int? _payloadSizeForType(int type) {
    if (type >= _lppBinaryBool && type <= _lppBinaryWindow) {
      return 1;
    }
    switch (type) {
      case MeshCoreConstants.lppDigitalInput:
      case MeshCoreConstants.lppDigitalOutput:
      case MeshCoreConstants.lppPresenceSensor:
      case MeshCoreConstants.lppHumiditySensor:
      case _lppPercentage:
      case _lppSwitch:
      case _lppButtonEvent:
      case _lppDimmer:
      case _lppUv:
      case _lppLightLevel:
        return 1;
      case MeshCoreConstants.lppAnalogInput:
      case MeshCoreConstants.lppAnalogOutput:
      case MeshCoreConstants.lppIlluminanceSensor:
      case MeshCoreConstants.lppTemperatureSensor:
      case MeshCoreConstants.lppBarometer:
      case MeshCoreConstants.lppVoltageSensor:
      case _lppCurrent:
      case _lppAltitude:
      case _lppConcentration:
      case _lppPower:
      case _lppSpeed:
      case _lppDirection:
      case _lppGust:
      case _lppDewPoint:
      case _lppRain:
      case _lppPm25:
      case _lppPm10:
      case _lppCo2:
      case _lppTvoc:
      case _lppRpm:
      case _lppConductivity:
      case _lppRotation:
        return 2;
      case MeshCoreConstants.lppAccelerometer:
      case MeshCoreConstants.lppGyrometer:
        return 6;
      case MeshCoreConstants.lppGps:
        return 9;
      case _lppGenericSensor:
      case _lppFrequency:
      case _lppDistance:
      case _lppEnergy:
      case _lppUnixTime:
      case _lppDuration:
      case _lppAcceleration:
      case _lppGyroRate:
      case _lppVolume:
      case _lppFlowRate:
      case _lppVolumeStorage:
      case _lppWater:
      case _lppGasVolume:
      case _lppMass:
      case _lppSignedSpeed:
      case _lppSignedPower:
      case _lppSignedCurrent:
        return 4;
      case _lppColour:
        return 3;
    }
    return null;
  }

  static bool _isZeroPaddedTail(Uint8List data, int remainingBytes) {
    final start = data.length - remainingBytes;
    for (int i = start; i < data.length; i++) {
      if (data[i] != 0) return false;
    }
    return remainingBytes > 0;
  }

  /// Create Cayenne LPP data for GPS location
  /// Standard Cayenne LPP GPS format (type 0x88):
  /// - Latitude: 3 bytes, signed 24-bit, big-endian, × 10000
  /// - Longitude: 3 bytes, signed 24-bit, big-endian, × 10000
  /// - Altitude: 3 bytes, signed 24-bit, big-endian, × 100
  static Uint8List createGpsData({
    required double latitude,
    required double longitude,
    double altitude = 0.0,
    int channel = 0,
  }) {
    final buffer = <int>[];

    buffer.add(channel);
    buffer.add(MeshCoreConstants.lppGps);

    // Latitude (signed 24-bit BE, 3 bytes, 0.0001° precision)
    int lat = (latitude * 10000).round();
    // Handle negative values (two's complement for 24-bit)
    if (lat < 0) lat = lat + 0x1000000;
    buffer.add((lat >> 16) & 0xFF); // Byte 0 (MSB)
    buffer.add((lat >> 8) & 0xFF); // Byte 1
    buffer.add(lat & 0xFF); // Byte 2 (LSB)

    // Longitude (signed 24-bit BE, 3 bytes, 0.0001° precision)
    int lon = (longitude * 10000).round();
    if (lon < 0) lon = lon + 0x1000000;
    buffer.add((lon >> 16) & 0xFF); // Byte 0 (MSB)
    buffer.add((lon >> 8) & 0xFF); // Byte 1
    buffer.add(lon & 0xFF); // Byte 2 (LSB)

    // Altitude (signed 24-bit BE, 3 bytes, 0.01m precision)
    int alt = (altitude * 100).round();
    if (alt < 0) alt = alt + 0x1000000;
    buffer.add((alt >> 16) & 0xFF); // Byte 0 (MSB)
    buffer.add((alt >> 8) & 0xFF); // Byte 1
    buffer.add(alt & 0xFF); // Byte 2 (LSB)

    return Uint8List.fromList(buffer);
  }

  /// Create Cayenne LPP data for temperature
  static Uint8List createTemperatureData(double celsius, {int channel = 0}) {
    final buffer = <int>[];
    buffer.add(channel);
    buffer.add(MeshCoreConstants.lppTemperatureSensor);

    final temp = (celsius * 10).round();
    buffer.add((temp >> 8) & 0xFF);
    buffer.add(temp & 0xFF);

    return Uint8List.fromList(buffer);
  }

  /// Create Cayenne LPP data for battery voltage
  static Uint8List createBatteryData(double voltage, {int channel = 0}) {
    final buffer = <int>[];
    buffer.add(channel);
    buffer.add(MeshCoreConstants.lppAnalogInput);

    final volts = (voltage * 100).round();
    buffer.add((volts >> 8) & 0xFF);
    buffer.add(volts & 0xFF);

    return Uint8List.fromList(buffer);
  }
}
