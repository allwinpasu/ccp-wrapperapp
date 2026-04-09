// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'url_shortcut.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

UrlShortcut _$UrlShortcutFromJson(Map<String, dynamic> json) {
  return _UrlShortcut.fromJson(json);
}

/// @nodoc
mixin _$UrlShortcut {
  String get id => throw _privateConstructorUsedError;
  String get url => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  String? get faviconUrl => throw _privateConstructorUsedError;

  /// Serializes this UrlShortcut to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UrlShortcut
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UrlShortcutCopyWith<UrlShortcut> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UrlShortcutCopyWith<$Res> {
  factory $UrlShortcutCopyWith(
          UrlShortcut value, $Res Function(UrlShortcut) then) =
      _$UrlShortcutCopyWithImpl<$Res, UrlShortcut>;
  @useResult
  $Res call(
      {String id,
      String url,
      String title,
      DateTime createdAt,
      String? faviconUrl});
}

/// @nodoc
class _$UrlShortcutCopyWithImpl<$Res, $Val extends UrlShortcut>
    implements $UrlShortcutCopyWith<$Res> {
  _$UrlShortcutCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UrlShortcut
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? url = null,
    Object? title = null,
    Object? createdAt = null,
    Object? faviconUrl = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      url: null == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      faviconUrl: freezed == faviconUrl
          ? _value.faviconUrl
          : faviconUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UrlShortcutImplCopyWith<$Res>
    implements $UrlShortcutCopyWith<$Res> {
  factory _$$UrlShortcutImplCopyWith(
          _$UrlShortcutImpl value, $Res Function(_$UrlShortcutImpl) then) =
      __$$UrlShortcutImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String url,
      String title,
      DateTime createdAt,
      String? faviconUrl});
}

/// @nodoc
class __$$UrlShortcutImplCopyWithImpl<$Res>
    extends _$UrlShortcutCopyWithImpl<$Res, _$UrlShortcutImpl>
    implements _$$UrlShortcutImplCopyWith<$Res> {
  __$$UrlShortcutImplCopyWithImpl(
      _$UrlShortcutImpl _value, $Res Function(_$UrlShortcutImpl) _then)
      : super(_value, _then);

  /// Create a copy of UrlShortcut
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? url = null,
    Object? title = null,
    Object? createdAt = null,
    Object? faviconUrl = freezed,
  }) {
    return _then(_$UrlShortcutImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      url: null == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      faviconUrl: freezed == faviconUrl
          ? _value.faviconUrl
          : faviconUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UrlShortcutImpl implements _UrlShortcut {
  const _$UrlShortcutImpl(
      {required this.id,
      required this.url,
      required this.title,
      required this.createdAt,
      this.faviconUrl});

  factory _$UrlShortcutImpl.fromJson(Map<String, dynamic> json) =>
      _$$UrlShortcutImplFromJson(json);

  @override
  final String id;
  @override
  final String url;
  @override
  final String title;
  @override
  final DateTime createdAt;
  @override
  final String? faviconUrl;

  @override
  String toString() {
    return 'UrlShortcut(id: $id, url: $url, title: $title, createdAt: $createdAt, faviconUrl: $faviconUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UrlShortcutImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.faviconUrl, faviconUrl) ||
                other.faviconUrl == faviconUrl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, url, title, createdAt, faviconUrl);

  /// Create a copy of UrlShortcut
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UrlShortcutImplCopyWith<_$UrlShortcutImpl> get copyWith =>
      __$$UrlShortcutImplCopyWithImpl<_$UrlShortcutImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UrlShortcutImplToJson(
      this,
    );
  }
}

abstract class _UrlShortcut implements UrlShortcut {
  const factory _UrlShortcut(
      {required final String id,
      required final String url,
      required final String title,
      required final DateTime createdAt,
      final String? faviconUrl}) = _$UrlShortcutImpl;

  factory _UrlShortcut.fromJson(Map<String, dynamic> json) =
      _$UrlShortcutImpl.fromJson;

  @override
  String get id;
  @override
  String get url;
  @override
  String get title;
  @override
  DateTime get createdAt;
  @override
  String? get faviconUrl;

  /// Create a copy of UrlShortcut
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UrlShortcutImplCopyWith<_$UrlShortcutImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
