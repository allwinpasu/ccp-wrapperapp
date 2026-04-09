import 'package:freezed_annotation/freezed_annotation.dart';

part 'url_shortcut.freezed.dart';
part 'url_shortcut.g.dart';

@freezed
class UrlShortcut with _$UrlShortcut {
  const factory UrlShortcut({
    required String id,
    required String url,
    required String title,
    required DateTime createdAt,
    String? faviconUrl,
  }) = _UrlShortcut;

  factory UrlShortcut.fromJson(Map<String, dynamic> json) =>
      _$UrlShortcutFromJson(json);
}
