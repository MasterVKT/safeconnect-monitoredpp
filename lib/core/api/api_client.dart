import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:monitored_app/app/constants.dart';
import 'package:monitored_app/app/locator.dart';
import 'package:monitored_app/core/api/api_interceptors.dart';
import 'package:monitored_app/core/config/app_config.dart';
import 'package:monitored_app/core/services/storage_service.dart';
import 'package:monitored_app/core/utils/error_logger.dart';
import 'package:monitored_app/core/network/certificate_pinner.dart';

class ApiClient {
  final Dio _dio = Dio();
  final StorageService _storageService = locator<StorageService>();

  String get baseUrl => AppConfig().apiBaseUrl;

  ApiClient() {
    _initializeDio();
  }

  void _initializeDio() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout =
        const Duration(milliseconds: AppConstants.connectTimeout);
    _dio.options.receiveTimeout =
        const Duration(milliseconds: AppConstants.receiveTimeout);
    _dio.options.sendTimeout =
        const Duration(milliseconds: AppConstants.sendTimeout);
    _dio.options.headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    // Configure certificate pinning
    (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.enableCertificatePinning();
      return client;
    };

    // Ajouter des intercepteurs
    if (kDebugMode) {
      _dio.interceptors.add(LoggingInterceptor());
    }

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final skipAuth = options.extra['skipAuth'] == true;
        if (skipAuth) {
          options.headers.remove('Authorization');
          return handler.next(options);
        }
        // Ajouter le token d'authentification à chaque requête
        final token = await _storageService.read(AppConstants.tokenKey);
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) async {
        final skipAuthRefresh =
            error.requestOptions.extra['skipAuthRefresh'] == true ||
                error.requestOptions.extra['skipAuth'] == true;
        // Gérer les erreurs d'authentification (401)
        if (!skipAuthRefresh && error.response?.statusCode == 401) {
          debugPrint('[API] Got 401, attempting token refresh...');
          
          // Tentative de rafraîchir le token
          final refreshSuccess = await _refreshToken();
          debugPrint('[API] Token refresh result: $refreshSuccess');
          
          if (refreshSuccess) {
            // Read the new token from storage
            final newToken = await _storageService.read(AppConstants.tokenKey);
            debugPrint('[API] New token obtained, retrying request...');
            
            // Update the request options with new token
            error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
            
            // Also need to clear the extra flags to prevent infinite loop
            error.requestOptions.extra['skipAuthRefresh'] = false;
            error.requestOptions.extra['skipAuth'] = false;
            
            try {
              final response = await _dio.fetch(error.requestOptions);
              debugPrint('[API] Retry successful: ${response.statusCode}');
              return handler.resolve(response);
            } catch (retryError) {
              debugPrint('[API] Retry failed: $retryError');
            }
          }
        }

        // Journaliser l'erreur
        if (kDebugMode) {
          print('API Error: ${error.message}');
        } else {
          ErrorLogger.logError(
            'API Error',
            error,
            StackTrace.current,
          );
        }

        return handler.next(error);
      },

    ));
  }

  // Méthodes pour les requêtes HTTP
  Future<Response> get(String path,
      {Map<String, dynamic>? queryParameters, Options? options}) {
    return _dio.get(path, queryParameters: queryParameters, options: options);
  }

  Future<Response> post(String path,
      {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) {
    return _dio.post(path,
        data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response> put(String path,
      {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) {
    return _dio.put(path,
        data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response> patch(String path,
      {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) {
    return _dio.patch(path,
        data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response> delete(String path,
      {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) {
    return _dio.delete(path,
        data: data, queryParameters: queryParameters, options: options);
  }

  // Emergency-specific API methods
  Future<Response> sendEmergencyAlert(
      Map<String, dynamic> emergencyData) async {
    try {
      debugPrint('Sending emergency alert to backend...');

      // Add priority flag for emergency data
      final alertData = {
        ...emergencyData,
        'priority': 'critical',
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'alert_type': 'emergency_activation',
      };

      final response = await post('/emergency/alert/', data: alertData);

      debugPrint('Emergency alert sent successfully');
      return response;
    } catch (e) {
      debugPrint('Error sending emergency alert: $e');
      rethrow;
    }
  }

  Future<Response> activateEmergencyMode(
      Map<String, dynamic> emergencyData) async {
    try {
      debugPrint('Activating emergency mode via API...');

      final response = await post('/emergency/activate/', data: {
        ...emergencyData,
        'activated_at': DateTime.now().toUtc().toIso8601String(),
      });

      debugPrint('Emergency mode activated via API');
      return response;
    } catch (e) {
      debugPrint('Error activating emergency mode: $e');
      rethrow;
    }
  }

  Future<Response> deactivateEmergencyMode(
      String emergencyId, String reason) async {
    try {
      debugPrint('Deactivating emergency mode via API...');

      final response = await post('/emergency/deactivate/', data: {
        'emergency_id': emergencyId,
        'reason': reason,
        'deactivated_at': DateTime.now().toUtc().toIso8601String(),
      });

      debugPrint('Emergency mode deactivated via API');
      return response;
    } catch (e) {
      debugPrint('Error deactivating emergency mode: $e');
      rethrow;
    }
  }

  Future<Response> sendEmergencyData(Map<String, dynamic> data) async {
    try {
      debugPrint('Sending emergency data to backend...');

      final emergencyData = {
        ...data,
        'emergency_flag': true,
        'priority': 1,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      };

      final response = await post('/emergency/data/', data: emergencyData);

      debugPrint('Emergency data sent successfully');
      return response;
    } catch (e) {
      debugPrint('Error sending emergency data: $e');
      rethrow;
    }
  }

  Future<Response> uploadEmergencyMedia(
      String filePath, String mediaType) async {
    try {
      debugPrint('Uploading emergency media: $mediaType');

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
        'media_type': mediaType,
        'emergency_flag': true,
        'priority': 1,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });

      final response = await post('/emergency/media/', data: formData);

      debugPrint('Emergency media uploaded successfully');
      return response;
    } catch (e) {
      debugPrint('Error uploading emergency media: $e');
      rethrow;
    }
  }

  Future<Response> sendEmergencyLocation(
      Map<String, dynamic> locationData) async {
    try {
      debugPrint('Sending emergency location data...');

      final data = {
        ...locationData,
        'emergency_flag': true,
        'priority': 1,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      };

      final response = await post('/emergency/location/', data: data);

      debugPrint('Emergency location data sent successfully');
      return response;
    } catch (e) {
      debugPrint('Error sending emergency location: $e');
      rethrow;
    }
  }

  // Méthode pour rafraîchir le token
  Future<bool> _refreshToken() async {
    try {
      final refreshToken =
          await _storageService.read(AppConstants.refreshTokenKey);
      if (refreshToken == null || refreshToken.isEmpty) {
        debugPrint('Refresh token is empty, skipping refresh');
        return false;
      }

      final response = await Dio().post(
        '$baseUrl/users/token/refresh/',
        data: {'refresh': refreshToken},
        options: Options(
          headers: {'Authorization': null},
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      // Only delete tokens and return false for auth-related errors (401/403)
      // Don't delete tokens for 400 Bad Request (e.g., invalid refresh token format)
      if (response.statusCode == 401 || response.statusCode == 403) {
        debugPrint('Token refresh failed with auth error: ${response.statusCode}');
        await _storageService.delete(AppConstants.tokenKey);
        await _storageService.delete(AppConstants.refreshTokenKey);
        return false;
      }

      if (response.statusCode == 400) {
        debugPrint('Token refresh rejected: ${response.data}');
        // Don't delete tokens for 400 - it might be a format issue, not auth
        return false;
      }

      if (response.statusCode == 200) {
        await _storageService.write(
            AppConstants.tokenKey, response.data['access']);
        if (response.data['refresh'] != null) {
          await _storageService.write(
              AppConstants.refreshTokenKey, response.data['refresh']);
        }
        return true;
      }
      return false;
    } catch (e) {
      // Only catch network errors, not auth-related errors
      debugPrint('Token refresh network error: $e');
      return false;
    }
  }
}
