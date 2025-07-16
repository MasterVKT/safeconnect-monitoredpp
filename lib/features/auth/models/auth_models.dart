import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:monitored_app/core/models/user.dart';

part 'auth_models.freezed.dart';
part 'auth_models.g.dart';

@freezed
class AuthResponse with _$AuthResponse {
  const factory AuthResponse({
    required String access,
    required String refresh,
    required User user,
  }) = _AuthResponse;

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);
}

@freezed
class SignInParams with _$SignInParams {
  const factory SignInParams({
    required String email,
    required String password,
  }) = _SignInParams;

  factory SignInParams.fromJson(Map<String, dynamic> json) =>
      _$SignInParamsFromJson(json);
}

@freezed
class PairingParams with _$PairingParams {
  const factory PairingParams({
    required String pairingCode,
    required Map<String, dynamic> deviceInfo,
  }) = _PairingParams;

  factory PairingParams.fromJson(Map<String, dynamic> json) =>
      _$PairingParamsFromJson(json);
}

@freezed
class AuthResult with _$AuthResult {
  const factory AuthResult.success(User? user) = _Success;
  const factory AuthResult.error({required String message, String? errorCode}) =
      _Error;
}