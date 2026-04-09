// lib/core/services/url_shortcut_service.dart
import 'dart:convert';
import 'package:ccp_app/features/home/data/model/url_shortcut/url_shortcut.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UrlShortcutService {
  final SharedPreferences _prefs;
  static const String _shortcutsKey = 'url_shortcuts';

  UrlShortcutService(this._prefs);

  Future<List<UrlShortcut>> getShortcuts() async {
    try {
      final String? jsonString = _prefs.getString(_shortcutsKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => UrlShortcut.fromJson(json)).toList();
    } catch (e) {
      print('Error getting shortcuts: $e');
      return [];
    }
  }

  Future<bool> addShortcut(String url, String title) async {
    try {
      print('UrlShortcutService: Adding shortcut - $title ($url)');

      // Get existing shortcuts
      final shortcuts = await getShortcuts();
      print(
          'UrlShortcutService: Existing shortcuts count: ${shortcuts.length}');

      // Check if URL already exists
      final exists = shortcuts.any((shortcut) => shortcut.url == url);
      if (exists) {
        print('UrlShortcutService: Shortcut already exists');
        return false; // Don't add duplicate
      }

      final shortcut = UrlShortcut(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        url: url,
        title: title,
        createdAt: DateTime.now(),
      );

      shortcuts.add(shortcut);
      print(
          'UrlShortcutService: Added shortcut. New count: ${shortcuts.length}');

      // Save to SharedPreferences
      final jsonList = shortcuts.map((s) => s.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      final saved = await _prefs.setString(_shortcutsKey, jsonString);

      print('UrlShortcutService: Saved to SharedPreferences: $saved');
      return saved;
    } catch (e) {
      print('UrlShortcutService: Error adding shortcut: $e');
      return false;
    }
  }

  Future<bool> removeShortcut(String id) async {
    try {
      final shortcuts = await getShortcuts();
      shortcuts.removeWhere((shortcut) => shortcut.id == id);

      final jsonList = shortcuts.map((s) => s.toJson()).toList();
      return await _prefs.setString(_shortcutsKey, jsonEncode(jsonList));
    } catch (e) {
      print('Error removing shortcut: $e');
      return false;
    }
  }

  Future<bool> clearAll() async {
    try {
      return await _prefs.remove(_shortcutsKey);
    } catch (e) {
      print('Error clearing shortcuts: $e');
      return false;
    }
  }
}
