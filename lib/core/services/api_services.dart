import 'package:dio/dio.dart';
import 'dart:io';

import 'package:dio/io.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // TODO: Replace with your actual API URL
  static const String baseUrl = 'https://your-api-url.com/api/v1';

  late final Dio _dio = _createDio();

  Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Configure custom HTTP client adapter to bypass SSL verification
    // WARNING: This is for DEVELOPMENT ONLY - NOT recommended for production!
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        // Bypass SSL certificate validation
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
        return client;
      },
    );

    // Add logging interceptor for debugging
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => print('DIO: $obj'),
    ));

    return dio;
  }

  Dio get dio => _dio;

  // Auth Methods
  Future<Response> login(String email, String password) async {
    return await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
  }

  Future<Response> register(String name, String email, String password) async {
    return await _dio.post('/auth/register', data: {
      'name': name,
      'email': email,
      'password': password,
    });
  }
}
