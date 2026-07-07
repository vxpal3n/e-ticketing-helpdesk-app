import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/dashboard_provider.dart';
import '../../../ticket/presentation/providers/ticket_provider.dart';
import '../../../ticket/presentation/pages/ticket_list_page.dart';
import '../../../ticket/presentation/pages/ticket_detail_page.dart';
import '../../../notification/presentation/pages/notification_page.dart';

class DashboardPage extends ConsumerWidget {
  final String role;
  
  const DashboardPage({super.key, required this.role});

  String _getGreeting() {
    switch (role) {
      case 'admin': return 'Dashboard Admin';
      case 'helpdesk': return 'Dashboard Support';
      default: return 'Dashboard User';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardProvider);
    final ticketState = ref.watch(ticketProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_getGreeting(), style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 24)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {
              // --- 1. NAVIGASI NOTIFIKASI BEKERJA ---
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationPage()));
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(dashboardProvider.notifier).refresh();
          ref.invalidate(ticketProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                role == 'admin' 
                    ? 'Berikut ringkasan seluruh tiket dalam sistem.' 
                    : role == 'helpdesk'
                        ? 'Berikut tiket yang sedang ditugaskan kepada Anda.'
                        : 'Berikut adalah ringkasan tiket Anda.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
              ),
              const SizedBox(height: 32),

              dashboardState.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Text('Error: $err'),
                data: (stats) => GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.3,
                  children: [
                    // --- 2. STATISTIK KLIKABLE ---
                    _buildStatCard(context, 'Total Tiket', stats.total.toString(), Icons.confirmation_number_outlined, AppColors.primary, () => _goToTab(context, 0)),
                    _buildStatCard(context, 'Open', stats.open.toString(), Icons.error_outline, AppColors.error, () => _goToTab(context, 1)),
                    _buildStatCard(context, 'Assign', stats.assign.toString(), Icons.assignment_ind_outlined, AppColors.info, () => _goToTab(context, 2)),
                    _buildStatCard(context, 'In Progress', stats.inProgress.toString(), Icons.pending_actions, AppColors.warning, () => _goToTab(context, 3)),
                    _buildStatCard(context, 'Closed', stats.close.toString(), Icons.check_circle_outline, AppColors.success, () => _goToTab(context, 4)),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              Text('Tiket Terbaru', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              
              ticketState.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => const Text('Gagal memuat tiket terbaru'),
                data: (tickets) {
                  if (tickets.isEmpty) return const Text('Belum ada tiket.');
                  final recentTickets = tickets.take(3).toList();
                  return Column(
                    children: recentTickets.map((ticket) => _buildRecentTicketCard(context, ticket)).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _goToTab(BuildContext context, int index) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => TicketListPage(role: role, initialIndex: index)));
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color.withOpacity(0.2), width: 1),
        ),
        color: color.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const Spacer(),
              Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 32, color: color)),
              Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTicketCard(BuildContext context, Ticket ticket) {
    final statusColor = _getStatusColor(ticket.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        // --- 3. RECENT TIKET KLIKABLE ---
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TicketDetailPage(ticket: ticket))),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: Text(ticket.title, style: GoogleFonts.inter(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(ticket.id, style: AppTheme.monoTextStyle.copyWith(fontWeight: FontWeight.w500, color: AppColors.primary)),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withOpacity(0.5)),
            ),
            child: Text(ticket.status.toUpperCase(), style: GoogleFonts.inter(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open': return AppColors.error;
      case 'assign': return AppColors.info;
      case 'in progress': return AppColors.warning;
      case 'close': return AppColors.success;
      default: return AppColors.info;
    }
  }
}