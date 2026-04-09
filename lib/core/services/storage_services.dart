import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Theme
  bool get isDarkTheme => _prefs?.getBool('isDarkTheme') ?? false;
  Future<void> setDarkTheme(bool isDark) async {
    await _prefs?.setBool('isDarkTheme', isDark);
  }

  // User Data
  String? get userToken => _prefs?.getString('userToken');
  Future<void> setUserToken(String token) async {
    await _prefs?.setString('userToken', token);
  }

  Future<void> clearUserData() async {
    await _prefs?.remove('userToken');
  }
}
