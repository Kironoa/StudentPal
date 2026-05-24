import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/screens/dashboard_screen.dart';
import 'package:mobile_app/screens/schedule_screen.dart';
import 'package:mobile_app/screens/assignments_screen.dart';
import 'package:mobile_app/screens/profile_screen.dart';
import 'package:mobile_app/screens/settings_screen.dart';
import 'package:mobile_app/widgets/live_clock_widget.dart';
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
    final theme = Theme.of(context);
    final accent = ref.read(themeProvider).accentColor;
    final now = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: accent.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8, horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('MMMM yyyy').format(now).toUpperCase(),
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 1.2,
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.close_rounded,
                        color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.5),
                        size: 18),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              CalendarWidget(
                accent: accent,
                today: now,
                userId: widget.userId,
              ),
            ],
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