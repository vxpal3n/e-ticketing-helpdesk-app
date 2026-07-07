import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/local_storage_service.dart';

// Provider untuk Service dan Network
final localStorageProvider = Provider((ref) => LocalStorageService());
final dioClientProvider = Provider((ref) => DioClient(localStorage: ref.watch(localStorageProvider)));

class AuthNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    // Cek apakah user sudah login sebelumnya (punya role tersimpan)
    final storage = ref.read(localStorageProvider);
    return await storage.getRole(); 
  }

  // --- FUNGSI LOGIN ---
  Future<bool> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      final dio = ref.read(dioClientProvider).dio;
      final storage = ref.read(localStorageProvider);

      final response = await dio.post('/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final token = data['access_token'];
        final role = data['user']['role']; 
        final name = data['user']['name'];   // Ambil nama dari API
        final email = data['user']['email']; // Ambil email dari API

        await storage.saveToken(token);
        await storage.saveRole(role);
        await storage.saveUserData(name, email); // Simpan ke storage

        state = AsyncData(role);
        return true;
      }
      return false;
      
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ?? 'Koneksi ke server gagal';
      state = AsyncError(errorMessage, StackTrace.current);
      return false;
    }
  }

  // --- FUNGSI REGISTER ---
  Future<bool> register(String name, String email, String password) async {
    state = const AsyncLoading();
    try {
      final dio = ref.read(dioClientProvider).dio;
      
      // Hit API Laravel (Endpoint akan kita buat nanti di backend jika belum ada)
      final response = await dio.post('/register', data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        state = const AsyncData(null); // Kembali ke state awal (belum login)
        return true;
      }
      return false;
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ?? 'Gagal mendaftarkan akun';
      state = AsyncError(errorMessage, StackTrace.current);
      return false;
    }
  }

  // --- FUNGSI RESET PASSWORD ---
  Future<bool> resetPassword(String email) async {
    state = const AsyncLoading();
    try {
      final dio = ref.read(dioClientProvider).dio;
      
      // Hit API Laravel untuk lupa password
      await dio.post('/forgot-password', data: {
        'email': email,
      });

      state = const AsyncData(null);
      return true;
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ?? 'Gagal mengirim link reset';
      state = AsyncError(errorMessage, StackTrace.current);
      return false;
    }
  }

  // --- FUNGSI LOGOUT ---
  Future<void> logout() async {
    state = const AsyncLoading();
    try {
      final dio = ref.read(dioClientProvider).dio;
      final storage = ref.read(localStorageProvider);

      await dio.post('/logout');
      await storage.clearAll();
      state = const AsyncData(null);
    } catch (e) {
      final storage = ref.read(localStorageProvider);
      await storage.clearAll();
      state = const AsyncData(null);
    }
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, String?>(() {
  return AuthNotifier();
});