import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:monitored_app/app/constants.dart';
import 'package:monitored_app/app/locator.dart';
import 'package:monitored_app/core/api/api_interceptors.dart';
import 'package:monitored_app/core/services/storage_service.dart';
import 'package:monitored_app/core/utils/error_logger.dart';

class ApiClient {
  final Dio _dio = Dio();
  final String baseUrl = AppConstants.apiV1;
  final StorageService _storageService = locator<StorageService>();

  ApiClient() {
    _initializeDio();
  }
  
  void _initializeDio() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(milliseconds: AppConstants.connectTimeout);
    _dio.options.receiveTimeout = const Duration(milliseconds: AppConstants.receiveTimeout);
    _dio.options.sendTimeout = const Duration(milliseconds: AppConstants.sendTimeout);
    _dio.options.headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    
    // Ajouter des intercepteurs
    if (kDebugMode) {
      _dio.interceptors.add(LoggingInterceptor());
    }
    
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Ajouter le token d'authentification à chaque requête
        final token = await _storageService.read(AppConstants.tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) async {
        // Gérer les erreurs d'authentification (401)
        if (error.response?.statusCode == 401) {
          // Tentative de rafraîchir le token
          if (await _refreshToken()) {
            // Réessayer la requête avec le nouveau token
            final token = await _storageService.read(AppConstants.tokenKey);
            error.requestOptions.headers['Authorization'] = 'Bearer $token';
            final response = await _dio.fetch(error.requestOptions);
            return handler.resolve(response);
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
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters, Options? options}) {
    return _dio.get(path, queryParameters: queryParameters, options: options);
  }

  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) {
    return _dio.post(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response> put(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) {
    return _dio.put(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response> delete(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) {
    return _dio.delete(path, data: data, queryParameters: queryParameters, options: options);
  }
  
  // Méthode pour rafraîchir le token
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storageService.read(AppConstants.refreshTokenKey);
      if (refreshToken == null) return false;

      final response = await Dio().post(
        '$baseUrl/users/token/refresh/',
        data: {'refresh': refreshToken},
        options: Options(headers: {'Authorization': null}),
      );

      if (response.statusCode == 200) {
        await _storageService.write(AppConstants.tokenKey, response.data['access']);
        await _storageService.write(AppConstants.refreshTokenKey, response.data['refresh']);
        return true;
      }
      return false;
    } catch (e) {
      // En cas d'échec de rafraîchissement, déconnecter l'utilisateur
      await _storageService.delete(AppConstants.tokenKey);
      await _storageService.delete(AppConstants.refreshTokenKey);
      return false;
    }
  }
}