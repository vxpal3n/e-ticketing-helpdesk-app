import 'package:dio/dio.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';

// --- MODEL KOMENTAR ---
class TicketComment {
  final int id;
  final String message;
  final String userName;
  final DateTime createdAt;

  TicketComment({
    required this.id,
    required this.message,
    required this.userName,
    required this.createdAt,
  });

  factory TicketComment.fromJson(Map<String, dynamic> json) {
    return TicketComment(
      id: json['id'] ?? 0,
      message: json['message'] ?? '',
      // Menarik nama user dari relasi (jika ada)
      userName: json['user'] != null ? json['user']['name'] : 'Unknown',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }
}

// --- MODEL TIKET TERBARU ---
class Ticket {
  final String id;
  final String title;
  final String description;
  final String status;
  final String? priority;
  final String? attachment; // <-- 2. TAMBAHKAN INI UNTUK MENAMPUNG NAMA FILE
  final DateTime createdAt;
  final List<dynamic> histories;
  final List<TicketComment> comments;

  Ticket({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    this.priority,
    this.attachment, // <-- TAMBAHKAN INI
    this.histories = const [],
    this.comments = const [],
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'open',
      priority: json['priority'] ?? 'Medium',
      attachment: json['attachment'], // <-- TAMBAHKAN INI
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      histories: json['histories'] ?? [],
      comments: json['comments'] != null 
          ? (json['comments'] as List).map((c) => TicketComment.fromJson(c)).toList() 
          : [],
    );
  }
}

// --- PROVIDER TIKET ---
class TicketNotifier extends AsyncNotifier<List<Ticket>> {
  @override
  Future<List<Ticket>> build() async {
    return fetchTickets();
  }

  Future<List<Ticket>> fetchTickets() async {
    try {
      final dio = ref.read(dioClientProvider).dio;
      final response = await dio.get('/tickets');
      
      if (response.statusCode == 200) {
        final List data = response.data['data'];
        return data.map((e) => Ticket.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Gagal memuat tiket');
    }
  }

  // 2. Create Ticket (User) -> Dukung Upload Gambar
  Future<bool> createTicket(String title, String desc, String priority, {String? imagePath}) async {
    try {
      final dio = ref.read(dioClientProvider).dio;
      
      final formData = FormData.fromMap({
        'title': title,
        'description': desc,
        'priority': priority,
      });

      // Tambahkan file dengan filename eksplisit agar dibaca Laravel
      if (imagePath != null) {
        String fileName = imagePath.split('/').last;
        formData.files.add(MapEntry(
          'attachment',
          await MultipartFile.fromFile(imagePath, filename: fileName),
        ));
      }

      await dio.post('/tickets', data: formData);
      ref.invalidateSelf(); 
      ref.invalidate(dashboardProvider); 
      return true;
    } catch (e) {
      return false;
    }
  }

  // Aksi Status
  Future<bool> acceptTicket(String id) async {
    try {
      final dio = ref.read(dioClientProvider).dio;
      await dio.post('/tickets/$id/accept');
      ref.invalidateSelf();
      ref.invalidate(dashboardProvider);
      return true;
    } catch (e) { return false; }
  }

  Future<bool> assignTicket(String id, int helpdeskId) async {
    try {
      final dio = ref.read(dioClientProvider).dio;
      await dio.post('/tickets/$id/assign', data: {'helpdesk_id': helpdeskId});
      ref.invalidateSelf();
      ref.invalidate(dashboardProvider);
      return true;
    } catch (e) { return false; }
  }

  Future<bool> finishTicket(String id) async {
    try {
      final dio = ref.read(dioClientProvider).dio;
      await dio.post('/tickets/$id/finish');
      ref.invalidateSelf();
      ref.invalidate(dashboardProvider);
      return true;
    } catch (e) { return false; }
  }

  // Fungsi Delete Tiket (Admin Only)
  Future<bool> deleteTicket(String id) async {
    try {
      final dio = ref.read(dioClientProvider).dio;
      await dio.delete('/admin/tickets/$id');
      ref.invalidateSelf();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Tambah Komentar
  Future<bool> addComment(String ticketId, String message) async {
    try {
      final dio = ref.read(dioClientProvider).dio;
      await dio.post('/tickets/$ticketId/comments', data: {'message': message});
      ref.invalidateSelf(); // Refresh data tiket agar komentar baru muncul
      return true;
    } catch (e) { return false; }
  }
}

final ticketProvider = AsyncNotifierProvider<TicketNotifier, List<Ticket>>(() {
  return TicketNotifier();
});