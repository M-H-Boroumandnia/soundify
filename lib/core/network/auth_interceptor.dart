import 'package:dio/dio.dart';

import '../../data/models/auth_tokens.dart';
import '../storage/token_storage.dart';

class AuthInterceptor extends QueuedInterceptor {
  static const skipAuthKey = 'skipAuth';
  static const _retriedKey = 'retried';

  final Dio _dio;
  final Dio _refreshDio;
  final TokenStorage storage;
  final void Function() onSessionExpired;

  AuthInterceptor({
    required Dio dio,
    required this.storage,
    required this.onSessionExpired,
  })  : _dio = dio,
        _refreshDio = Dio(BaseOptions(
          baseUrl: dio.options.baseUrl,
          connectTimeout: dio.options.connectTimeout,
          receiveTimeout: dio.options.receiveTimeout,
          contentType: Headers.jsonContentType,
        ));

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[skipAuthKey] != true) {
      final token = await storage.readAccess();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    final eligible = err.response?.statusCode == 401 &&
        request.extra[skipAuthKey] != true &&
        request.extra[_retriedKey] != true;
    if (!eligible) {
      return handler.next(err);
    }

    final sentToken = _bearer(request.headers['Authorization']);
    final currentToken = await storage.readAccess();
    if (currentToken != null && currentToken != sentToken) {
      return _retry(request, currentToken, handler, err);
    }

    final newToken = await _refresh();
    if (newToken == null) {
      await storage.clear();
      onSessionExpired();
      return handler.next(err);
    }
    return _retry(request, newToken, handler, err);
  }

  Future<String?> _refresh() async {
    final refresh = await storage.readRefresh();
    if (refresh == null) return null;
    try {
      final response = await _refreshDio.post(
        '/auth/token/refresh/',
        data: {'refresh': refresh},
      );
      final tokens = AuthTokens.tryParse(response.data);
      if (tokens == null) return null;
      await storage.save(tokens);
      return tokens.access;
    } on DioException {
      return null;
    }
  }

  Future<void> _retry(
    RequestOptions request,
    String token,
    ErrorInterceptorHandler handler,
    DioException original,
  ) async {
    request.headers['Authorization'] = 'Bearer $token';
    request.extra[_retriedKey] = true;
    try {
      final response = await _dio.fetch<dynamic>(request);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  String? _bearer(dynamic header) {
    if (header is! String) return null;
    return header.startsWith('Bearer ') ? header.substring(7) : header;
  }
}
