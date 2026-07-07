import 'package:dio/dio.dart';
import '../services/local_storage_service.dart';

class DioClient {
  // Gunakan http://10.0.2.2:8000/api untuk Android Emulator
  // Gunakan http://127.0.0.1:8000/api untuk iOS Simulator / Web
  static const String _baseUrl = 'http://127.0.0.1:8000/api';
  
  final Dio _dio;
  final LocalStorageService _localStorage;

  DioClient({LocalStorageService? localStorage}) 
    : _localStorage = localStorage ?? LocalStorageService(),
      _dio = Dio(
        BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Accept': 'application/json'},
        ),
      ) {
    
    // Interceptor untuk otomatis memasukkan Token ke setiap request API
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _localStorage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException error, handler) {
          return handler.next(error);
        },
      ),
    );
  }

  Dio get dio => _dio;
}