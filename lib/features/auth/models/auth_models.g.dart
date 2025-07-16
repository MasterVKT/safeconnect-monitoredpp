// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AuthResponseImpl _$$AuthResponseImplFromJson(Map<String, dynamic> json) =>
    _$AuthResponseImpl(
      access: json['access'] as String,
      refresh: json['refresh'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$AuthResponseImplToJson(_$AuthResponseImpl instance) =>
    <String, dynamic>{
      'access': instance.access,
      'refresh': instance.refresh,
      'user': instance.user,
    };

_$SignInParamsImpl _$$SignInParamsImplFromJson(Map<String, dynamic> json) =>
    _$SignInParamsImpl(
      email: json['email'] as String,
      password: json['password'] as String,
    );

Map<String, dynamic> _$$SignInParamsImplToJson(_$SignInParamsImpl instance) =>
    <String, dynamic>{
      'email': instance.email,
      'password': instance.password,
    };

_$PairingParamsImpl _$$PairingParamsImplFromJson(Map<String, dynamic> json) =>
    _$PairingParamsImpl(
      pairingCode: json['pairingCode'] as String,
      deviceInfo: json['deviceInfo'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$$PairingParamsImplToJson(_$PairingParamsImpl instance) =>
    <String, dynamic>{
      'pairingCode': instance.pairingCode,
      'deviceInfo': instance.deviceInfo,
    };
