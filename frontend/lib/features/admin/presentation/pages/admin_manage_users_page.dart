import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/admin_provider.dart';

class AdminManageUsersPage extends ConsumerWidget {
  const AdminManageUsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminState = ref.watch(adminProvider);
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: Text('Kelola Pengguna', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(adminProvider),
        child: adminState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err', style: GoogleFonts.inter())),
          data: (users) {
            if (users.isEmpty) return Center(child: Text('Tidak ada pengguna.', style: GoogleFonts.inter()));

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: user.isActive ? AppColors.primary.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                      child: Icon(Icons.person, color: user.isActive ? AppColors.primary : Colors.grey),
                    ),
                    title: Text(user.name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: textColor)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.email, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.info.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            user.role.toUpperCase(), 
                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.info)
                          ),
                        ),
                      ],
                    ),
                    trailing: Switch(
                      value: user.isActive,
                      activeColor: AppColors.primary,
                      onChanged: (value) async {
                        final success = await ref.read(adminProvider.notifier).toggleUserStatus(user.id);
                        if (!success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Gagal mengubah status. Anda tidak bisa menonaktifkan akun sendiri!'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}