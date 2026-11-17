import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';
import 'auth_interceptor.dart';

class ApiClient {
  final Dio dio;

  ApiClient._(this.dio);

  factory ApiClient({
    required TokenStorage storage,
    required void Function() onSessionExpired,
  }) {
    final dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      sendTimeout: AppConfig.connectTimeout,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ));
    dio.interceptors.add(AuthInterceptor(
      dio: dio,
      storage: storage,
      onSessionExpired: onSessionExpired,
    ));
    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: false,
        logPrint: (o) => debugPrint(o.toString()),
      ));
    }
    return ApiClient._(dio);
  }

  static Options publicOptions() =>
      Options(extra: {AuthInterceptor.skipAuthKey: true});

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? query,
    bool auth = true,
    CancelToken? cancelToken,
  }) =>
      _send(() => dio.get(
            path,
            queryParameters: query,
            options: auth ? null : publicOptions(),
            cancelToken: cancelToken,
          ));

  Future<dynamic> post(String path, {Object? data, bool auth = true}) =>
      _send(() => dio.post(
            path,
            data: data,
            options: auth ? null : publicOptions(),
          ));

  Future<dynamic> patch(String path, {Object? data}) =>
      _send(() => dio.patch(path, data: data));

  Future<dynamic> delete(String path) => _send(() => dio.delete(path));

  Future<dynamic> _send(Future<Response<dynamic>> Function() call) async {
    try {
      final response = await call();
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
