// lib/core/services/location_tracking_service.dart
import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Shared constants ─────────────────────────────────────────────────────────
const _kDeviceRegistrationKey = 'device_registration';
const _kLocationLogsKey = 'location_logs';
const _kIsTrackingKey = 'is_tracking_enabled';
const _kSendLocationUrl =
    'http://10.9.75.138:3000/employee-activity/save-device-location';

/// "2026-03-17T10:15:30" — no milliseconds, no Z suffix
String _formatTimestamp(DateTime dt) =>
    DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(dt);

// ─── Foreground task entry point ──────────────────────────────────────────────
// Must be top-level and annotated — this is what Android calls when the
// foreground service starts in a separate isolate.

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(_LocationTaskHandler());
}

// ─── Task handler (runs in background isolate) ────────────────────────────────

class _LocationTaskHandler extends TaskHandler {
  int _intervalMinutes = 15;
  DateTime? _lastSent;

  // ✅ Track last-sent time via SharedPreferences so it survives isolate restarts
  static const _kLastSentKey = 'bg_location_last_sent';

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    print('[BG] Service started at $timestamp (starter: $starter)');
    final prefs = await SharedPreferences.getInstance();

    // Restore last sent time across restarts
    final lastSentMs = prefs.getInt(_kLastSentKey);
    if (lastSentMs != null) {
      _lastSent = DateTime.fromMillisecondsSinceEpoch(lastSentMs);
      print('[BG] Restored lastSent: $_lastSent');
    }

    final regJson = prefs.getString(_kDeviceRegistrationKey);
    if (regJson != null) {
      final reg = jsonDecode(regJson) as Map<String, dynamic>;
      // ✅ Handle both snake_case and camelCase depending on your Freezed serialization
      _intervalMinutes = (reg['location_ping_interval'] ??
              reg['locationPingInterval'] as int?) ??
          15;
      print('[BG] Ping interval: $_intervalMinutes min');
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    _handleEvent(timestamp);
  }

  Future<void> _handleEvent(DateTime timestamp) async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();

    // ✅ Reload to get latest writes from the main isolate
    await prefs.reload();

    var regJson = prefs.getString(_kDeviceRegistrationKey);

    if (regJson == null) {
      await Future.delayed(const Duration(seconds: 2));
      await prefs.reload();
      regJson = prefs.getString(_kDeviceRegistrationKey);
    }

    if (regJson == null) {
      print('[BG] No registration — skipping');
      return;
    }

    final reg = jsonDecode(regJson) as Map<String, dynamic>;

    // ✅ Handle both camelCase (Freezed default) and snake_case
    final deviceUuid = (reg['deviceUuid'] ?? reg['device_uuid']) as String?;
    final token = reg['token'] as String?;
    final intervalMinutes = (reg['locationPingInterval'] ??
            reg['location_ping_interval'] as int?) ??
        15;

    if (deviceUuid == null || token == null) {
      print('[BG] Missing deviceUuid/token. Keys found: ${reg.keys.toList()}');
      return;
    }

    // Throttle using persisted lastSent
    final lastSentMs = prefs.getInt('bg_location_last_sent');
    if (lastSentMs != null) {
      final elapsed = now
          .difference(DateTime.fromMillisecondsSinceEpoch(lastSentMs))
          .inMinutes;
      if (elapsed < intervalMinutes) {
        print('[BG] Throttled ($elapsed min < $intervalMinutes min)');
        return;
      }
    }

