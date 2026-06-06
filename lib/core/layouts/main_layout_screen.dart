import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/widget_service.dart';
import '../../features/groups/screens/home_screen.dart';
import '../../features/reports/screens/report_screen.dart';
import '../../features/personal/screens/personal_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/savings/screens/savings_screen.dart';
import '../theme/app_theme.dart';

import 'package:google_nav_bar/google_nav_bar.dart';

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _initWidget();
  }

  Future<void> _initWidget() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await WidgetService.updateWidgetFromUid(uid);
    }
  }

  final List<Widget> _screens = [
    const HomeScreen(),
    const PersonalScreen(),
    const SavingsScreen(),
    const ReportScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: Colors.black.withValues(alpha: 0.1),
            )
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8),
            child: GNav(
              rippleColor: Colors.grey[300]!,
              hoverColor: Colors.grey[100]!,
              gap: 8,
              activeColor: Theme.of(context).colorScheme.primary,
              iconSize: 24,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              color: Colors.grey,
              tabs: const [
                GButton(
                  icon: Icons.group,
                  text: 'Nhóm',
                ),
                GButton(
                  icon: Icons.person,
                  text: 'Cá nhân',
                ),
                GButton(
                  icon: Icons.savings,
                  text: 'Tiết kiệm',
                ),
                GButton(
                  icon: Icons.bar_chart,
                  text: 'Báo cáo',
                ),
                GButton(
                  icon: Icons.settings,
                  text: 'Cài đặt',
                ),
              ],
              selectedIndex: _currentIndex,
              onTabChange: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
          ),
        ),
      ),
    );
  }
}
