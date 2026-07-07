import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _pushNotif = true;
  bool _emailNotif = false;
  bool _ticketUpdates = true;
  bool _assignmentAlerts = true;
  bool _biometricLock = false;

  String _userName = 'Memuat...';
  String _userEmail = 'Memuat...';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // --- TARIK DATA ASLI DARI STORAGE ---
  Future<void> _loadUserData() async {
    final storage = ref.read(localStorageProvider);
    final data = await storage.getUserData();
    setState(() {
      _userName = data['name'] ?? 'Pengguna Sistem';
      _userEmail = data['email'] ?? 'user@company.com';
    });
  }

  // --- FUNGSI EDIT PROFILE (Data Asli) ---
  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _userName);
    final emailController = TextEditingController(text: _userEmail);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Profile', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
              decoration: const InputDecoration(labelText: 'Nama Lengkap'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
              decoration: const InputDecoration(labelText: 'Email Address'),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Batal', style: GoogleFonts.inter(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil sedang diperbarui (Simulasi API)')));
            },
            child: Text('Simpan', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- FUNGSI UBAH PASSWORD ---
  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Change Password', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(obscureText: true, style: GoogleFonts.inter(), decoration: const InputDecoration(labelText: 'Password Lama')),
            const SizedBox(height: 12),
            TextField(obscureText: true, style: GoogleFonts.inter(), decoration: const InputDecoration(labelText: 'Password Baru')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Batal', style: GoogleFonts.inter(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password berhasil diubah')));
            },
            child: Text('Simpan', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text('Logout', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin keluar dari aplikasi?', style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Batal', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(dialogContext); 
              await ref.read(authProvider.notifier).logout();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              }
            },
            child: Text('Ya, Logout', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final role = ref.watch(authProvider).value ?? 'user';
    final textColor = Theme.of(context).colorScheme.onSurface; // Dinamis untuk Light/Dark

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
        // --- 1. ACCOUNT ---
        _buildSectionHeader('ACCOUNT'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.primary.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U', 
                      style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userName,
                          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _userEmail,
                          style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.info.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            role.toUpperCase(), 
                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.info),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _showEditProfileDialog,
                    icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          _buildListTile(Icons.lock_outline, 'Change Password', onTap: _showChangePasswordDialog),
          const SizedBox(height: 24),

          // --- 2. APPEARANCE ---
          _buildSectionHeader('APPEARANCE'),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            leading: Icon(Icons.dark_mode_outlined, color: textColor),
            title: Text('Theme', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: textColor)),
            trailing: DropdownButton<ThemeMode>(
              value: themeMode,
              underline: const SizedBox(),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
              dropdownColor: Theme.of(context).colorScheme.surface, // Background bersih
              style: GoogleFonts.inter(color: textColor, fontWeight: FontWeight.w600, fontSize: 14), // Teks jelas
              onChanged: (mode) {
                if (mode != null) ref.read(themeProvider.notifier).setTheme(mode);
              },
              items: const [
                DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
              ],
            ),
          ),
          _buildListTile(Icons.language, 'Language', trailingText: 'English'),
          const SizedBox(height: 24),

          // --- 3. NOTIFICATIONS ---
          _buildSectionHeader('NOTIFICATIONS'),
          _buildSwitchTile('Push Notifications', _pushNotif, (val) => setState(() => _pushNotif = val)),
          _buildSwitchTile('Email Notifications', _emailNotif, (val) => setState(() => _emailNotif = val)),
          _buildSwitchTile('Ticket Updates', _ticketUpdates, (val) => setState(() => _ticketUpdates = val)),
          if (role == 'helpdesk' || role == 'admin')
            _buildSwitchTile('Assignment Alerts', _assignmentAlerts, (val) => setState(() => _assignmentAlerts = val)),
          const SizedBox(height: 24),

          // --- 4. PRIVACY & SECURITY ---
          _buildSectionHeader('PRIVACY & SECURITY'),
          _buildSwitchTile('Biometric Lock', _biometricLock, (val) => setState(() => _biometricLock = val)),
          _buildListTile(Icons.devices, 'Active Sessions'),
          if (role == 'user')
            _buildListTile(Icons.delete_forever_outlined, 'Delete Account', isDestructive: true),
          const SizedBox(height: 24),

          // --- 5. ABOUT ---
          _buildSectionHeader('ABOUT'),
          _buildListTile(Icons.info_outline, 'App Version', trailingText: 'v2.0.0', showArrow: false),
          _buildListTile(Icons.privacy_tip_outlined, 'Privacy Policy'),
          _buildListTile(Icons.description_outlined, 'Terms of Service'),
          _buildListTile(Icons.help_outline, 'Help Center'),
          const SizedBox(height: 32),

          // --- 6. LOGOUT BUTTON ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ElevatedButton(
              onPressed: _handleLogout,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error.withOpacity(0.1),
                foregroundColor: AppColors.error,
                elevation: 0,
                side: const BorderSide(color: AppColors.error, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout, color: AppColors.error),
                  const SizedBox(width: 8),
                  Text('Logout', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, bottom: 8, top: 8),
      child: Text(
        title,
        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey.shade500, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title, {String? trailingText, bool showArrow = true, bool isDestructive = false, VoidCallback? onTap}) {
    final textColor = isDestructive ? AppColors.error : Theme.of(context).colorScheme.onSurface;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: Icon(icon, color: textColor),
      title: Text(
        title, 
        style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: textColor),
      ),
      trailing: trailingText != null
          ? Text(trailingText, style: GoogleFonts.inter(color: Colors.grey, fontWeight: FontWeight.w500))
          : (showArrow ? const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey) : null),
      onTap: onTap ?? () {},
    );
  }

  Widget _buildSwitchTile(String title, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
      value: value,
      activeColor: AppColors.primary,
      onChanged: onChanged,
    );
  }
}