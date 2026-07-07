import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// --- MODEL USER ---
class AppUser {
  final int id;
  final String name;
  final String email;
  final String role;
  final bool isActive;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }
}

// --- PROVIDER ADMIN ---
class AdminNotifier extends AsyncNotifier<List<AppUser>> {
  @override
  Future<List<AppUser>> build() async {
    return fetchUsers();
  }

  Future<List<AppUser>> fetchUsers() async {
    try {
      final dio = ref.read(dioClientProvider).dio;
      final response = await dio.get('/admin/users');
      
      if (response.statusCode == 200) {
        final List data = response.data['data'];
        return data.map((e) => AppUser.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Gagal memuat daftar pengguna');
    }
  }

  Future<bool> toggleUserStatus(int id) async {
    try {
      final dio = ref.read(dioClientProvider).dio;
      await dio.patch('/admin/users/$id/toggle-status');
      ref.invalidateSelf(); // Refresh list setelah update
      return true;
    } catch (e) {
      return false;
    }
  }
}

final adminProvider = AsyncNotifierProvider<AdminNotifier, List<AppUser>>(() {
  return AdminNotifier();
});