import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceInfoService {
  static final DeviceInfoService _instance = DeviceInfoService._internal();
  factory DeviceInfoService() => _instance;
  DeviceInfoService._internal();

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  String? _deviceId;
  String? _manufacturer;
  String? _model;
  String? _deviceName;
  bool? _isPhysicalDevice;

  // Initialize and get device info
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    // Get device information based on platform
    if (kIsWeb) {
      await _getWebInfo(prefs);
    } else if (Platform.isAndroid) {
      await _getAndroidInfo();
    } else if (Platform.isIOS) {
      await _getIosInfo();
    }
    
    // Save device info to SharedPreferences for background tasks
    await prefs.setString('device_id', _deviceId ?? 'unknown');
    await prefs.setString('device_manufacturer', _manufacturer ?? 'Unknown');
    await prefs.setString('device_model', _model ?? 'Unknown');
    await prefs.setString('device_name', _deviceName ?? 'Unknown Device');
    await prefs.setBool('is_physical_device', _isPhysicalDevice ?? true);
  }

  Future<void> _getAndroidInfo() async {
    try {
      final androidInfo = await _deviceInfo.androidInfo;
      
      // Use Android ID as the unique device identifier
      _deviceId = androidInfo.id; // This is the Android ID (unique per device)
      
      _manufacturer = androidInfo.manufacturer;
      _model = androidInfo.model;
      _deviceName = '${androidInfo.manufacturer} ${androidInfo.model}';
      _isPhysicalDevice = androidInfo.isPhysicalDevice;
      
      debugPrint('Android Device Info:');
      debugPrint('Device ID (Android ID): $_deviceId');
      debugPrint('Manufacturer: $_manufacturer');
      debugPrint('Model: $_model');
      debugPrint('Device Name: $_deviceName');
      debugPrint('Is Physical Device: $_isPhysicalDevice');
      debugPrint('Board: ${androidInfo.board}');
      debugPrint('Brand: ${androidInfo.brand}');
      debugPrint('Hardware: ${androidInfo.hardware}');
    } catch (e) {
      debugPrint('Error getting Android device info: $e');
      _setDefaultValues('Android');
    }
  }

  Future<void> _getIosInfo() async {
    try {
      final iosInfo = await _deviceInfo.iosInfo;
      
      // Use identifierForVendor as the unique device identifier
      // This is unique for each device-app combination
      _deviceId = iosInfo.identifierForVendor ?? 'unknown';
      
      _manufacturer = 'Apple';
      _model = iosInfo.utsname.machine; // e.g., "iPhone14,2"
      _deviceName = iosInfo.name; // e.g., "John's iPhone"
      _isPhysicalDevice = iosInfo.isPhysicalDevice;
      
      debugPrint('iOS Device Info:');
      debugPrint('Device ID (Vendor ID): $_deviceId');
      debugPrint('Manufacturer: $_manufacturer');
      debugPrint('Model: $_model');
      debugPrint('Device Name: $_deviceName');
      debugPrint('System Name: ${iosInfo.systemName}');
      debugPrint('System Version: ${iosInfo.systemVersion}');
      debugPrint('Is Physical Device: $_isPhysicalDevice');
    } catch (e) {
      debugPrint('Error getting iOS device info: $e');
      _setDefaultValues('iOS');
    }
  }

  Future<void> _getWebInfo(SharedPreferences prefs) async {
    try {
      final webInfo = await _deviceInfo.webBrowserInfo;
      
      // For web, generate a persistent ID and store it
      _deviceId = prefs.getString('web_device_id');
      if (_deviceId == null) {
        // Create a pseudo-unique ID based on browser fingerprint
        _deviceId = '${webInfo.vendor}_${webInfo.userAgent?.hashCode}'.replaceAll(' ', '_');
        await prefs.setString('web_device_id', _deviceId!);
      }
      
      _manufacturer = webInfo.vendor ?? 'Web';
      _model = webInfo.browserName.toString();
      _deviceName = '${webInfo.browserName} on ${webInfo.platform}';
      _isPhysicalDevice = true;
      
      debugPrint('Web Device Info:');
      debugPrint('Device ID: $_deviceId');
      debugPrint('Manufacturer: $_manufacturer');
      debugPrint('Model: $_model');
      debugPrint('Device Name: $_deviceName');
      debugPrint('User Agent: ${webInfo.userAgent}');
    } catch (e) {
      debugPrint('Error getting Web device info: $e');
      _setDefaultValues('Web');
    }
  }

  void _setDefaultValues(String platform) {
    _deviceId = 'unknown';
    _manufacturer = platform;
    _model = 'Unknown';
    _deviceName = '$platform Device';
    _isPhysicalDevice = true;
  }

  // Getters
  String get deviceId => _deviceId ?? 'unknown';
  String get manufacturer => _manufacturer ?? 'Unknown';
  String get model => _model ?? 'Unknown';
  String get deviceName => _deviceName ?? 'Unknown Device';
  bool get isPhysicalDevice => _isPhysicalDevice ?? true;

  // Get device info as Map for API calls
  Map<String, dynamic> getDeviceInfoMap() {
    return {
      'device_id': deviceId,
      'manufacturer': manufacturer,
      'model': model,
      'device_name': deviceName,
      'is_physical_device': isPhysicalDevice,
    };
  }
}