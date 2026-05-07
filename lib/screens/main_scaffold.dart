import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/screens/dashboard_screen.dart';
import 'package:mobile_app/screens/schedule_screen.dart';
import 'package:mobile_app/screens/assignments_screen.dart';
import 'package:mobile_app/screens/profile_screen.dart';
import 'package:mobile_app/providers/theme_provider.dart';

class MainScaffold extends ConsumerStatefulWidget {
  final int userId;

  const MainScaffold({super.key, required this.userId});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeState = ref.watch(themeProvider);
    final double scale = themeState.uiScale;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          DashboardContent(
            userId: widget.userId,
            onNavigateToSchedule: () => _onItemTapped(1),
            onNavigateToAssignments: () => _onItemTapped(2),
            onNavigateToProfile: () => _onItemTapped(3),
          ),
          SchedulePage(userId: widget.userId),
          AssignmentsScreen(userId: widget.userId),
          ProfileScreen(userId: widget.userId),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        type: BottomNavigationBarType.fixed,
        backgroundColor: theme.cardColor,
        elevation: 8,
        selectedFontSize: 12 * scale,
        unselectedFontSize: 12 * scale,
        iconSize: 24 * scale,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_rounded),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task_alt_rounded),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class DashboardContent extends StatelessWidget {
  final int userId;
  final VoidCallback onNavigateToSchedule;
  final VoidCallback onNavigateToAssignments;
  final VoidCallback onNavigateToProfile;

  const DashboardContent({
    super.key,
    required this.userId,
    required this.onNavigateToSchedule,
    required this.onNavigateToAssignments,
    required this.onNavigateToProfile,
  });

  @override
  Widget build(BuildContext context) {
    return StudentDashboard(
      userId: userId,
      onNavigateToSchedule: onNavigateToSchedule,
      onNavigateToAssignments: onNavigateToAssignments,
      onNavigateToProfile: onNavigateToProfile,
    );
  }
}