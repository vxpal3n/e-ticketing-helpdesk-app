import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/notification_provider.dart';

class NotificationPage extends ConsumerWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Pantau state dari provider notifikasi
    final notificationState = ref.watch(notificationProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Notifikasi', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: () {
              // Tandai semua dibaca
              ref.read(notificationProvider.notifier).markAllAsRead();
            },
            child: Text(
              'Tandai Dibaca', 
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.primary)
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(notificationProvider),
        child: notificationState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err', style: GoogleFonts.inter())),
          data: (notifications) {
            if (notifications.isEmpty) {
              return Center(
                child: Text('Belum ada notifikasi.', style: GoogleFonts.inter(color: Colors.grey))
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return _buildNotificationItem(context, ref, notif);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, WidgetRef ref, AppNotification notif) {
    final isUnread = !notif.isRead;
    // Format waktu simpel: DD/MM/YYYY HH:MM
    final timeString = '${notif.createdAt.day}/${notif.createdAt.month}/${notif.createdAt.year} ${notif.createdAt.hour}:${notif.createdAt.minute.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: () {
        if (isUnread) {
          // Tandai dibaca jika ditekan
          ref.read(notificationProvider.notifier).markAsRead(notif.id);
        }
        if (notif.ticketId != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tiket terkait: ${notif.ticketId}', style: GoogleFonts.inter(color: Colors.white)),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Container(
        color: isUnread ? AppColors.info.withOpacity(0.05) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  backgroundColor: isUnread ? AppColors.primary.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                  child: Icon(
                    Icons.notifications_active_outlined, 
                    color: isUnread ? AppColors.primary : Colors.grey,
                  ),
                ),
                if (isUnread)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 10, height: 10,
                      decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                    ),
                  ),
            ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notif.title, 
                    style: GoogleFonts.inter(
                      fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                      color: isUnread ? Theme.of(context).colorScheme.onSurface : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // --- MAGIC DETECTOR: JetBrains Mono untuk ID Tiket ---
                  _buildMessageWithMono(context, notif.message, isUnread),
                  
                  const SizedBox(height: 8),
                  Text(
                    timeString, 
                    style: GoogleFonts.inter(
                      fontSize: 12, 
                      color: Colors.grey.shade500
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper untuk mendeteksi ID Tiket (TK-...) dan memberinya font JetBrains Mono
  Widget _buildMessageWithMono(BuildContext context, String message, bool isUnread) {
    // Pecah kalimat berdasarkan spasi
    final words = message.split(' ');
    
    return RichText(
      text: TextSpan(
        children: words.map((word) {
          // Jika kata mengandung format ID tiket kita (TK-...)
          if (word.contains('TK-')) {
            return TextSpan(
              text: '$word ',
              style: AppTheme.monoTextStyle.copyWith(
                fontWeight: FontWeight.w400, // Regular 400 sesuai spesifikasi
                color: isUnread ? Theme.of(context).colorScheme.onSurface : Colors.grey.shade600,
              ),
            );
          }
          // Jika kata biasa (Inter)
          return TextSpan(
            text: '$word ',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w400,
              color: isUnread ? Theme.of(context).colorScheme.onSurface : Colors.grey.shade600,
            ),
          );
        }).toList(),
      ),
    );
  }
}