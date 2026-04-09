// lib/features/permissions/presentation/pages/permission_tutorial_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionTutorialScreen extends StatefulWidget {
  final VoidCallback onPermissionsGranted;
  const PermissionTutorialScreen(
      {super.key, required this.onPermissionsGranted});

  @override
  State<PermissionTutorialScreen> createState() =>
      _PermissionTutorialScreenState();
}

class _PermissionTutorialScreenState extends State<PermissionTutorialScreen>
    with WidgetsBindingObserver {
  int _currentStep = 0;
  bool _isRequesting = false;
  bool _showRetry = false;

  // Battery-specific lifecycle tracking
  bool _batteryRequestInFlight = false;
  bool _wentPausedForBattery = false;

  late List<_PermStep> _steps;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _buildSteps();
    _skipAlreadyGranted();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_batteryRequestInFlight) return;

    if (state == AppLifecycleState.paused) {
      // User is now on the battery settings screen
      _wentPausedForBattery = true;
    } else if (state == AppLifecycleState.resumed && _wentPausedForBattery) {
      // User returned from battery settings — treat as granted regardless of
      // what permission_handler reports. On Samsung/Xiaomi/Oppo, "No
      // restrictions" does NOT set isIgnoringBatteryOptimizations=true but
      // it IS functionally equivalent and the user has taken the action.
      _wentPausedForBattery = false;
      _batteryRequestInFlight = false;
      if (mounted) {
        setState(() => _isRequesting = false);
        _advance();
      }
    }
  }

  void _buildSteps() {
    _steps = [
      _PermStep(
        permission: Permission.location,
        icon: Icons.location_on,
        iconColor: const Color(0xFF2196F3),
        title: 'Location',
        why:
            'Tracks your field visits and sends your GPS coordinates to the office system.',
        dialogTitle: "Allow CCP App to access this device's location?",
        dialogOptions: [
          _DialogOption('While Using the App', isTarget: true),
          _DialogOption(
            'Only this time',
          ),
          _DialogOption("Don't allow"),
        ],
      ),
      _PermStep(
        permission: Permission.locationAlways,
        icon: Icons.location_searching,
        iconColor: const Color(0xFF3F51B5),
        title: 'Background location',
        why:
            'Keeps location tracking active when the app is closed or screen is locked.',
        dialogTitle: 'Change location permission to "Allow all the time"?',
        dialogOptions: [
          _DialogOption('Change to "Allow all the time"', isTarget: true),
          _DialogOption('Keep "Allow only while using the app"'),
        ],
        note: 'Android may open Settings — select "Allow all the time".',
      ),
      _PermStep(
        permission: Permission.camera,
        icon: Icons.camera_alt,
        iconColor: const Color(0xFF9C27B0),
        title: 'Camera',
        why: 'Captures photos of documents, receipts and field evidence.',
        dialogTitle: 'Allow CCP App to take pictures and record video?',
        dialogOptions: [
          _DialogOption('While Using the App', isTarget: true),
          _DialogOption(
            'Only this time',
          ),
          _DialogOption("Don't allow"),
          // _DialogOption('Allow', isTarget: true),
          // _DialogOption("Don't allow"),
        ],
      ),
      if (Platform.isAndroid)
        _PermStep(
          permission: Permission.notification,
          icon: Icons.notifications,
          iconColor: const Color(0xFF009688),
          title: 'Notifications',
          why:
              'Shows a status bar icon confirming background location is active.',
          dialogTitle: 'Allow CCP App to send you notifications?',
          dialogOptions: [
            _DialogOption('Allow', isTarget: true),
            _DialogOption("Don't allow"),
          ],
        ),
      if (Platform.isAndroid)
        _PermStep(
          permission: Permission.ignoreBatteryOptimizations,
          icon: Icons.battery_charging_full,
          iconColor: const Color(0xFFFF9800),
          title: 'Battery optimization',
          why:
              'Prevents Android from stopping background location when the screen turns off.',
          dialogTitle: 'Battery optimization settings will open.',
          dialogOptions: [
            _DialogOption('No restrictions', isTarget: true),
            _DialogOption('Optimized (default)'),
            _DialogOption('Restricted'),
          ],
          note: 'Select "No restrictions" for CCP App and tap the back button.',
          isBatteryStep: true,
        ),
    ];
  }

  Future<void> _skipAlreadyGranted() async {
    for (int i = 0; i < _steps.length; i++) {
      final s = _steps[i];
      // Battery: check if already exempted
      if (s.isBatteryStep) {
        final status = await Permission.ignoreBatteryOptimizations.status;
        if (status.isGranted) {
          if (mounted) setState(() => _currentStep = i + 1);
        } else {
          break;
        }
      } else {
        final status = await s.permission.status;
        if (status.isGranted || status.isLimited) {
          if (mounted) setState(() => _currentStep = i + 1);
        } else {
          break;
        }
      }
    }
    if (_currentStep >= _steps.length && mounted) {
      widget.onPermissionsGranted();
    }
  }

  Future<void> _requestCurrent() async {
    if (_isRequesting || _currentStep >= _steps.length) return;
    final step = _steps[_currentStep];

    if (step.permission == Permission.locationAlways) {
      final loc = await Permission.location.status;
      if (!loc.isGranted) {
        _showSnack('Please grant Location permission first');
        return;
      }
    }

    setState(() {
      _isRequesting = true;
      _showRetry = false;
    });

    if (step.isBatteryStep) {
      // Reset lifecycle flags before firing the intent
      _wentPausedForBattery = false;
      _batteryRequestInFlight = true;
      // Fire intent — returns immediately, lifecycle handles the result
      await Permission.ignoreBatteryOptimizations.request();
      // _isRequesting stays true until didChangeAppLifecycleState clears it
      return;
    }

    // Standard permission dialog
    await step.permission.request();
    if (!mounted) return;

    final status = await step.permission.status;
    setState(() => _isRequesting = false);

    if (status.isGranted || status.isLimited) {
      _advance();
    } else {
      setState(() => _showRetry = true);
    }
  }

  void _advance() {
    if (_currentStep + 1 >= _steps.length) {
      widget.onPermissionsGranted();
    } else {
      setState(() {
        _currentStep++;
        _showRetry = false;
      });
    }
  }

  void _openAppSettings() {
    // For battery: just re-trigger the same intent
    final step = _steps[_currentStep];
    if (step.isBatteryStep) {
      _requestCurrent();
    } else {
      openAppSettings();
    }
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  void _exitApp() => exit(0);

  @override
  Widget build(BuildContext context) {
    if (_currentStep >= _steps.length) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final step = _steps[_currentStep];
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvoked: (_) => _showExitDialog(),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.security,
                            color: theme.primaryColor, size: 20),
                        const SizedBox(width: 8),
                        Text('App permissions',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: theme.primaryColor)),
                        const Spacer(),
                        Text('${_currentStep + 1} / ${_steps.length}',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[500])),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (_currentStep + 1) / _steps.length,
                        minHeight: 6,
                        backgroundColor: Colors.grey[200],
                        valueColor:
                            AlwaysStoppedAnimation<Color>(theme.primaryColor),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_steps.length, (i) {
                        final done = i < _currentStep;
                        final active = i == _currentStep;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: active ? 22 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: done
                                ? Colors.green
                                : active
                                    ? theme.primaryColor
                                    : Colors.grey[300],
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon + title
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: step.iconColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(step.icon,
                                color: step.iconColor, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(step.title,
                                    style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold)),
                                Text('Why we need this',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[500])),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Why
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: step.iconColor.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: step.iconColor.withOpacity(0.2)),
                        ),
                        child: Text(step.why,
                            style: TextStyle(
                                fontSize: 14,
                                height: 1.55,
                                color: Colors.grey[800])),
                      ),
                      const SizedBox(height: 22),

                      // Dialog label
                      Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                                color: Color(0xFF1565C0),
                                shape: BoxShape.circle),
                            child: const Center(
                              child: Text('i',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              step.isBatteryStep
                                  ? 'Android will open battery settings — here\'s what to select:'
                                  : 'Android will show this dialog — here\'s what to tap:',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700]),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      _MockDialog(step: step),

                      if (step.note != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.amber[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.amber.withOpacity(0.4)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline,
                                  size: 16, color: Colors.amber[800]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(step.note!,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.amber[900])),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Retry card
                      if (_showRetry) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Icon(Icons.warning_amber_rounded,
                                    color: Colors.red[700], size: 18),
                                const SizedBox(width: 8),
                                Text('Permission not granted',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.red[800])),
                              ]),
                              const SizedBox(height: 6),
                              Text(
                                step.isBatteryStep
                                    ? 'Please open battery settings and select "No restrictions" for CCP App.'
                                    : 'This permission is required. Tap "Try again" or open Settings.',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.red[700]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _showExitDialog,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Exit'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isRequesting ? null : _requestCurrent,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isRequesting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : Text(_showRetry
                                ? (step.isBatteryStep
                                    ? 'Open battery settings'
                                    : 'Try again')
                                : 'Grant this permission'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit App?'),
        content: const Text('All permissions are required. Exit anyway?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _exitApp();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}

// ─── Mock dialog ──────────────────────────────────────────────────────────────

class _MockDialog extends StatelessWidget {
  final _PermStep step;
  const _MockDialog({required this.step});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                        color: Colors.blue[700],
                        borderRadius: BorderRadius.circular(7)),
                    child:
                        const Icon(Icons.apps, color: Colors.white, size: 17),
                  ),
                  const SizedBox(width: 10),
                  Text('CCP App',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800])),
                ]),
                const SizedBox(height: 12),
                Text(step.dialogTitle,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111111),
                        height: 1.4)),
              ],
            ),
          ),
          const Divider(height: 0.5, thickness: 0.5),
          ...step.dialogOptions.asMap().entries.map((e) => _OptionRow(
              option: e.value, isLast: e.key == step.dialogOptions.length - 1)),
        ],
      ),
    );
  }
}

