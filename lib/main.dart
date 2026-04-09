// lib/main.dart
import 'package:ccp_app/core/services/device_info_services.dart';
import 'package:ccp_app/core/services/location_tracking_service.dart';
import 'package:ccp_app/core/services/storage_services.dart';
import 'package:ccp_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ccp_app/features/home/presentation/screens/home_screen.dart';
import 'package:ccp_app/features/onboarding/presentation/screen/consent_selfie_screen.dart';
import 'package:ccp_app/features/permission/presentation/screens/permission_tutorial_screen.dart';
import 'package:ccp_app/services/permission_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await StorageService().init();
  await DeviceInfoService().initialize();

  LocationTrackingService.initForegroundTask();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider(create: (_) => AuthBloc())],
      child: MaterialApp(
        title: 'CFE App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const AppStartupScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AppStartupScreen extends StatefulWidget {
  const AppStartupScreen({super.key});

  @override
  State<AppStartupScreen> createState() => _AppStartupScreenState();
}

class _AppStartupScreenState extends State<AppStartupScreen> {
  final _permissionService = PermissionService();

  bool _checking = true;
  bool _permissionsGranted = false;
  bool _consentAndSelfieDone = false; // selfie captured + consent given

  static const _kConsentDoneKey = 'consent_selfie_done';

  @override
  void initState() {
    super.initState();
    _checkInitialState();
  }

  Future<void> _checkInitialState() async {
    final prefs = await SharedPreferences.getInstance();
    final consentDone = prefs.getBool(_kConsentDoneKey) ?? false;
    final allGranted = await _permissionService.areAllGranted();

    if (mounted) {
      setState(() {
        _permissionsGranted = allGranted;
        _consentAndSelfieDone = consentDone;
        _checking = false;
      });
    }
  }

  void _onPermissionsGranted() {
    if (mounted) setState(() => _permissionsGranted = true);
  }

  Future<void> _onConsentAndSelfieComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kConsentDoneKey, true);
    if (mounted) setState(() => _consentAndSelfieDone = true);
  }

  @override
  Widget build(BuildContext context) {
    // Splash
    if (_checking) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor),
              ),
              const SizedBox(height: 24),
              Text('Initializing...',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Colors.grey[600])),
            ],
          ),
        ),
      );
    }

    // Step 1: permissions not yet granted → tutorial + grant flow
    if (!_permissionsGranted) {
      return PermissionTutorialScreen(
        onPermissionsGranted: _onPermissionsGranted,
      );
    }

    // Step 2: consent + selfie not yet done
    if (!_consentAndSelfieDone) {
      return ConsentSelfieScreen(
        onCompleted: _onConsentAndSelfieComplete,
      );
    }

    // Step 3: all done → home
    return const HomeScreen();
  }
}
