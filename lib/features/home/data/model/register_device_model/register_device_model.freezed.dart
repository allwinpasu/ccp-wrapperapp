// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'register_device_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

RegisterDeviceModel _$RegisterDeviceModelFromJson(Map<String, dynamic> json) {
  return _RegisterDeviceModel.fromJson(json);
}

/// @nodoc
mixin _$RegisterDeviceModel {
  @JsonKey(name: 'device_uuid')
  String get deviceUuid => throw _privateConstructorUsedError;
  @JsonKey(name: 'token')
  String get token => throw _privateConstructorUsedError;
  @JsonKey(name: 'location_ping_start_time')
  String get locationPingStartTime => throw _privateConstructorUsedError;
  @JsonKey(name: 'location_ping_end_time')
  String get locationPingEndTime => throw _privateConstructorUsedError;
  @JsonKey(name: 'location_ping_interval')
  int get locationPingInterval => throw _privateConstructorUsedError;
  @JsonKey(name: 'user')
  String get user => throw _privateConstructorUsedError;
  @JsonKey(name: 'employee_id')
  String get employeeId => throw _privateConstructorUsedError;

  /// Serializes this RegisterDeviceModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RegisterDeviceModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RegisterDeviceModelCopyWith<RegisterDeviceModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RegisterDeviceModelCopyWith<$Res> {
  factory $RegisterDeviceModelCopyWith(
          RegisterDeviceModel value, $Res Function(RegisterDeviceModel) then) =
      _$RegisterDeviceModelCopyWithImpl<$Res, RegisterDeviceModel>;
  @useResult
  $Res call(
      {@JsonKey(name: 'device_uuid') String deviceUuid,
      @JsonKey(name: 'token') String token,
      @JsonKey(name: 'location_ping_start_time') String locationPingStartTime,
      @JsonKey(name: 'location_ping_end_time') String locationPingEndTime,
      @JsonKey(name: 'location_ping_interval') int locationPingInterval,
      @JsonKey(name: 'user') String user,
      @JsonKey(name: 'employee_id') String employeeId});
}

/// @nodoc
class _$RegisterDeviceModelCopyWithImpl<$Res, $Val extends RegisterDeviceModel>
    implements $RegisterDeviceModelCopyWith<$Res> {
  _$RegisterDeviceModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RegisterDeviceModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? deviceUuid = null,
    Object? token = null,
    Object? locationPingStartTime = null,
    Object? locationPingEndTime = null,
    Object? locationPingInterval = null,
    Object? user = null,
    Object? employeeId = null,
  }) {
    return _then(_value.copyWith(
      deviceUuid: null == deviceUuid
          ? _value.deviceUuid
          : deviceUuid // ignore: cast_nullable_to_non_nullable
              as String,
      token: null == token
          ? _value.token
          : token // ignore: cast_nullable_to_non_nullable
              as String,
      locationPingStartTime: null == locationPingStartTime
          ? _value.locationPingStartTime
          : locationPingStartTime // ignore: cast_nullable_to_non_nullable
              as String,
      locationPingEndTime: null == locationPingEndTime
          ? _value.locationPingEndTime
          : locationPingEndTime // ignore: cast_nullable_to_non_nullable
              as String,
      locationPingInterval: null == locationPingInterval
          ? _value.locationPingInterval
          : locationPingInterval // ignore: cast_nullable_to_non_nullable
              as int,
      user: null == user
          ? _value.user
          : user // ignore: cast_nullable_to_non_nullable
              as String,
      employeeId: null == employeeId
          ? _value.employeeId
          : employeeId // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RegisterDeviceModelImplCopyWith<$Res>
    implements $RegisterDeviceModelCopyWith<$Res> {
  factory _$$RegisterDeviceModelImplCopyWith(_$RegisterDeviceModelImpl value,
          $Res Function(_$RegisterDeviceModelImpl) then) =
      __$$RegisterDeviceModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'device_uuid') String deviceUuid,
      @JsonKey(name: 'token') String token,
      @JsonKey(name: 'location_ping_start_time') String locationPingStartTime,
      @JsonKey(name: 'location_ping_end_time') String locationPingEndTime,
      @JsonKey(name: 'location_ping_interval') int locationPingInterval,
      @JsonKey(name: 'user') String user,
      @JsonKey(name: 'employee_id') String employeeId});
}

