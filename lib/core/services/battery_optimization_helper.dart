// lib/core/services/battery_optimization_helper.dart
import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum _Brand {
  xiaomi,
  samsung,
  oneplus,
  oppo,
  vivo,
  realme,
  huawei,
  honor,
  other
}

class BatteryOptimizationHelper {
  static const _kShownKey = 'battery_dialog_shown';

  static _Brand _detect(String manufacturer, String model) {
    final m = manufacturer.toLowerCase();
    final d = model.toLowerCase();
    if (m.contains('xiaomi') || m.contains('redmi') || d.contains('poco')) {
      return _Brand.xiaomi;
    }
    if (m.contains('samsung')) return _Brand.samsung;
    if (m.contains('oneplus') || d.contains('oneplus')) return _Brand.oneplus;
    if (m.contains('oppo')) return _Brand.oppo;
    if (m.contains('vivo')) return _Brand.vivo;
    if (m.contains('realme')) return _Brand.realme;
    if (m.contains('huawei')) return _Brand.huawei;
    if (m.contains('honor')) return _Brand.honor;
    return _Brand.other;
  }

  /// Call after device registration succeeds — shows once per install.
  static Future<void> checkAndShow(
    BuildContext context, {
    required String manufacturer,
    required String model,
  }) async {
    if (!Platform.isAndroid) return;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kShownKey) ?? false) return;
    if (!context.mounted) return;

    final brand = _detect(manufacturer, model);
    final config = _getConfig(brand);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.battery_alert, color: Colors.orange),
          SizedBox(width: 8),
          Flexible(
            child: Text('Enable Background Access',
                style: TextStyle(fontSize: 16)),
          ),
        ]),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To keep location tracking active when the app is closed, '
                'please adjust these settings on your device:',
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),
              ...config.steps.asMap().entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _StepRow(
                        number: '${e.key + 1}',
                        title: e.value.title,
                        path: e.value.path,
                      ),
                    ),
                  ),
              if (config.note != null) ...[
                const SizedBox(height: 4),
                Text(config.note!,
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              prefs.setBool(_kShownKey, true);
            },
            child: const Text('Later'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              await prefs.setBool(_kShownKey, true);
              await _openSettings(brand);
            },
            icon: const Icon(Icons.settings, size: 16),
            label: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  // ─── Brand config ──────────────────────────────────────────────────────────

  static _BrandConfig _getConfig(_Brand brand) {
    switch (brand) {
      case _Brand.xiaomi:
        return _BrandConfig(
          steps: [
            _Step('No restrictions (Battery)',
                'Settings → Apps → CCP App → Battery saver → No restrictions'),
            _Step('Enable Autostart',
                'Settings → Apps → Manage apps → CCP App → Enable Autostart'),
          ],
          note: 'Both settings are required on MIUI/HyperOS devices.',
        );
      case _Brand.samsung:
        return _BrandConfig(
          steps: [
            _Step('Unrestricted battery usage',
                'Settings → Apps → CCP App → Battery → Unrestricted'),
          ],
          note: "Samsung Adaptive Battery may pause background apps.",
        );
      case _Brand.oneplus:
        return _BrandConfig(
          steps: [
            _Step("Don't optimize",
                'Settings → Battery → Battery Optimization → CCP App → Don\'t optimize'),
          ],
          note: 'OxygenOS battery saver can block background tracking.',
        );
      case _Brand.oppo:
        return _BrandConfig(
          steps: [
            _Step('Remove power protection',
                'Settings → Battery → Power Consumption Protection → CCP App → Off'),
            _Step('Allow background activity',
                'Settings → Apps → CCP App → Battery → Allow background activity'),
          ],
          note: 'ColorOS restricts background processes aggressively.',
        );
      case _Brand.vivo:
        return _BrandConfig(
          steps: [
            _Step('High background power',
                'Settings → Battery → High Background Power → Add CCP App'),
            _Step('Background app refresh',
                'Settings → Apps → CCP App → Background App Refresh → On'),
          ],
          note: 'Funtouch OS restricts background apps by default.',
        );
      case _Brand.realme:
        return _BrandConfig(
          steps: [
            _Step("Don't optimize",
                'Settings → Battery → Battery Optimization → CCP App → Don\'t optimize'),
          ],
          note: 'Realme UI (ColorOS-based) limits background apps.',
        );
      case _Brand.huawei:
        return _BrandConfig(
          steps: [
            _Step('Manage app launch',
                'Settings → Apps → App Launch → CCP App → Manage manually → Enable all'),
            _Step('Battery optimization off',
                'Settings → Battery → Battery Optimization → CCP App → Don\'t optimize'),
          ],
          note: 'EMUI/HarmonyOS has strict background process controls.',
        );
      case _Brand.honor:
        return _BrandConfig(
          steps: [
            _Step('Allow auto-launch',
                'Settings → Apps → App Launch → CCP App → Enable Auto-launch'),
          ],
        );
      case _Brand.other:
        return _BrandConfig(
          steps: [
            _Step('Disable battery optimization',
                'Settings → Battery → Battery Optimization → CCP App → Don\'t optimize'),
          ],
          note: 'This lets the app track location reliably in the background.',
        );
    }
  }

  // ─── Open settings ─────────────────────────────────────────────────────────

  static Future<void> _openSettings(_Brand brand) async {
    switch (brand) {
      case _Brand.xiaomi:
        await _tryLaunch(
          package: 'com.miui.securitycenter',
          componentName:
              'com.miui.securitycenter/com.miui.permcenter.autostart.AutoStartManagementActivity',
        );
        break;
      case _Brand.huawei:
        await _tryLaunch(
          package: 'com.huawei.systemmanager',
          componentName:
              'com.huawei.systemmanager/com.huawei.systemmanager.appcontrol.activity.StartupAppControlActivity',
        );
        break;
      default:
        await _tryLaunch(
          action: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
        );
        break;
    }
  }

  /// Tries to launch an intent, falls back to standard battery settings on failure.
  static Future<void> _tryLaunch({
    String action = 'android.intent.action.MAIN',
    String? package,
    String? componentName,
  }) async {
    try {
      final intent = AndroidIntent(
        action: action,
        package: package,
        componentName: componentName,
        flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      await intent.launch();
    } catch (e) {
      debugPrint('Intent launch failed ($componentName): $e');
      // Fallback to standard Android battery optimization settings
      if (action != 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS') {
        try {
          final fallback = AndroidIntent(
            action: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
            flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
          );
          await fallback.launch();
        } catch (e2) {
          debugPrint('Fallback intent also failed: $e2');
        }
      }
    }
  }
}

// ─── Data classes ─────────────────────────────────────────────────────────────

class _Step {
  final String title;
  final String path;
  const _Step(this.title, this.path);
}

class _BrandConfig {
  final List<_Step> steps;
  final String? note;
  const _BrandConfig({required this.steps, this.note});
}

// ─── UI widget ────────────────────────────────────────────────────────────────

class _StepRow extends StatelessWidget {
  final String number;
  final String title;
  final String path;

  const _StepRow({
    required this.number,
    required this.title,
    required this.path,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: Colors.orange,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 2),
              Text(path,
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }
}
