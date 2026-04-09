// lib/features/home/presentation/pages/home_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io'; // for File()

import 'package:ccp_app/core/services/device_info_services.dart';
import 'package:ccp_app/core/services/location_tracking_service.dart';
import 'package:ccp_app/core/services/url_shotcut_service.dart';
import 'package:ccp_app/features/home/data/model/register_device_model/register_device_model.dart';
import 'package:ccp_app/features/home/data/model/url_shortcut/url_shortcut.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationLogEntry {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  LocationLogEntry({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ─── Browser state ──────────────────────────────────────────────────────────
  bool _showBrowser = false;
  WebViewController? _webViewController;
  String _currentUrl = '';
  bool _isLoading = false;
  bool _canGoBack = false;
  bool _canGoForward = false;

  // ─── Shortcuts ──────────────────────────────────────────────────────────────
  late UrlShortcutService _shortcutService;
  List<UrlShortcut> _shortcuts = [];
  bool _shortcutsLoaded = false;

  // ─── Location tracking ──────────────────────────────────────────────────────
  late LocationTrackingService _locationService;
  bool _isLocationTrackingEnabled = false;
  bool _showLocationLogs = false;
  final List<LocationLogEntry> _locationLogs = [];

  // ─── Auth / device registration ─────────────────────────────────────────────
  String? _ssoToken;
  String? _registrationToken;
  bool _isTokenCaptured = false;
  bool _isDeviceRegistered = false;
  bool _isRegisteringDevice = false;
  RegisterDeviceModel? _deviceRegistration;

  // ─── Selfie ──────────────────────────────────────────────────────────────────
  // Loaded from SharedPreferences key 'user_selfie_path'.
  // Set during ConsentSelfieScreen onboarding. Shown in appbar as CircleAvatar.
  String? _selfiePath;

  // ─── Dashboard data ───────────────────────────────────────────────────────────
  // TODO: replace with real API data
  final int _ptpCount = 3;
  final int _receiptsCut = 3;
  final int _receiptsTarget = 20;
  final List<String> _agreements = [
    'X0HEAGD00001407798',
    'X0HEBAT00001410473',
    'X0HEHYD00001396310',
  ];
  final List<Map<String, String>> _beatStops = [
    {'name': 'Nazarethpet', 'status': 'visited'},
    {'name': 'Guindy', 'status': 'current'},
    {'name': 'Perungudi', 'status': 'pending'},
  ];

  // ─── Init ───────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    final prefs = await SharedPreferences.getInstance();

    _shortcutService = UrlShortcutService(prefs);
    await _seedDefaultShortcuts();
    await _loadShortcuts();

    // MUST be called before getDeviceInfoMap() is ever used
    await DeviceInfoService().initialize();

    // Restore persisted SSO token (only present before first registration)
    _ssoToken = prefs.getString('auth_token');
    if (_ssoToken != null) {
      setState(() => _isTokenCaptured = true);
    }

    // Restore persisted device registration
    await _loadDeviceRegistration();

    // Load selfie path captured during onboarding
    final savedSelfie = prefs.getString('user_selfie_path');
    if (savedSelfie != null && File(savedSelfie).existsSync()) {
      if (mounted) setState(() => _selfiePath = savedSelfie);
    }

    // Init location service — callback calls the send-location API
    _locationService = LocationTrackingService(
      prefs,
      onLocationUpdate: (lat, long, timestamp) {
        if (!mounted) return;
        setState(() {
          _locationLogs.insert(
            0,
            LocationLogEntry(
                latitude: lat, longitude: long, timestamp: timestamp),
          );
          if (_locationLogs.length > 20) {
            _locationLogs.removeRange(20, _locationLogs.length);
          }
        });
        // Uses device_uuid + registration token — NOT the SSO token
        _sendLocationToAPI(lat, long, timestamp);
      },
    );

    await _loadSavedLocationLogs();

    // ── Tracking state is driven purely by device registration ────────────────
    // If device is registered → tracking must be ON (start/resume it)
    // If device is not registered → tracking must be OFF
    if (_isDeviceRegistered) {
      final started = await _locationService.startTracking();
      final isRunning = started || await FlutterForegroundTask.isRunningService;
      if (mounted) {
        setState(() => _isLocationTrackingEnabled = isRunning);
      }
    } else {
      // No registration — ensure service is stopped and switch is off
      await _locationService.stopTracking();
      if (mounted) {
        setState(() => _isLocationTrackingEnabled = false);
      }
    }
  }

  // ─── WebView ────────────────────────────────────────────────────────────────

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)

      // Flutter channel: web app (or bridge script) calls
      // FlutterChannel.postMessage(JSON.stringify({token: '...'}))
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (JavaScriptMessage message) async {
          debugPrint('=== FlutterChannel message received ===');
          debugPrint('Raw: ${message.message}');
          await _handleTokenMessage(message.message);
        },
      )
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (int progress) {
          if (mounted) setState(() => _isLoading = progress < 100);
        },
        onPageStarted: (String url) {
          if (mounted) {
            setState(() {
              _isLoading = true;
              _currentUrl = url;
            });
          }
          // Inject bridge as early as possible so it catches the first
          // localStorage.setItem call the web app makes after login
          _injectBridgeScript();
        },
        onPageFinished: (String url) async {
          debugPrint('Page finished: $url');
          if (mounted) {
            setState(() {
              _isLoading = false;
              _currentUrl = url;
            });
            _canGoBack = await _webViewController!.canGoBack();
            _canGoForward = await _webViewController!.canGoForward();
            if (mounted) setState(() {});
          }

          // Re-inject bridge after full load (handles SPAs that wipe the DOM)
          await _injectBridgeScript();

          // If we already have a saved token, push it into the page storage
          // so the web app recognises the session without re-login
          if (_ssoToken != null) await _injectTokenIntoPage();

          // Fallback: scan storage after known login-success URL patterns
          if (_isLoginSuccessUrl(url)) {
            debugPrint('Login-success URL detected: $url');
            await Future.delayed(const Duration(milliseconds: 800));
            await _tryCaptureSsoTokenFromStorage();
          }
        },
        onWebResourceError: (WebResourceError error) {
          debugPrint('WebView error: ${error.description}');
        },
      ));
  }

  bool _isLoginSuccessUrl(String url) =>
      url.contains('/login/done') ||
      url.contains('#/home') ||
      url.contains('/authenticated') ||
      url.contains('/dashboard');

  // ─── JS bridge ──────────────────────────────────────────────────────────────

  Future<void> _injectBridgeScript() async {
    if (_webViewController == null) return;
    try {
      await _webViewController!.runJavaScript(r'''
        (function() {
          if (window.__flutterBridgeInjected) return;
          window.__flutterBridgeInjected = true;

          var TOKEN_KEYS = ['token','authToken','auth_token','access_token',
                            'ccp.authToken','flutter_auth_token','jwt','bearer_token'];

          function forwardToken(value, source) {
            if (!value || value.length < 20) return;
            if (window.FlutterChannel && window.FlutterChannel.postMessage) {
              window.FlutterChannel.postMessage(
                JSON.stringify({ token: value, source: source })
              );
            }
          }

          var _lsSet = localStorage.setItem.bind(localStorage);
          localStorage.setItem = function(key, value) {
            _lsSet(key, value);
            if (TOKEN_KEYS.indexOf(key) !== -1) forwardToken(value, 'ls:' + key);
          };

          var _ssSet = sessionStorage.setItem.bind(sessionStorage);
          sessionStorage.setItem = function(key, value) {
            _ssSet(key, value);
            if (TOKEN_KEYS.indexOf(key) !== -1) forwardToken(value, 'ss:' + key);
          };

          window.addEventListener('storage', function(e) {
            if (TOKEN_KEYS.indexOf(e.key) !== -1 && e.newValue) {
              forwardToken(e.newValue, 'evt:' + e.key);
            }
          });

          console.log('[FlutterBridge] injected');
        })();
      ''');
    } catch (e) {
      debugPrint('Bridge inject error: $e');
    }
  }

  // ─── Token capture ──────────────────────────────────────────────────────────

  Future<void> _handleTokenMessage(String raw) async {
    try {
      // ── Guard: skip if device already registered ──────────────────────────
      if (_isDeviceRegistered) {
        debugPrint('Device already registered — ignoring token message');
        return;
      }
      String token = raw;
      if (raw.trim().startsWith('{')) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        token = (map['token'] as String?) ?? raw;
      }

      token = token.replaceAll('"', '').trim();
      if (token.isEmpty || token.length < 20) return;
      if (token == _ssoToken) return;

      debugPrint('SSO token captured (${token.length} chars)');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);

      if (mounted) {
        setState(() {
          _ssoToken = token;
          _isTokenCaptured = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Login token captured — registering device…'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        await _registerDevice();
      }
    } catch (e) {
      debugPrint('Error handling token message: $e');
    }
  }

  Future<void> _tryCaptureSsoTokenFromStorage() async {
    if (_webViewController == null || _isTokenCaptured || _isDeviceRegistered)
      return;
    const keys = [
      'token',
      'authToken',
      'auth_token',
      'access_token',
      'ccp.authToken',
      'flutter_auth_token',
      'jwt',
    ];
    for (final key in keys) {
      try {
        final result = await _webViewController!
            .runJavaScriptReturningResult("localStorage.getItem('$key')");
        final value = result.toString().replaceAll('"', '').trim();
        if (value.isNotEmpty && value != 'null' && value.length > 20) {
          debugPrint('Fallback token found — key: $key');
          await _handleTokenMessage(value);
          return;
        }
      } catch (_) {}
    }
  }

  Future<void> _clearSsoToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    setState(() {
      _ssoToken = null;
      _isTokenCaptured = false;
    });
  }

  // ─── Token injection (returning users) ──────────────────────────────────────

  Future<void> _injectTokenIntoPage() async {
    if (_webViewController == null || _ssoToken == null || _ssoToken!.isEmpty)
      return;
    try {
      final escaped = _ssoToken!
          .replaceAll('\\', '\\\\')
          .replaceAll('"', '\\"')
          .replaceAll('\n', '\\n')
          .replaceAll('\r', '\\r');
      final accessExpiry =
          DateTime.now().add(const Duration(hours: 1)).toIso8601String();
      final refreshExpiry =
          DateTime.now().add(const Duration(days: 7)).toIso8601String();

      await _webViewController!.runJavaScript('''
        (function() {
          var t = "$escaped";
          localStorage.setItem('ccp.authToken', t);
          localStorage.setItem('authToken', t);
          localStorage.setItem('token', t);
          localStorage.setItem('access_token', t);
          localStorage.setItem('ccp.accessTokenExpiryAt', "$accessExpiry");
          localStorage.setItem('ccp.refreshTokenExpiryAt', "$refreshExpiry");
          sessionStorage.setItem('ccp.authToken', t);
          sessionStorage.setItem('ccp.accessTokenExpiryAt', "$accessExpiry");
          sessionStorage.setItem('ccp.refreshTokenExpiryAt', "$refreshExpiry");
          window.dispatchEvent(new Event('storage'));
          console.log('[FlutterBridge] token injected into page');
        })();
      ''');
    } catch (e) {
      debugPrint('Token injection error: $e');
    }
  }

  // ─── API 1: Register Device ─────────────────────────────────────────────────

  Future<void> _registerDevice() async {
    if (_ssoToken == null) {
      debugPrint('Cannot register: no SSO token');
      return;
    }
    if (_isRegisteringDevice) {
      debugPrint('Registration already in progress');
      return;
    }

    if (mounted) setState(() => _isRegisteringDevice = true);

    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ));
      final deviceInfo = DeviceInfoService().getDeviceInfoMap();

      final requestData = {
        'device_id': deviceInfo['device_id'],
        'manufacturer': deviceInfo['manufacturer'],
        'model': deviceInfo['model'],
        'device_name': deviceInfo['device_name'],
        'is_physical_device': deviceInfo['is_physical_device'],
      };

      debugPrint('register-device payload: $requestData');

      final response = await dio.post(
        'http://10.9.75.138:3000/employee-activity/register-device',
        data: requestData,
        options: Options(
          headers: {
            'Authorization': _ssoToken,
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('register-device success: ${response.data}');
        final registration = RegisterDeviceModel.fromJson(response.data);

        await _saveDeviceRegistration(registration);

        if (mounted) {
          setState(() {
            _deviceRegistration = registration;
            _registrationToken = registration.token;
            _isDeviceRegistered = true;
          });

          debugPrint('Registered — user: ${registration.user}');
          debugPrint('Employee ID: ${registration.employeeId}');
          debugPrint('Device UUID: ${registration.deviceUuid}');
          debugPrint('Ping interval: ${registration.locationPingInterval} min');

          await _clearSsoToken();

          await _startLocationTrackingAfterRegistration(
              registration.locationPingInterval);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✓ Device registered successfully'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      } else {
        debugPrint('register-device returned ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('register-device error: $e');
      if (e is DioException) {
        debugPrint('Dio type: ${e.type}, msg: ${e.message}');
        debugPrint('Response: ${e.response?.data}');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Device registration failed. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRegisteringDevice = false);
    }
  }

  // ─── API 2: Send Location ───────────────────────────────────────────────────

  Future<void> _sendLocationToAPI(
      double lat, double long, DateTime timestamp) async {
    if (_deviceRegistration == null) {
      debugPrint('No device registration — skipping send-location');
      return;
    }

    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ));
      final deviceInfo = DeviceInfoService().getDeviceInfoMap();

      final requestData = {
        'device_uuid': _deviceRegistration!.deviceUuid,
        'device_id': deviceInfo['device_id'],
        'latitude': lat,
        'longitude': long,
        'location_sent_at':
            DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(timestamp),
      };

      debugPrint('send-location payload: $requestData');

      final response = await dio.post(
        'http://10.9.75.138:3000/employee-activity/save-device-location',
        data: requestData,
        options: Options(
          headers: {
            'Authorization': _deviceRegistration!.token,
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('send-location success: ${response.data}');
      } else {
        debugPrint('send-location returned ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('send-location error: $e');
      if (e is DioException) {
        debugPrint('Dio type: ${e.type}, msg: ${e.message}');
        debugPrint('Response: ${e.response?.data}');
      }
    }
  }

  Future<void> _startLocationTrackingAfterRegistration(
      int intervalMinutes) async {
    debugPrint('Starting location tracking at ${intervalMinutes}min interval');
    final started = await _locationService.startTracking();
    if (mounted) {
      setState(() => _isLocationTrackingEnabled = started);
    }
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      await _registerDevice();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location permission required for device registration'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ─── Persistence ────────────────────────────────────────────────────────────

  Future<void> _saveDeviceRegistration(RegisterDeviceModel r) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'device_registration', registerDeviceModelToJson(r));
    } catch (e) {
      debugPrint('Error saving device registration: $e');
    }
  }

  Future<void> _loadDeviceRegistration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString('device_registration');
      if (json != null) {
        final r = registerDeviceModelFromJson(json);
        if (mounted) {
          setState(() {
            _deviceRegistration = r;
            _registrationToken = r.token;
            _isDeviceRegistered = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading device registration: $e');
    }
  }

  Future<void> _clearAllAuthData() async {
    await _clearSsoToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('device_registration');
    setState(() {
      _deviceRegistration = null;
      _registrationToken = null;
      _isDeviceRegistered = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All authentication data cleared'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  // ─── Location tracking ──────────────────────────────────────────────────────

  Future<void> _toggleLocationTracking(bool value) async {
    if (value) {
      if (!_isDeviceRegistered) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Please log in to CCP Web first to register this device.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final started = await _locationService.startTracking();
      final isRunning = started || await FlutterForegroundTask.isRunningService;
      if (mounted) {
        setState(() => _isLocationTrackingEnabled = isRunning);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isRunning
                ? 'Location tracking started — Updates every 15 minutes'
                : 'Failed to start. Check location permissions.'),
            backgroundColor: isRunning ? Colors.green : Colors.red,
          ),
        );
      }
    } else {
      await _locationService.stopTracking();
      if (mounted) {
        setState(() => _isLocationTrackingEnabled = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location tracking stopped'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _loadSavedLocationLogs() async {
    final saved = await _locationService.getLocationLogs();
    if (mounted) {
      setState(() {
        _locationLogs
          ..clear()
          ..addAll(saved.map((log) => LocationLogEntry(
                latitude: log['latitude'],
                longitude: log['longitude'],
                timestamp: log['timestamp'],
              )));
      });
    }
  }

  // ─── Shortcuts ──────────────────────────────────────────────────────────────

  Future<void> _seedDefaultShortcuts() async {
    final prefs = await SharedPreferences.getInstance();
    final seeded = prefs.getBool('default_shortcuts_seeded') ?? false;
    if (seeded) return;

    await _shortcutService.addShortcut(
      'https://ccpdev02.chola.murugappa.com',
      'CCP',
    );

    await prefs.setBool('default_shortcuts_seeded', true);
  }

  Future<void> _loadShortcuts() async {
    final shortcuts = await _shortcutService.getShortcuts();
    if (mounted) {
      setState(() {
        _shortcuts = shortcuts;
        _shortcutsLoaded = true;
      });
    }
  }

  Future<void> _addShortcutFromWebView(String url) async {
    if (url.isEmpty) return;
    if (_shortcuts.any((s) => s.url == url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Shortcut already exists'),
            backgroundColor: Colors.orange),
      );
      return;
    }
    String title = _extractDomainName(url);
    try {
      final t = await _webViewController?.getTitle();
      if (t != null && t.isNotEmpty) title = t;
    } catch (_) {}
    final added = await _shortcutService.addShortcut(url, title);
    if (added && mounted) {
      await _loadShortcuts();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Added "$title" to shortcuts'),
            backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _deleteShortcut(UrlShortcut shortcut) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Shortcut'),
        content: Text('Delete "${shortcut.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _shortcutService.removeShortcut(shortcut.id);
      await _loadShortcuts();
    }
  }

  String _extractDomainName(String url) {
    try {
      return Uri.parse(url).host.replaceFirst('www.', '');
    } catch (_) {
      return url;
    }
  }

  // ─── Browser ────────────────────────────────────────────────────────────────

  void _loadUrl({required String presetUrl}) {
    String url = presetUrl.replaceAll(' ', '');
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    try {
      _initializeWebView();
      _webViewController?.loadRequest(Uri.parse(url));
      setState(() => _showBrowser = true);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open URL')),
      );
    }
  }

  void _closeBrowser() {
    // Only reset browser-related state — do NOT touch location tracking state
    setState(() {
      _showBrowser = false;
      _webViewController = null;
      _currentUrl = '';
      _isLoading = false;
      _canGoBack = false;
      _canGoForward = false;
    });

    _syncLocationTrackingState();
  }

  void _syncLocationTrackingState() {
    final shouldBeEnabled = _isDeviceRegistered;
    if (_isLocationTrackingEnabled != shouldBeEnabled) {
      setState(() => _isLocationTrackingEnabled = shouldBeEnabled);
      if (shouldBeEnabled) {
        _locationService.startTracking().then((started) async {
          final isRunning =
              started || await FlutterForegroundTask.isRunningService;
          if (mounted && _isLocationTrackingEnabled != isRunning) {
            setState(() => _isLocationTrackingEnabled = isRunning);
          }
        });
      }
    }
  }

  Future<void> _refresh() async => _webViewController?.reload();

  // ─── Selfie full-screen dialog ───────────────────────────────────────────────

  void _showSelfieDialog() {
    if (_selfiePath == null) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(_selfiePath!),
                  width: 260,
                  height: 260,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Auth Status Dialog ──────────────────────────────────────────────────────

  void _showAuthStatusDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _isDeviceRegistered ? Icons.check_circle : Icons.cancel,
              color: _isDeviceRegistered ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            const Text('Authentication Status'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('SSO Login Token'),
              const SizedBox(height: 8),
              _infoRow(
                'Status',
                _isTokenCaptured ? 'Captured ✓' : 'Not captured',
                _isTokenCaptured ? Colors.green : Colors.red,
              ),
              if (_isTokenCaptured && _ssoToken != null) ...[
                const SizedBox(height: 6),
                _infoRow('Length', '${_ssoToken!.length} chars', Colors.grey),
                const SizedBox(height: 8),
                _tokenBox('SSO Token Preview', _ssoToken!),
              ],
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              _sectionTitle('Device Registration'),
              const SizedBox(height: 8),
              _infoRow(
                'Status',
                _isDeviceRegistered ? 'Registered ✓' : 'Not registered',
                _isDeviceRegistered ? Colors.green : Colors.orange,
              ),
              if (_isDeviceRegistered && _deviceRegistration != null) ...[
                const SizedBox(height: 10),
                _infoRow('User', _deviceRegistration!.user, Colors.blue),
                const SizedBox(height: 6),
                _infoRow('Employee ID', _deviceRegistration!.employeeId,
                    Colors.blue),
                const SizedBox(height: 6),
                _infoRow('Device UUID', _deviceRegistration!.deviceUuid,
                    Colors.indigo),
                const SizedBox(height: 6),
                _infoRow(
                  'Ping Interval',
                  '${_deviceRegistration!.locationPingInterval} minutes',
                  Colors.orange,
                ),
                const SizedBox(height: 6),
                _infoRow('Ping Start',
                    _deviceRegistration!.locationPingStartTime, Colors.purple),
                const SizedBox(height: 6),
                _infoRow('Ping End', _deviceRegistration!.locationPingEndTime,
                    Colors.purple),
                if (_registrationToken != null) ...[
                  const SizedBox(height: 12),
                  _tokenBox('Registration Token Preview', _registrationToken!),
                ],
              ] else if (_isRegisteringDevice) ...[
                const SizedBox(height: 12),
                const Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Registering…',
                        style: TextStyle(color: Colors.orange)),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 10),
                Text(
                  _isTokenCaptured
                      ? 'Token captured. Tap "Register Now" to retry.'
                      : 'Log in via the browser to capture your SSO token.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (_isTokenCaptured && !_isDeviceRegistered && !_isRegisteringDevice)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _registerDevice();
              },
              child: const Text('Register Now'),
            ),
          if (_isTokenCaptured || _isDeviceRegistered)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _clearAllAuthData();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Clear All Data'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ─── Widget helpers ──────────────────────────────────────────────────────────

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      );

  Widget _infoRow(String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
                fontSize: 13, color: color, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _tokenBox(String label, String token) {
    final preview = token.length > 50 ? '${token.substring(0, 50)}…' : token;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            preview,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
          ),
        ),
      ],
    );
  }

  // ─── Location tracking card ──────────────────────────────────────────────────

  Widget _buildLocationTrackingCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (_isLocationTrackingEnabled
                            ? Colors.green
                            : Colors.grey)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.location_on,
                    color:
                        _isLocationTrackingEnabled ? Colors.green : Colors.grey,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Smart Location Access',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isLocationTrackingEnabled
                            ? 'Updates every 15 minutes'
                            : 'Disabled',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isLocationTrackingEnabled,
                  onChanged: _toggleLocationTracking,
                  activeColor: Colors.green,
                ),
              ],
            ),
            if (_isLocationTrackingEnabled && _locationLogs.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Updates (${_locationLogs.length})',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700]),
                  ),
                  TextButton.icon(
                    onPressed: () =>
                        setState(() => _showLocationLogs = !_showLocationLogs),
                    icon: Icon(
                        _showLocationLogs
                            ? Icons.expand_less
                            : Icons.expand_more,
                        size: 20),
                    label: Text(_showLocationLogs ? 'Hide' : 'Show'),
                  ),
                ],
              ),
              if (_showLocationLogs) ...[
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _locationLogs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final log = _locationLogs[index];
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.blue.withOpacity(0.1),
                          child: Text('${index + 1}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue)),
                        ),
                        title: Text(
                          'Lat: ${log.latitude.toStringAsFixed(6)}, '
                          'Long: ${log.longitude.toStringAsFixed(6)}',
                          style: const TextStyle(
                              fontSize: 13, fontFamily: 'monospace'),
                        ),
                        subtitle: Text(
                          DateFormat('MMM dd, hh:mm a').format(log.timestamp),
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                        trailing: Icon(Icons.my_location,
                            size: 16, color: Colors.grey[400]),
                      );
                    },
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  // ─── Shortcuts list ──────────────────────────────────────────────────────────

  // ─── Dashboard ──────────────────────────────────────────────────────────────

  Widget _buildDashboard() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _buildLocationTrackingCard(),
        const SizedBox(height: 20),
        _buildShortcutButtons(),
        const SizedBox(height: 20),
        if (_isDeviceRegistered) _buildTodayActivity(),
        const SizedBox(height: 20),
        if (_isDeviceRegistered) _buildBeatPlanner(),
        const SizedBox(height: 20),
        if (_isDeviceRegistered) _buildAgreements(),
        // _buildTodayActivity(),
        // const SizedBox(height: 20),
        // _buildBeatPlanner(),
        // const SizedBox(height: 20),
        // _buildAgreements(),
      ],
    );
  }

  // ── Today Activity ────────────────────────────────────────────────────────

  Widget _buildTodayActivity() {
    final receiptPct = _receiptsTarget > 0
        ? (_receiptsCut / _receiptsTarget).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Today\'s activity', Icons.today),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'PTP for the Day',
                value: '$_ptpCount',
                sub: '',
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'Receipts cut',
                value: '$_receiptsCut / $_receiptsTarget',
                sub: '',
                color: Colors.green,
                progress: receiptPct,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Contacts Made',
                value: '2 / 8',
                sub: '',
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Beat Planner ─────────────────────────────────────────────────────────

  Widget _buildBeatPlanner() {
    final visitedCount =
        _beatStops.where((s) => s['status'] == 'visited').length;
    final progress =
        _beatStops.isEmpty ? 0.0 : visitedCount / _beatStops.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Beat planner', Icons.map),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.withOpacity(0.15)),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Route stops row
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: _beatStops.asMap().entries.map((e) {
                          final stop = e.value;
                          final isLast = e.key == _beatStops.length - 1;
                          final color = stop['status'] == 'visited'
                              ? Colors.green
                              : stop['status'] == 'current'
                                  ? Colors.blue
                                  : Colors.grey;
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle, color: color),
                              ),
                              const SizedBox(width: 4),
                              Text(stop['name']!,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                      fontWeight: stop['status'] == 'current'
                                          ? FontWeight.w600
                                          : FontWeight.normal)),
                              if (!isLast)
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  child: Icon(Icons.arrow_forward,
                                      size: 12, color: Colors.grey[400]),
                                ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('${_beatStops.length} stops',
                          style: const TextStyle(
                              fontSize: 11,
                              color: Colors.blue,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),

              // Map image
              SizedBox(
                height: 190,
                width: double.infinity,
                child: Image.asset(
                  'assets/images/beat_map.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[100],
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.map_outlined,
                              size: 40, color: Colors.grey[400]),
                          const SizedBox(height: 6),
                          Text('Route map',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[500])),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Progress footer
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: Colors.green),
                    ),
                    // const SizedBox(width: 6),
                    // Text(
                    //   '$visitedCount of ${_beatStops.length} stops visited',
                    //   style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    // ),
                    // const SizedBox(width: 10),
                    // Expanded(
                    //   child: ClipRRect(
                    //     borderRadius: BorderRadius.circular(3),
                    //     child: LinearProgressIndicator(
                    //       value: progress,
                    //       minHeight: 4,
                    //       backgroundColor: Colors.grey[200],
                    //       valueColor:
                    //           const AlwaysStoppedAnimation<Color>(Colors.green),
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Agreements ────────────────────────────────────────────────────────────

  Widget _buildAgreements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Agreements', Icons.description_outlined),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.withOpacity(0.15)),
          ),
          child: Column(
            children: _agreements.asMap().entries.map((entry) {
              final idx = entry.key;
              final id = entry.value;
              final isLast = idx == _agreements.length - 1;

              // Parse type code from agreement ID (e.g. AGD, BAT, HYD)
              final typeCode =
                  id.length > 7 ? id.substring(4, 7).toUpperCase() : '';

              // Cycle status for demo — replace with real data
              final statuses = ['Pending', 'Visited', 'Scheduled'];
              final statusColors = [Colors.orange, Colors.green, Colors.blue];
              final statusBg = [
                Colors.orange.withOpacity(0.1),
                Colors.green.withOpacity(0.1),
                Colors.blue.withOpacity(0.1),
              ];
              final status = statuses[idx % statuses.length];
              final statusColor = statusColors[idx % statusColors.length];
              final statusBgColor = statusBg[idx % statusBg.length];

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              "${entry.key + 1}",
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'monospace'),
                            ),
                          ),
                        ),
                        // const SizedBox(width: 12),
                        // Container(
                        //   width: 36,
                        //   height: 36,
                        //   decoration: BoxDecoration(
                        //     color: Colors.blue.withOpacity(0.08),
                        //     borderRadius: BorderRadius.circular(10),
                        //   ),
                        //   child: const Icon(Icons.description_outlined,
                        //       size: 18, color: Colors.blue),
                        // ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                id,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'monospace'),
                              ),
                              // const SizedBox(height: 2),
                              // Text(
                              //   'Sivachander',
                              //   style: TextStyle(
                              //       fontSize: 11, color: Colors.grey[500]),
                              // ),
                            ],
                          ),
                        ),
                        // Container(
                        //   padding: const EdgeInsets.symmetric(
                        //       horizontal: 8, vertical: 3),
                        //   decoration: BoxDecoration(
                        //     color: statusBgColor,
                        //     borderRadius: BorderRadius.circular(20),
                        //   ),
                        //   child: Text(
                        //     status,
                        //     style: TextStyle(
                        //         fontSize: 11,
                        //         fontWeight: FontWeight.w600,
                        //         color: statusColor),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Divider(
                        height: 0.5,
                        thickness: 0.5,
                        indent: 14,
                        color: Colors.grey.withOpacity(0.15)),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ── Shortcut buttons ──────────────────────────────────────────────────────

  Widget _buildShortcutButtons() {
    if (!_shortcutsLoaded || _shortcuts.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Quick access', Icons.link),
        const SizedBox(height: 10),
        ...(_shortcuts.map((shortcut) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => _loadUrl(presetUrl: shortcut.url),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.withOpacity(0.15)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.language,
                            color: Theme.of(context).primaryColor, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(shortcut.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14)),
                            Text(shortcut.url,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: Colors.grey[500], fontSize: 11)),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios,
                          size: 14, color: Colors.grey[400]),
                    ],
                  ),
                ),
              ),
            ))),
      ],
    );
  }

  // ── Helper widgets ────────────────────────────────────────────────────────

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  // ─── Dispose ────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _locationService.dispose();
    super.dispose();
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _showBrowser
            ? SizedBox(
                height: 40,
                child: TextField(
                  controller: TextEditingController(text: _currentUrl),
                  readOnly: true,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.2),
                    prefixIcon: const Icon(Icons.lock, size: 16),
                  ),
                ),
              )
            : const Text('Home'),
        leading: _showBrowser
            ? IconButton(
                icon: const Icon(Icons.close), onPressed: _closeBrowser)
            : null,
        actions: [
          // ── Selfie avatar (home screen only) ──────────────────
          // Displayed when a selfie was captured during onboarding.
          // Tap opens a full-size preview dialog.
          if (!_showBrowser && _selfiePath != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: GestureDetector(
                onTap: _showSelfieDialog,
                child: CircleAvatar(
                  radius: 18,
                  backgroundImage: FileImage(File(_selfiePath!)),
                  backgroundColor: Colors.grey[300],
                ),
              ),
            ),

          // ── Auth status icon (home only) ──────────────────────
          if (!_showBrowser)
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    _isDeviceRegistered
                        ? Icons.verified_user
                        : Icons.no_encryption,
                    color: _isDeviceRegistered
                        ? Colors.green
                        : _isTokenCaptured
                            ? Colors.orange
                            : Colors.grey,
                  ),
                  onPressed: _showAuthStatusDialog,
                  tooltip: _isDeviceRegistered
                      ? 'Device registered'
                      : _isTokenCaptured
                          ? 'Token captured — pending registration'
                          : 'Not authenticated',
                ),
                if (_isRegisteringDevice)
                  const Positioned(
                    bottom: 8,
                    right: 8,
                    child: SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(strokeWidth: 1.5),
                    ),
                  ),
              ],
            ),

          // ── Browser controls ──────────────────────────────────
          if (_showBrowser) ...[
            IconButton(
              icon: Icon(Icons.arrow_back,
                  color: _canGoBack ? null : Colors.grey),
              onPressed: _canGoBack
                  ? () async {
                      if (await _webViewController!.canGoBack()) {
                        await _webViewController!.goBack();
                      }
                    }
                  : null,
            ),
            IconButton(
              icon: Icon(Icons.arrow_forward,
                  color: _canGoForward ? null : Colors.grey),
              onPressed: _canGoForward
                  ? () async {
                      if (await _webViewController!.canGoForward()) {
                        await _webViewController!.goForward();
                      }
                    }
                  : null,
            ),
            IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
          ],
        ],
      ),
      body: Stack(
        children: [
          if (!_showBrowser) _buildDashboard(),
          if (_showBrowser && _webViewController != null)
            Column(
              children: [
                if (_isLoading) const LinearProgressIndicator(),
                Expanded(child: WebViewWidget(controller: _webViewController!)),
              ],
            ),
        ],
      ),
    );
  }
}

// ─── Stat card widget ────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color color;
  final double? progress;

  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: color.withOpacity(0.9))),
          if (progress != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(sub, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        ],
      ),
    );
  }
}
