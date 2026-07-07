import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/ticket_provider.dart';

class TicketDetailPage extends ConsumerStatefulWidget {
  final Ticket ticket; // Data awal dari list
  
  const TicketDetailPage({super.key, required this.ticket});

  @override
  ConsumerState<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends ConsumerState<TicketDetailPage> {
  final _commentController = TextEditingController();
  bool _isSendingComment = false;

  void _sendComment(String ticketId) async {
    if (_commentController.text.trim().isEmpty) return;
    
    setState(() => _isSendingComment = true);
    
    final success = await ref.read(ticketProvider.notifier).addComment(
      ticketId, 
      _commentController.text.trim()
    );
    
    setState(() => _isSendingComment = false);
    
    if (success && mounted) {
      _commentController.clear();
      // Keyboard otomatis turun
      FocusScope.of(context).unfocus(); 
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(authProvider).value ?? 'user';
    
    // Trik Riverpod: Ambil tiket terbaru dari list agar saat ada komentar/status baru, UI otomatis update
    final ticketState = ref.watch(ticketProvider);
    final currentTicket = ticketState.value?.firstWhere(
      (t) => t.id == widget.ticket.id, 
      orElse: () => widget.ticket
    ) ?? widget.ticket;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Detail Tiket', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          actions: [
            // TOMBOL DELETE KHUSUS ADMIN
            if (role == 'admin')
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                onPressed: () async {
                  // Dialog Konfirmasi
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text('Hapus Tiket', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                      content: const Text('Tindakan ini permanen. Lanjutkan?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                          onPressed: () => Navigator.pop(ctx, true), 
                          child: const Text('Hapus', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    final success = await ref.read(ticketProvider.notifier).deleteTicket(currentTicket.id);
                    if (success && context.mounted) {
                      Navigator.pop(context); // Kembali ke list
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tiket dihapus')));
                    }
                  }
                },
              ),
          ],
          bottom: TabBar(
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
            unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.normal),
            tabs: const [
              Tab(text: 'Informasi'),
              Tab(text: 'Tracking'),
              Tab(text: 'Komentar'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildInfoTab(context, ref, currentTicket, role),
            _buildTrackingTab(context, currentTicket),
            _buildCommentTab(context, currentTicket),
          ],
        ),
      ),
    );
  }

// --- TAB 1: INFORMASI & AKSI ---
  Widget _buildInfoTab(BuildContext context, WidgetRef ref, Ticket ticket, String role) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ticket.id, 
                style: AppTheme.monoTextStyle.copyWith(fontWeight: FontWeight.w500, fontSize: 16, color: AppColors.primary),
              ),
              _buildChip(ticket.status.toUpperCase(), _getStatusColor(ticket.status)),
            ],
          ),
          const SizedBox(height: 16),
          Text(ticket.title, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                '${ticket.createdAt.day}-${ticket.createdAt.month}-${ticket.createdAt.year}', 
                style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 12),
              ),
              const SizedBox(width: 16),
              Icon(Icons.flag, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                'Prioritas: ${ticket.priority}', 
                style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Deskripsi Kendala:', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text(ticket.description, style: GoogleFonts.inter(fontSize: 15, height: 1.5)),
          
          // --- LOGIKA MENAMPILKAN FOTO LAMPIRAN ---
          if (ticket.attachment != null) ...[
            const SizedBox(height: 24),
            Text('Lampiran Foto:', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                // Sesuaikan 127.0.0.1 dengan IP Base URL di dio_client.dart milikmu
                'http://127.0.0.1:8000/storage/${ticket.attachment}', 
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey.shade200,
                  child: const Center(child: Text('Gagal memuat gambar lampiran')),
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 32),
          
          // ACTION BUTTONS (EVENT-DRIVEN)
          _buildActionButtons(context, ref, role, ticket),
        ],
      ),
    );
  }

  // --- TAB 2: TRACKING TIMELINE ---
  Widget _buildTrackingTab(BuildContext context, Ticket ticket) {
    if (ticket.histories.isEmpty) {
      return Center(child: Text('Belum ada riwayat tercatat.', style: GoogleFonts.inter(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: ticket.histories.length,
      itemBuilder: (context, index) {
        final history = ticket.histories[index];
        return _buildTimelineItem(
          context, 
          history['action'] ?? '-', 
          history['description'] ?? '-', 
          history['created_at'],
          index == 0 // Item pertama (terbaru) dikasih warna nyala
        );
      },
    );
  }

  // --- TAB 3: KOMENTAR / CHAT ---
  Widget _buildCommentTab(BuildContext context, Ticket ticket) {
    return Column(
      children: [
        Expanded(
          child: ticket.comments.isEmpty
              ? Center(child: Text('Belum ada diskusi.', style: GoogleFonts.inter(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: ticket.comments.length,
                  itemBuilder: (context, index) {
                    final comment = ticket.comments[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      color: AppColors.primary.withOpacity(0.05),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(comment.userName, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.primary)),
                                Text(
                                  '${comment.createdAt.hour}:${comment.createdAt.minute.toString().padLeft(2, '0')}', 
                                  style: GoogleFonts.inter(fontSize: 10, color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(comment.message, style: GoogleFonts.inter(fontSize: 14)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        // Input Area
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), offset: const Offset(0, -2), blurRadius: 4)],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    hintText: 'Tulis balasan...',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    fillColor: Colors.transparent,
                    filled: false,
                  ),
                ),
              ),
              _isSendingComment
                  ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                  : IconButton(
                      icon: const Icon(Icons.send, color: AppColors.primary),
                      onPressed: () => _sendComment(ticket.id),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  // --- LOGIKA TOMBOL AKSI OTOMATIS ---
  Widget _buildActionButtons(BuildContext context, WidgetRef ref, String role, Ticket ticket) {
    final notifier = ref.read(ticketProvider.notifier);

    if (role == 'admin' && ticket.status == 'open') {
      return _buildFullWidthButton('Terima Tiket (Masuk Antrean)', AppColors.info, () async {
        final success = await notifier.acceptTicket(ticket.id);
        if (success && context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status berubah: ASSIGN')));
        }
      });
    }
    
    if (role == 'admin' && ticket.status == 'assign') {
      return _buildFullWidthButton('Tugaskan ke Helpdesk', AppColors.warning, () async {
        // Anggap ID Helpdesk adalah 2
        final success = await notifier.assignTicket(ticket.id, 2);
        if (success && context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status berubah: IN PROGRESS')));
        }
      });
    }

    if (role == 'helpdesk' && ticket.status == 'in progress') {
      return _buildFullWidthButton('Selesaikan Pekerjaan (Close)', AppColors.success, () async {
        final success = await notifier.finishTicket(ticket.id);
        if (success && context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status berubah: CLOSE')));
        }
      });
    }

    return const SizedBox.shrink();
  }

  Widget _buildFullWidthButton(String label, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: color),
        onPressed: onPressed,
        child: Text(label, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // --- UI HELPER ---
  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(label, style: GoogleFonts.inter(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildTimelineItem(BuildContext context, String title, String subtitle, String? dateStr, bool isLatest) {
    final date = dateStr != null ? DateTime.tryParse(dateStr) : null;
    final timeString = date != null ? '${date.hour}:${date.minute.toString().padLeft(2, '0')}' : '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 16, height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isLatest ? AppColors.primary : Colors.grey.shade300,
              ),
            ),
            Container(
              width: 2, height: 50,
              color: isLatest ? AppColors.primary : Colors.grey.shade300,
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: isLatest ? Theme.of(context).colorScheme.onSurface : Colors.grey)),
                  Text(timeString, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600)),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
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