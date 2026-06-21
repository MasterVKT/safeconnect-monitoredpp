import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monitored_app/app/constants.dart';
import 'package:monitored_app/core/api/api_client.dart';
import 'package:monitored_app/core/services/auth_service.dart';
import 'package:monitored_app/core/services/storage_service.dart';

class RecordingApiClient implements ApiClient {
  RecordingApiClient({this.response, this.error});

  final Response<dynamic>? response;
  final DioException? error;
  final List<ApiRequestCall> calls = <ApiRequestCall>[];

  @override
  String get baseUrl => 'http://localhost:8000';

  @override
  Future<Response> post(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    calls.add(
      ApiRequestCall(
        path: path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
    );

    if (error != null) {
      throw error!;
    }

    return response!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class ApiRequestCall {
  const ApiRequestCall({
    required this.path,
    required this.data,
    required this.queryParameters,
    required this.options,
  });

  final String path;
  final dynamic data;
  final Map<String, dynamic>? queryParameters;
  final Options? options;
}

class DummyStorageService implements StorageService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('AuthService pairing endpoint', () {
    late AuthService authService;
    late RecordingApiClient apiClient;
    late DummyStorageService storageService;

    test('uses only the official pairing validation endpoint', () async {
      final payload = <String, dynamic>{'pairing_code': '123456'};
      final response = Response<dynamic>(
        requestOptions: RequestOptions(
          path: AppConstants.validatePairingCodeEndpoint,
        ),
        statusCode: 200,
        data: <String, dynamic>{'success': true},
      );
      apiClient = RecordingApiClient(response: response);
      storageService = DummyStorageService();
      authService = AuthService(apiClient, storageService);

      final result = await authService.validatePairingCodeRequestAsync(payload);

      expect(result, same(response));

      expect(apiClient.calls, hasLength(1));
      final call = apiClient.calls.single;
      expect(call.path, AppConstants.validatePairingCodeEndpoint);
      expect(call.data, payload);
      expect(call.queryParameters, isNull);

      final options = call.options!;
      expect(options.extra!['skipAuth'], isTrue);
      expect(options.extra!['skipAuthRefresh'], isTrue);
    });

    test('propagates endpoint errors without trying alternate routes',
        () async {
      final payload = <String, dynamic>{'pairing_code': '123456'};
      final requestOptions = RequestOptions(
        path: AppConstants.validatePairingCodeEndpoint,
      );
      final error = DioException(
        requestOptions: requestOptions,
        response: Response<dynamic>(
          requestOptions: requestOptions,
          statusCode: 404,
          data: <String, dynamic>{'detail': 'Not found'},
        ),
        type: DioExceptionType.badResponse,
      );
      apiClient = RecordingApiClient(error: error);
      storageService = DummyStorageService();
      authService = AuthService(apiClient, storageService);

      await expectLater(
        authService.validatePairingCodeRequestAsync(payload),
        throwsA(same(error)),
      );

      expect(apiClient.calls, hasLength(1));
      expect(apiClient.calls.single.path,
          AppConstants.validatePairingCodeEndpoint);
      expect(apiClient.calls.single.data, payload);
    });
  });
}
