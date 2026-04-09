// lib/features/permissions/presentation/pages/permission_request_screen.dart
import 'dart:io';
import 'package:ccp_app/services/permission_service.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionRequestScreen extends StatefulWidget {
  final VoidCallback onPermissionsGranted;

  const PermissionRequestScreen({
    super.key,
    required this.onPermissionsGranted,
  });

  @override
  State<PermissionRequestScreen> createState() =>
      _PermissionRequestScreenState();
}

class _PermissionRequestScreenState extends State<PermissionRequestScreen>
    with WidgetsBindingObserver {
  final _service = PermissionService();

  bool _isRequesting = false;
  bool _hasRequestedOnce = false;
  List<Permission> _missing = [];
  bool _checkedOnce = false;

  @override
  void initState() {
    super.initState();
    // Listen for app resume — user may return from system settings
    WidgetsBinding.instance.addObserver(this);
    _checkStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Auto re-check when user comes back from system settings
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkStatus();
    }
  }

  Future<void> _checkStatus() async {
    final missing = await _service.getMissing();
    if (!mounted) return;

    if (missing.isEmpty) {
      widget.onPermissionsGranted();
      return;
    }

    setState(() {
      _missing = missing;
      _checkedOnce = true; // ← flip here
    });
  }

  Future<void> _requestPermissions() async {
    if (_isRequesting) return;
    setState(() {
      _isRequesting = true;
      _hasRequestedOnce = true;
    });

    try {
      await _service.requestMissing();
    } finally {
      if (mounted) setState(() => _isRequesting = false);
    }

    final missing = await _service.getMissing();
    if (!mounted) return;

    if (missing.isEmpty) {
      widget.onPermissionsGranted();
      return;
    }

    setState(() => _missing = missing);

    final permanentlyDenied = await _service.anyPermanentlyDenied();
    if (!mounted) return;

    if (permanentlyDenied) {
      _showSettingsDialog(missing);
    } else {
      _showMissingDialog(missing);
    }
  }

  // ─── Dialogs ───────────────────────────────────────────────────────────────

  /// Shown when permissions are denied but not permanently —
  /// user can try granting again.
  void _showMissingDialog(List<Permission> missing) {
    final names = missing.map((p) => '• ${_service.displayName(p)}').join('\n');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange),
          SizedBox(width: 8),
          Text('Permissions Required'),
        ]),
        content: Text(
          'The following permissions must be granted to use this app:\n\n'
          '$names\n\n'
          'Please allow all permissions to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _exitApp();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Exit App'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _requestPermissions();
            },
            child: const Text('Grant Now'),
          ),
        ],
      ),
    );
  }

  /// Shown when one or more permissions are permanently denied —
  /// user must go to system settings to fix.
  void _showSettingsDialog(List<Permission> missing) {
    final names = missing.map((p) => '• ${_service.displayName(p)}').join('\n');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.settings, color: Colors.orange),
          SizedBox(width: 8),
          Text('Open App Settings'),
        ]),
        content: Text(
          'The following permissions were permanently denied:\n\n'
          '$names\n\n'
          'Please enable them in App Settings to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _exitApp();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Exit App'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              await openAppSettings();
              // didChangeAppLifecycleState will re-check when user returns
            },
            icon: const Icon(Icons.settings, size: 16),
            label: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showExitConfirm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit App?'),
        content: const Text(
          'All permissions are required for this app to function. '
          'Are you sure you want to exit?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
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

  void _exitApp() => exit(0);

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // block back button
      onPopInvoked: (_) => _showExitConfirm(),
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 48),

                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(Icons.security,
                      size: 48, color: Theme.of(context).primaryColor),
                ),

                const SizedBox(height: 24),

                Text(
                  'App Permissions',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                Text(
                  'All permissions below are required. '
                  'You cannot use the app without granting all of them.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 28),

                // Permission list
                Expanded(
                  child: ListView.separated(
                    itemCount: _service.requiredPermissions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final p = _service.requiredPermissions[index];
                      final isMissing = _missing.contains(p);

                      _TileStatus tileStatus;
                      if (!_checkedOnce) {
                        tileStatus =
                            _TileStatus.pending; // spinner still loading
                      } else if (isMissing) {
                        tileStatus = _TileStatus.denied;
                      } else {
                        tileStatus = _TileStatus.granted;
                      }

                      return _PermissionTile(
                        icon: _service.permissionIcon(p),
                        color: _service.permissionColor(p),
                        title: _service.displayName(p),
                        description: _service.permissionDescription(p),
                        status: tileStatus,
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Info banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: Colors.orange, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _hasRequestedOnce && _missing.isNotEmpty
                              ? '${_missing.length} permission(s) still missing. '
                                  'Tap "Grant Permissions" to try again.'
                              : 'Tap "Grant Permissions" and allow each '
                                  'permission when prompted by the system.',
                          style: TextStyle(
                              fontSize: 12, color: Colors.orange[900]),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Buttons — only Exit or Grant, no skip
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isRequesting ? null : _showExitConfirm,
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
                        onPressed: _isRequesting ? null : _requestPermissions,
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
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                _hasRequestedOnce && _missing.isNotEmpty
                                    ? 'Grant Missing (${_missing.length})'
                                    : 'Grant Permissions',
                              ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Permission tile widget ───────────────────────────────────────────────────

enum _TileStatus { pending, granted, denied }

class _PermissionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final _TileStatus status;

  const _PermissionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final Color borderColor;
    final Widget trailing;

    switch (status) {
      case _TileStatus.granted:
        borderColor = Colors.green.withOpacity(0.4);
        trailing =
            const Icon(Icons.check_circle, color: Colors.green, size: 22);
        break;
      case _TileStatus.denied:
        borderColor = Colors.red.withOpacity(0.4);
        trailing = const Icon(Icons.cancel, color: Colors.red, size: 22);
        break;
      case _TileStatus.pending:
        borderColor = color.withOpacity(0.25);
        trailing = Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'REQUIRED',
            style: TextStyle(
                fontSize: 9, fontWeight: FontWeight.bold, color: Colors.red),
          ),
        );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}
