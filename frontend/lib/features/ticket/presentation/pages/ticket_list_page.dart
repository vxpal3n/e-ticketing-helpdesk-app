import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/ticket_provider.dart';
import 'create_ticket_page.dart';
import 'ticket_detail_page.dart';

class TicketListPage extends ConsumerWidget {
  final String role;
  final int initialIndex;

  const TicketListPage({super.key, required this.role, this.initialIndex = 0});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open': return AppColors.error;
      case 'assign': return AppColors.info;
      case 'in progress': return AppColors.warning;
      case 'close': return AppColors.success;
      default: return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketState = ref.watch(ticketProvider);

    return DefaultTabController(
      length: 5, // Sesuaikan dengan jumlah status di database
      initialIndex: initialIndex, // Gunakan initialIndex dari konstruktor
      child: Scaffold(
        appBar: AppBar(
          title: Text('Daftar Tiket', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Semua'),
              Tab(text: 'Open'),
              Tab(text: 'Assign'),
              Tab(text: 'In Progress'),
              Tab(text: 'Closed'),
            ],
          ),
        ),
        body: RefreshIndicator(
          onRefresh: () async => ref.invalidate(ticketProvider),
          child: ticketState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
            data: (tickets) {
              return TabBarView(
                children: [
                  _buildTicketList(context, tickets),
                  _buildTicketList(context, tickets.where((t) => t.status == 'open').toList()),
                  _buildTicketList(context, tickets.where((t) => t.status == 'assign').toList()),
                  _buildTicketList(context, tickets.where((t) => t.status == 'in progress').toList()),
                  _buildTicketList(context, tickets.where((t) => t.status == 'close').toList()),
                ],
              );
            },
          ),
        ),
        floatingActionButton: role == 'user' || role == 'admin' ? FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateTicketPage()));
          },
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text('Buat Tiket', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
        ) : null, // Helpdesk tidak perlu buat tiket
      ),
    );
  }

  Widget _buildTicketList(BuildContext context, List<Ticket> tickets) {
    if (tickets.isEmpty) {
      return const Center(child: Text('Tidak ada tiket di kategori ini.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        final color = _getStatusColor(ticket.status);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell( // Gunakan InkWell agar efek klik card terasa
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => TicketDetailPage(ticket: ticket)));
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Spesifikasi JetBrains Mono Medium 500 14sp untuk ID List Tiket
                        Text(
                          ticket.id, 
                          style: AppTheme.monoTextStyle.copyWith(fontWeight: FontWeight.w500, fontSize: 14, color: AppColors.primary),
                        ),
                        const SizedBox(height: 8),
                        Text(ticket.title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                            const SizedBox(width: 4),
                            Text(
                              '${ticket.createdAt.day}/${ticket.createdAt.month}/${ticket.createdAt.year}',
                              style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withOpacity(0.5)),
                    ),
                    child: Text(ticket.status.toUpperCase(), style: GoogleFonts.inter(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}