/// @nodoc
class __$$RegisterDeviceModelImplCopyWithImpl<$Res>
    extends _$RegisterDeviceModelCopyWithImpl<$Res, _$RegisterDeviceModelImpl>
    implements _$$RegisterDeviceModelImplCopyWith<$Res> {
  __$$RegisterDeviceModelImplCopyWithImpl(_$RegisterDeviceModelImpl _value,
      $Res Function(_$RegisterDeviceModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of RegisterDeviceModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? deviceUuid = null,
    Object? token = null,
    Object? locationPingStartTime = null,
    Object? locationPingEndTime = null,
    Object? locationPingInterval = null,
    Object? user = null,
    Object? employeeId = null,
  }) {
    return _then(_$RegisterDeviceModelImpl(
      deviceUuid: null == deviceUuid
          ? _value.deviceUuid
          : deviceUuid // ignore: cast_nullable_to_non_nullable
              as String,
      token: null == token
          ? _value.token
          : token // ignore: cast_nullable_to_non_nullable
              as String,
      locationPingStartTime: null == locationPingStartTime
          ? _value.locationPingStartTime
          : locationPingStartTime // ignore: cast_nullable_to_non_nullable
              as String,
      locationPingEndTime: null == locationPingEndTime
          ? _value.locationPingEndTime
          : locationPingEndTime // ignore: cast_nullable_to_non_nullable
              as String,
      locationPingInterval: null == locationPingInterval
          ? _value.locationPingInterval
          : locationPingInterval // ignore: cast_nullable_to_non_nullable
              as int,
      user: null == user
          ? _value.user
          : user // ignore: cast_nullable_to_non_nullable
              as String,
      employeeId: null == employeeId
          ? _value.employeeId
          : employeeId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RegisterDeviceModelImpl implements _RegisterDeviceModel {
  const _$RegisterDeviceModelImpl(
      {@JsonKey(name: 'device_uuid') required this.deviceUuid,
      @JsonKey(name: 'token') required this.token,
      @JsonKey(name: 'location_ping_start_time')
      required this.locationPingStartTime,
      @JsonKey(name: 'location_ping_end_time')
      required this.locationPingEndTime,
      @JsonKey(name: 'location_ping_interval')
      required this.locationPingInterval,
      @JsonKey(name: 'user') required this.user,
      @JsonKey(name: 'employee_id') required this.employeeId});

  factory _$RegisterDeviceModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$RegisterDeviceModelImplFromJson(json);

  @override
  @JsonKey(name: 'device_uuid')
  final String deviceUuid;
  @override
  @JsonKey(name: 'token')
  final String token;
  @override
  @JsonKey(name: 'location_ping_start_time')
  final String locationPingStartTime;
  @override
  @JsonKey(name: 'location_ping_end_time')
  final String locationPingEndTime;
  @override
  @JsonKey(name: 'location_ping_interval')
  final int locationPingInterval;
  @override
  @JsonKey(name: 'user')
  final String user;
  @override
  @JsonKey(name: 'employee_id')
  final String employeeId;

  @override
  String toString() {
    return 'RegisterDeviceModel(deviceUuid: $deviceUuid, token: $token, locationPingStartTime: $locationPingStartTime, locationPingEndTime: $locationPingEndTime, locationPingInterval: $locationPingInterval, user: $user, employeeId: $employeeId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RegisterDeviceModelImpl &&
            (identical(other.deviceUuid, deviceUuid) ||
                other.deviceUuid == deviceUuid) &&
            (identical(other.token, token) || other.token == token) &&
            (identical(other.locationPingStartTime, locationPingStartTime) ||
                other.locationPingStartTime == locationPingStartTime) &&
            (identical(other.locationPingEndTime, locationPingEndTime) ||
                other.locationPingEndTime == locationPingEndTime) &&
            (identical(other.locationPingInterval, locationPingInterval) ||
                other.locationPingInterval == locationPingInterval) &&
            (identical(other.user, user) || other.user == user) &&
            (identical(other.employeeId, employeeId) ||
                other.employeeId == employeeId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      deviceUuid,
      token,
      locationPingStartTime,
      locationPingEndTime,
      locationPingInterval,
      user,
      employeeId);

  /// Create a copy of RegisterDeviceModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RegisterDeviceModelImplCopyWith<_$RegisterDeviceModelImpl> get copyWith =>
      __$$RegisterDeviceModelImplCopyWithImpl<_$RegisterDeviceModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RegisterDeviceModelImplToJson(
      this,
    );
  }
}

abstract class _RegisterDeviceModel implements RegisterDeviceModel {
  const factory _RegisterDeviceModel(
          {@JsonKey(name: 'device_uuid') required final String deviceUuid,
          @JsonKey(name: 'token') required final String token,
          @JsonKey(name: 'location_ping_start_time')
          required final String locationPingStartTime,
          @JsonKey(name: 'location_ping_end_time')
          required final String locationPingEndTime,
          @JsonKey(name: 'location_ping_interval')
          required final int locationPingInterval,
          @JsonKey(name: 'user') required final String user,
          @JsonKey(name: 'employee_id') required final String employeeId}) =
      _$RegisterDeviceModelImpl;

  factory _RegisterDeviceModel.fromJson(Map<String, dynamic> json) =
      _$RegisterDeviceModelImpl.fromJson;

  @override
  @JsonKey(name: 'device_uuid')
  String get deviceUuid;
  @override
  @JsonKey(name: 'token')
  String get token;
  @override
  @JsonKey(name: 'location_ping_start_time')
  String get locationPingStartTime;
  @override
  @JsonKey(name: 'location_ping_end_time')
  String get locationPingEndTime;
  @override
  @JsonKey(name: 'location_ping_interval')
  int get locationPingInterval;
  @override
  @JsonKey(name: 'user')
  String get user;
  @override
  @JsonKey(name: 'employee_id')
  String get employeeId;

  /// Create a copy of RegisterDeviceModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RegisterDeviceModelImplCopyWith<_$RegisterDeviceModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
