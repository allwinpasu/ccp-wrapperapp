// lib/services/permission_service.dart
//
// Single source of truth for PermissionService.
// ⚠️  Delete lib/services/permission_service_simple.dart from your project —
//     having two files with the same class name causes conflicts.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// ALL of these are mandatory — user cannot proceed without granting all.
  List<Permission> get requiredPermissions => [
        Permission.location,
        Permission.locationAlways,
        Permission.camera,
        if (Platform.isAndroid) Permission.notification,
        if (Platform.isAndroid) Permission.ignoreBatteryOptimizations,
      ];

  // ─── Status ────────────────────────────────────────────────────────────────

  Future<bool> areAllGranted() async {
    for (final p in requiredPermissions) {
      final s = await p.status;
      if (!s.isGranted && !s.isLimited) return false;
    }
    return true;
  }

  // Aliases for any existing call sites using the old method names
  Future<bool> areAllPermissionsGranted() => areAllGranted();
  Future<bool> areEssentialPermissionsGranted() => areAllGranted();

  Future<List<Permission>> getMissing() async {
    final missing = <Permission>[];
    for (final p in requiredPermissions) {
      final s = await p.status;
      if (!s.isGranted && !s.isLimited) missing.add(p);
    }
    return missing;
  }

  Future<List<Permission>> getDeniedPermissions() => getMissing();
  Future<List<Permission>> getDeniedEssentialPermissions() => getMissing();

  Future<bool> anyPermanentlyDenied() async {
    for (final p in requiredPermissions) {
      if ((await p.status).isPermanentlyDenied) return true;
    }
    return false;
  }

  Future<bool> hasEssentialPermissionPermanentlyDenied() =>
      anyPermanentlyDenied();

  // ─── Request ───────────────────────────────────────────────────────────────

  /// Requests only the currently missing permissions in the correct order.
  /// locationAlways MUST come after location is granted — Android enforces this.
  Future<void> requestMissing() async {
    final missing = await getMissing();
    if (missing.isEmpty) return;

    // 1. Foreground location first
    if (missing.contains(Permission.location)) {
      await Permission.location.request();
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // 2. Background location — only after foreground is granted
    if (missing.contains(Permission.locationAlways)) {
      if ((await Permission.location.status).isGranted) {
        await Permission.locationAlways.request();
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    // 3. Camera
    if (missing.contains(Permission.camera)) {
      await Permission.camera.request();
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // 4. Notification
    if (missing.contains(Permission.notification)) {
      await Permission.notification.request();
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // 5. Battery optimization
    if (missing.contains(Permission.ignoreBatteryOptimizations)) {
      await Permission.ignoreBatteryOptimizations.request();
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  /// Alias for any existing call sites using requestAllPermissions()
  Future<Map<Permission, PermissionStatus>> requestAllPermissions() async {
    await requestMissing();
    return {for (final p in requiredPermissions) p: await p.status};
  }

  // ─── Display helpers ───────────────────────────────────────────────────────

  String displayName(Permission p) {
    if (p == Permission.location) return 'Location';
    if (p == Permission.locationAlways) return 'Background Location';
    if (p == Permission.camera) return 'Camera';
    if (p == Permission.notification) return 'Notifications';
    if (p == Permission.ignoreBatteryOptimizations) return 'Battery Optimization';
    return p.toString().split('.').last;
  }

  String getPermissionDisplayName(Permission p) => displayName(p);

  String permissionDescription(Permission p) {
    if (p == Permission.location) return 'Track your location for field activities';
    if (p == Permission.locationAlways) return 'Keep tracking active when app is closed';
    if (p == Permission.camera) return 'Capture photos for documents and receipts';
    if (p == Permission.notification) return 'Show location tracking status and alerts';
    if (p == Permission.ignoreBatteryOptimizations) {
      return 'Prevent OS from stopping background location tracking';
    }
    return 'Required for app functionality';
  }

  String getPermissionDescription(Permission p) => permissionDescription(p);

  IconData permissionIcon(Permission p) {
    if (p == Permission.location) return Icons.location_on;
    if (p == Permission.locationAlways) return Icons.location_searching;
    if (p == Permission.camera) return Icons.camera_alt;
    if (p == Permission.notification) return Icons.notifications;
    if (p == Permission.ignoreBatteryOptimizations) return Icons.battery_charging_full;
    return Icons.security;
  }

  Color permissionColor(Permission p) {
    if (p == Permission.location) return Colors.blue;
    if (p == Permission.locationAlways) return Colors.indigo;
    if (p == Permission.camera) return Colors.purple;
    if (p == Permission.notification) return Colors.teal;
    if (p == Permission.ignoreBatteryOptimizations) return Colors.orange;
    return Colors.grey;
  }

  bool isEssentialPermission(Permission p) => requiredPermissions.contains(p);
}