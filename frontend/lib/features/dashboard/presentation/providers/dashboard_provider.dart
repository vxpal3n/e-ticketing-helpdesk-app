import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// --- MODEL STATISTIK ---
class TicketStats {
  final int total;
  final int open;
  final int assign;
  final int inProgress;
  final int close;

  TicketStats({
    required this.total,
    required this.open,
    required this.assign,
    required this.inProgress,
    required this.close,
  });

  factory TicketStats.fromJson(Map<String, dynamic> json) {
    return TicketStats(
      total: json['total'] ?? 0,
      open: json['open'] ?? 0,
      assign: json['assign'] ?? 0,
      inProgress: json['in_progress'] ?? 0,
      close: json['close'] ?? 0,
    );
  }
}

// --- PROVIDER DASHBOARD ---
class DashboardNotifier extends AsyncNotifier<TicketStats> {
  @override
  Future<TicketStats> build() async {
    return fetchStatistics();
  }

  Future<TicketStats> fetchStatistics() async {
    try {
      final dio = ref.read(dioClientProvider).dio;
      final response = await dio.get('/dashboard/statistics');
      
      if (response.statusCode == 200) {
        return TicketStats.fromJson(response.data['data']);
      }
      throw Exception('Gagal memuat statistik');
    } catch (e) {
      throw Exception('Terjadi kesalahan jaringan');
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final stats = await fetchStatistics();
      state = AsyncData(stats);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final dashboardProvider = AsyncNotifierProvider<DashboardNotifier, TicketStats>(() {
  return DashboardNotifier();
});