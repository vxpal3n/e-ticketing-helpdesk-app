import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/ticket/presentation/pages/ticket_list_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(authProvider).value ?? 'user';

    final List<Widget> pages = [
      DashboardPage(role: role), 
      TicketListPage(role: role),
      const ProfilePage(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        // Menyuntikkan font Inter ke label navigasi
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: Theme.of(context).colorScheme.primary);
          }
          return GoogleFonts.inter(fontWeight: FontWeight.normal, fontSize: 12);
        }),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined), 
            selectedIcon: Icon(Icons.dashboard_rounded), 
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.confirmation_number_outlined), 
            selectedIcon: Icon(Icons.confirmation_number_rounded), 
            label: 'Tiket',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined), 
            selectedIcon: Icon(Icons.settings_rounded), 
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}