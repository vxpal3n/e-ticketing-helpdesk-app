import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// --- MODEL NOTIFIKASI ---
class AppNotification {
  final int id;
  final String title;
  final String message;
  final bool isRead;
  final String? ticketId;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    this.ticketId,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      ticketId: json['ticket_id'], 
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }
}

// --- PROVIDER NOTIFIKASI ---
class NotificationNotifier extends AsyncNotifier<List<AppNotification>> {
  @override
  Future<List<AppNotification>> build() async {
    return fetchNotifications();
  }

  Future<List<AppNotification>> fetchNotifications() async {
    try {
      final dio = ref.read(dioClientProvider).dio;
      final response = await dio.get('/notifications');
      
      if (response.statusCode == 200) {
        final List data = response.data['data'];
        return data.map((e) => AppNotification.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Gagal memuat notifikasi');
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      final dio = ref.read(dioClientProvider).dio;
      await dio.patch('/notifications/$id/read');
      ref.invalidateSelf(); 
    } catch (e) {
      // Abaikan jika gagal
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final dio = ref.read(dioClientProvider).dio;
      await dio.patch('/notifications/read-all');
      ref.invalidateSelf(); 
    } catch (e) {
      // Abaikan jika gagal
    }
  }
}

final notificationProvider = AsyncNotifierProvider<NotificationNotifier, List<AppNotification>>(() {
  return NotificationNotifier();
});