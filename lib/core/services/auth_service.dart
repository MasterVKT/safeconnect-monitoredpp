import 'dart:convert';

import 'package:monitored_app/app/constants.dart';
import 'package:monitored_app/core/api/api_client.dart';
import 'package:monitored_app/core/models/user.dart';
import 'package:monitored_app/core/services/storage_service.dart';
import 'package:monitored_app/features/auth/models/auth_models.dart';

class AuthService {
  final ApiClient _apiClient;
  final StorageService _storageService;
  
  AuthService(this._apiClient, this._storageService);
  
  // Pairing device
  Future<AuthResult> pairDevice(PairingParams params) async {
    try {
      final response = await _apiClient.post(
        '/devices/validate-pairing-code/',
        data: params.toJson(),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final authResponse = AuthResponse.fromJson(response.data);
        
        // Store tokens and user
        await _storeAuthData(authResponse);
        
        return AuthResult.success(authResponse.user);
      } else {
        return AuthResult.error(
          message: response.data['detail'] ?? 'Failed to pair device',
        );
      }
    } catch (e) {
      return _handleAuthError(e);
    }
  }
  
  // Logout
  Future<void> signOut() async {
    await _storageService.delete(AppConstants.tokenKey);
    await _storageService.delete(AppConstants.refreshTokenKey);
    await _storageService.delete(AppConstants.userKey);
  }
  
  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await _storageService.read(AppConstants.tokenKey);
    return token != null;
  }
  
  // Get current user
  Future<User?> getCurrentUser() async {
    final userJson = await _storageService.read(AppConstants.userKey);
    if (userJson != null) {
      return User.fromJson(jsonDecode(userJson));
    }
    return null;
  }
  
  // Get user info from server
  Future<AuthResult> fetchUserInfo() async {
    try {
      final response = await _apiClient.get('/users/me/');
      
      if (response.statusCode == 200) {
        final user = User.fromJson(response.data);
        
        // Update user info in storage
        await _storageService.write(
          AppConstants.userKey,
          jsonEncode(user.toJson()),
        );
        
        return AuthResult.success(user);
      } else {
        return AuthResult.error(
          message: response.data['detail'] ?? 'Failed to get user info',
        );
      }
    } catch (e) {
      return _handleAuthError(e);
    }
  }
  
  // Helper methods
  
  Future<void> _storeAuthData(AuthResponse authResponse) async {
    await _storageService.write(AppConstants.tokenKey, authResponse.access);
    await _storageService.write(AppConstants.refreshTokenKey, authResponse.refresh);
    await _storageService.write(
      AppConstants.userKey,
      jsonEncode(authResponse.user.toJson()),
    );
  }
  
  AuthResult _handleAuthError(dynamic error) {
    if (error is Map<String, dynamic> && error.containsKey('detail')) {
      return AuthResult.error(message: error['detail']);
    }
    
    if (error.response?.data is Map<String, dynamic> && 
        error.response.data.containsKey('detail')) {
      return AuthResult.error(message: error.response.data['detail']);
    }
    
    if (error.error == 'NetworkError') {
      return const AuthResult.error(message: 'Network error. Check your internet connection.');
    }
    
    return const AuthResult.error(message: 'An error occurred');
  }
}