// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_device_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RegisterDeviceModelImpl _$$RegisterDeviceModelImplFromJson(
        Map<String, dynamic> json) =>
    _$RegisterDeviceModelImpl(
      deviceUuid: json['device_uuid'] as String,
      token: json['token'] as String,
      locationPingStartTime: json['location_ping_start_time'] as String,
      locationPingEndTime: json['location_ping_end_time'] as String,
      locationPingInterval: (json['location_ping_interval'] as num).toInt(),
      user: json['user'] as String,
      employeeId: json['employee_id'] as String,
    );

Map<String, dynamic> _$$RegisterDeviceModelImplToJson(
        _$RegisterDeviceModelImpl instance) =>
    <String, dynamic>{
      'device_uuid': instance.deviceUuid,
      'token': instance.token,
      'location_ping_start_time': instance.locationPingStartTime,
      'location_ping_end_time': instance.locationPingEndTime,
      'location_ping_interval': instance.locationPingInterval,
      'user': instance.user,
      'employee_id': instance.employeeId,
    };
