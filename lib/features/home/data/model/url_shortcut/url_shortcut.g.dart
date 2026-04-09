// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'url_shortcut.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UrlShortcutImpl _$$UrlShortcutImplFromJson(Map<String, dynamic> json) =>
    _$UrlShortcutImpl(
      id: json['id'] as String,
      url: json['url'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      faviconUrl: json['faviconUrl'] as String?,
    );

Map<String, dynamic> _$$UrlShortcutImplToJson(_$UrlShortcutImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'url': instance.url,
      'title': instance.title,
      'createdAt': instance.createdAt.toIso8601String(),
      'faviconUrl': instance.faviconUrl,
    };