// ─── Option row with animated hand ────────────────────────────────────────────

class _OptionRow extends StatefulWidget {
  final _DialogOption option;
  final bool isLast;
  const _OptionRow({required this.option, required this.isLast});

  @override
  State<_OptionRow> createState() => _OptionRowState();
}

class _OptionRowState extends State<_OptionRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _moveY;
  late final Animation<double> _scale;
  late final Animation<double> _ripple;

  @override
  void initState() {
    super.initState();
    if (!widget.option.isTarget) return;

    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800));

    _moveY = TweenSequence([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 10.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 18),
      TweenSequenceItem(
          tween: Tween(begin: 10.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 18),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 64),
    ]).animate(_ctrl);

    _scale = TweenSequence([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.85)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 18),
      TweenSequenceItem(
          tween: Tween(begin: 0.85, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 18),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 64),
    ]).animate(_ctrl);

    _ripple = TweenSequence([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 12),
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 28),
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 20),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 40),
    ]).animate(_ctrl);

    _ctrl.repeat();
  }

  @override
  void dispose() {
    if (widget.option.isTarget) _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final opt = widget.option;
    return Column(
      children: [
        Container(
          color: opt.isTarget
              ? Colors.green.withOpacity(0.07)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: opt.isTarget ? Colors.green : Colors.grey[400]!,
                    width: opt.isTarget ? 2 : 1.5,
                  ),
                  color: opt.isTarget
                      ? Colors.green.withOpacity(0.1)
                      : Colors.transparent,
                ),
                child: opt.isTarget
                    ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle, color: Colors.green),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(opt.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: opt.isTarget
                          ? const Color(0xFF1B5E20)
                          : const Color(0xFF111111),
                      fontWeight:
                          opt.isTarget ? FontWeight.w600 : FontWeight.normal,
                    )),
              ),
              if (opt.isTarget) ...[
                const SizedBox(width: 6),
                AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, __) => SizedBox(
                    width: 38,
                    height: 42,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Opacity(
                          opacity: _ripple.value * 0.3,
                          child: Container(
                            width: 30 + (_ripple.value * 10),
                            height: 30 + (_ripple.value * 10),
                            decoration: const BoxDecoration(
                                shape: BoxShape.circle, color: Colors.green),
                          ),
                        ),
                        Transform.translate(
                          offset: Offset(0, _moveY.value),
                          child: Transform.scale(
                            scale: _scale.value,
                            child: const Text('👆',
                                style: TextStyle(fontSize: 22)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (!widget.isLast)
          Divider(
              height: 0.5, thickness: 0.5, color: Colors.grey[200], indent: 20),
      ],
    );
  }
}

// ─── Data classes ──────────────────────────────────────────────────────────────

class _PermStep {
  final Permission permission;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String why;
  final String dialogTitle;
  final List<_DialogOption> dialogOptions;
  final String? note;
  final bool isBatteryStep;

  const _PermStep({
    required this.permission,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.why,
    required this.dialogTitle,
    required this.dialogOptions,
    this.note,
    this.isBatteryStep = false,
  });
}

class _DialogOption {
  final String text;
  final bool isTarget;
  const _DialogOption(this.text, {this.isTarget = false});
}