    // Get location
    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 20));
    } catch (e) {
      final last = await Geolocator.getLastKnownPosition();
      if (last == null) {
        print('[BG] No location: $e');
        return;
      }
      position = last;
    }

    final timestampStr = _formatTimestamp(now);
    final deviceId = prefs.getString('device_id') ?? 'unknown';

    // Save log
    List<String> logs = prefs.getStringList(_kLocationLogsKey) ?? [];
    logs.insert(0, '${position.latitude},${position.longitude},$timestampStr');
    if (logs.length > 50) logs = logs.sublist(0, 50);
    await prefs.setStringList(_kLocationLogsKey, logs);

    // Send to API
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ));
      final response = await dio.post(
        _kSendLocationUrl,
        data: {
          'device_uuid': deviceUuid,
          'device_id': deviceId,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'location_sent_at': timestampStr,
        },
        options: Options(
          headers: {
            'Authorization': token,
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      print('[BG] API response: ${response.statusCode}');

      // ✅ Persist lastSent so throttle survives isolate restarts
      await prefs.setInt('bg_location_last_sent', now.millisecondsSinceEpoch);

      await FlutterForegroundTask.updateService(
        notificationTitle: 'CCP Location Active',
        notificationText:
            'Last update: ${DateFormat('dd MMM, hh:mm a').format(now)}',
      );
    } catch (e) {
      print('[BG] Send error: $e');
      if (e is DioException) {
        print('[BG] Dio: ${e.type} — ${e.message}');
        print('[BG] Response: ${e.response?.data}');
      }
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    print('[BG] Service destroyed at $timestamp');
  }

  @override
  void onReceiveData(Object data) {}

  @override
  void onNotificationButtonPressed(String id) {}

  @override
  void onNotificationPressed() {}

  @override
  void onNotificationDismissed() {}
}

// ─── LocationTrackingService ──────────────────────────────────────────────────

class LocationTrackingService {
  final SharedPreferences _prefs;
  final Function(double, double, DateTime)? onLocationUpdate;

  // Foreground timer — active only while app UI is running
  Timer? _foregroundTimer;

  // Health check timer — restarts service if MIUI killed it
  Timer? _healthCheckTimer;

  LocationTrackingService(this._prefs, {this.onLocationUpdate});

  bool get isTrackingEnabled => _prefs.getBool(_kIsTrackingKey) ?? false;

  // ─── Init ──────────────────────────────────────────────────────────────────

  /// Call once from main.dart BEFORE runApp()
  static void initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'ccp_location_channel',
        channelName: 'CCP Location Tracking',
        channelDescription: 'Keeps location tracking active in the background',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        // ✅ ADD THIS — tapping notification brings app to foreground
        //buttons: [],
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5 * 60 * 1000),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  // ─── Permissions ───────────────────────────────────────────────────────────

  // ─── Start ─────────────────────────────────────────────────────────────────
  // Permissions are handled upfront by PermissionRequestScreen before the
  // user reaches HomeScreen — no need to re-request them here.

  Future<bool> startTracking() async {
    try {
      // Verify location permission is still granted (user may have revoked it)
      final locationGranted = await Permission.location.status;
      if (!locationGranted.isGranted) {
        print('[LOC] Location permission not granted');
        return false;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('[LOC] Location service (GPS) is disabled');
        return false;
      }

      // Start the foreground service — shows persistent notification
      final result = await FlutterForegroundTask.startService(
        serviceId: 1000,
        notificationTitle: 'CCP Location Active',
        notificationText: 'Location tracking is running',
        callback: startCallback,
      );

      if (result is ServiceRequestFailure) {
        print('[LOC] Service start failed: ${result.error}');
        return false;
      }

      print('[LOC] Foreground service started');

      // Foreground timer — while app UI is visible
      _startForegroundTimer();

      // Health check every 3 min — auto-restarts if OEM battery killer stops it
      _startHealthCheck();

      await _prefs.setBool(_kIsTrackingKey, true);
      return true;
    } catch (e) {
      print('[LOC] startTracking error: $e');
      return false;
    }
  }

  // ─── Foreground timer ──────────────────────────────────────────────────────

  void _startForegroundTimer() {
    _foregroundTimer?.cancel();
    _updateLocation(); // immediate update on start
    _foregroundTimer = Timer.periodic(
      const Duration(minutes: 15),
      (_) => _updateLocation(),
    );
  }

  Future<void> _updateLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 20));

      final now = DateTime.now();
      await _saveLocationLog(position.latitude, position.longitude, now);
      onLocationUpdate?.call(position.latitude, position.longitude, now);
      print('[FG] Location: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('[FG] Error: $e');
    }
  }

  // ─── Health check ──────────────────────────────────────────────────────────
  // MIUI can silently kill the foreground service without calling onDestroy.
  // This timer checks every 3 minutes and restarts the service if it's dead.

  void _startHealthCheck() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(
      const Duration(minutes: 3),
      (_) => _checkAndRestartService(),
    );
  }

  Future<void> _checkAndRestartService() async {
    if (!isTrackingEnabled) return;

    final isRunning = await FlutterForegroundTask.isRunningService;
    if (!isRunning) {
      print('[LOC] Service not running — restarting...');
      await FlutterForegroundTask.startService(
        serviceId: 1000,
        notificationTitle: 'CCP Location Active',
        notificationText: 'Location tracking resumed',
        callback: startCallback,
      );
      print('[LOC] Service restarted');
    }
  }

  // ─── Stop ──────────────────────────────────────────────────────────────────

  Future<void> stopTracking() async {
    try {
      await FlutterForegroundTask.stopService();
      _foregroundTimer?.cancel();
      _foregroundTimer = null;
      _healthCheckTimer?.cancel();
      _healthCheckTimer = null;
      await _prefs.setBool(_kIsTrackingKey, false);
      print('[LOC] Tracking stopped');
    } catch (e) {
      print('[LOC] stopTracking error: $e');
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _saveLocationLog(double lat, double long, DateTime ts) async {
    try {
      List<String> logs = _prefs.getStringList(_kLocationLogsKey) ?? [];
      logs.insert(0, '$lat,$long,${_formatTimestamp(ts)}');
      if (logs.length > 50) logs = logs.sublist(0, 50);
      await _prefs.setStringList(_kLocationLogsKey, logs);
    } catch (e) {
      print('[LOC] Save log error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getLocationLogs() async {
    try {
      final logs = _prefs.getStringList(_kLocationLogsKey) ?? [];
      return logs.map((log) {
        final parts = log.split(',');
        return {
          'latitude': double.parse(parts[0]),
          'longitude': double.parse(parts[1]),
          'timestamp': DateTime.parse(parts[2]),
        };
      }).toList();
    } catch (e) {
      print('[LOC] Get logs error: $e');
      return [];
    }
  }

  void dispose() {
    _foregroundTimer?.cancel();
    _healthCheckTimer?.cancel();
  }
}
