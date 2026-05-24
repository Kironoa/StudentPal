import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/screens/dashboard_screen.dart';
import 'package:mobile_app/screens/calendar_screen.dart';
import 'package:mobile_app/screens/schedule_screen.dart';
import 'package:mobile_app/screens/assignments_screen.dart';
import 'package:mobile_app/screens/profile_screen.dart';
import 'package:mobile_app/screens/settings_screen.dart';
import 'package:mobile_app/providers/theme_provider.dart';

class MainScaffold extends ConsumerStatefulWidget {
  final int userId;

  const MainScaffold({super.key, required this.userId});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  int _selectedIndex = 0;

  void _showCalendarModal() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: CalendarScreen(userId: widget.userId, showAsModal: true),
          ),
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      _showCalendarModal();
      return;
    }
    setState(() {
      _selectedIndex = index > 1 ? index - 1 : index;
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
            onNavigateToProfile: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(userId: widget.userId),
                ),
              );
            },
          ),
          SchedulePage(userId: widget.userId),
          AssignmentsScreen(userId: widget.userId),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex == 0
            ? 0
            : _selectedIndex + 1, // map stack index → nav index
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
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule_rounded),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task_alt_rounded),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class DashboardContent extends StatelessWidget {
  final int userId;
  final VoidCallback onNavigateToProfile;

  const DashboardContent({
    super.key,
    required this.userId,
    required this.onNavigateToProfile,
  });

  @override
  Widget build(BuildContext context) {
    return StudentDashboard(
      userId: userId,
      onNavigateToProfile: onNavigateToProfile,
    );
  }
}