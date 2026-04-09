// To parse this JSON data, do
//
//     final registerDeviceModel = registerDeviceModelFromJson(jsonString);

import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:convert';

part 'register_device_model.freezed.dart';
part 'register_device_model.g.dart';

RegisterDeviceModel registerDeviceModelFromJson(String str) =>
    RegisterDeviceModel.fromJson(json.decode(str));

String registerDeviceModelToJson(RegisterDeviceModel data) =>
    json.encode(data.toJson());

@freezed
class RegisterDeviceModel with _$RegisterDeviceModel {
  const factory RegisterDeviceModel({
    @JsonKey(name: 'device_uuid') required String deviceUuid,
    @JsonKey(name: 'token') required String token,
    @JsonKey(name: 'location_ping_start_time')
    required String locationPingStartTime,
    @JsonKey(name: 'location_ping_end_time')
    required String locationPingEndTime,
    @JsonKey(name: 'location_ping_interval') required int locationPingInterval,
    @JsonKey(name: 'user') required String user,
    @JsonKey(name: 'employee_id') required String employeeId,
  }) = _RegisterDeviceModel;

  factory RegisterDeviceModel.fromJson(Map<String, dynamic> json) =>
      _$RegisterDeviceModelFromJson(json);
}
