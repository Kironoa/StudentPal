import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_app/models/schedule_model.dart';
import 'package:mobile_app/helper/db_helper.dart';
import 'package:mobile_app/screens/resource_screen.dart';
import 'package:mobile_app/screens/schedule_screen.dart';
import 'package:mobile_app/screens/settings_screen.dart';
import 'package:mobile_app/providers/theme_provider.dart';
import 'package:mobile_app/providers/user_provider.dart';
import 'package:mobile_app/services/notification_service.dart';
import 'package:mobile_app/screens/notes_screen.dart';
import 'package:mobile_app/screens/assignments_screen.dart';
import 'package:mobile_app/screens/chat_screen.dart';
import 'package:mobile_app/screens/profile_screen.dart';
import 'package:mobile_app/screens/quizzes_screen.dart';
import 'package:mobile_app/screens/flashcards_screen.dart';
import 'package:mobile_app/screens/summaries_screen.dart';
import 'package:mobile_app/screens/login_screen.dart';
import 'package:mobile_app/widgets/live_clock_widget.dart';
import 'package:mobile_app/utils/responsive.dart';

class StudentDashboard extends ConsumerStatefulWidget {
  final int userId;
  const StudentDashboard({super.key, required this.userId});

  @override
  ConsumerState<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends ConsumerState<StudentDashboard>
    with TickerProviderStateMixin {
  late Timer _classTimer;
  late AnimationController _bgAnimationController;
  late AnimationController _speedDialAnimationController;
  late ScrollController _scrollController;

  final DatabaseHelper _dbHelper = DatabaseHelper();
  final NotificationService _notifService = NotificationService();

  List<Schedule> _todaySchedules = [];
  List<Map<String, dynamic>> _recentAssignments = [];
  Schedule? _currentClass;
  Schedule? _nextClass;

  int _selectedIndex = 0;
  bool _isSpeedDialExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _scrollController = ScrollController(keepScrollOffset: true);
    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _speedDialAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  double res(BuildContext context, double value) => value;

  DateTime _parseTime(String timeStr) {
    final now = DateTime.now();
    final trimmed = timeStr.trim();

    try {
      return DateFormat("h:mm a").parse(trimmed).copyWith(
            year: now.year,
            month: now.month,
            day: now.day,
          );
    } catch (_) {}

    try {
      return DateFormat("HH:mm").parse(trimmed).copyWith(
            year: now.year,
            month: now.month,
            day: now.day,
          );
    } catch (_) {}

    try {
      return DateFormat("h:mm").parse(trimmed).copyWith(
            year: now.year,
            month: now.month,
            day: now.day,
          );
    } catch (_) {}

    return now;
  }

  void _updateCurrentAndNextClass() {
    if (_todaySchedules.isEmpty) {
      setState(() {
        _currentClass = null;
        _nextClass = null;
      });
      return;
    }
    final now = DateTime.now();
    Schedule? foundCurrent;
    Schedule? foundNext;
    Duration minNextGap = const Duration(days: 1);

    for (var schedule in _todaySchedules) {
      final start = _parseTime(schedule.startTime);
      final end = _parseTime(schedule.endTime);
      if (now.isAfter(start) && now.isBefore(end)) {
        foundCurrent = schedule;
      }
      if (start.isAfter(now)) {
        final gap = start.difference(now);
        if (gap < minNextGap) {
          minNextGap = gap;
          foundNext = schedule;
        }
      }
    }
    setState(() {
      _currentClass = foundCurrent;
      _nextClass = foundNext;
    });
  }

  Future<void> _loadDashboardData() async {
    final allSchedules = await _dbHelper.getAllSchedules(widget.userId);
    DateTime now = DateTime.now();
    String currentDayName = DateFormat('EEEE').format(now).toLowerCase();
    final allAssignments = await _dbHelper.getAssignments(widget.userId);

    final dayMap = {
      'monday': ['monday', 'mon', 'm'],
      'tuesday': ['tuesday', 'tue', 't'],
      'wednesday': ['wednesday', 'wed', 'w'],
      'thursday': ['thursday', 'thu', 'th'],
      'friday': ['friday', 'fri', 'f'],
      'saturday': ['saturday', 'sat', 's'],
      'sunday': ['sunday', 'sun', 'su'],
    };
    final currentDayAliases = dayMap[currentDayName] ?? [];

    if (mounted) {
      setState(() {
        _todaySchedules = allSchedules.where((s) {
          final scheduleDays = s.days.toLowerCase();
          return currentDayAliases.any((alias) => scheduleDays.contains(alias));
        }).toList();
        _todaySchedules.sort(
          (a, b) => _parseTime(a.startTime).compareTo(_parseTime(b.startTime)),
        );
        _recentAssignments = allAssignments.take(3).toList();
      });
      _updateCurrentAndNextClass();
    }

    Future.wait(_todaySchedules.map((schedule) async {
      try {
        final DateTime scheduledTime = _parseTime(schedule.startTime);
        await _notifService.scheduleClassAlerts(
          id: schedule.id ?? 0,
          subject: schedule.subject,
          startTime: scheduledTime,
        );
      } catch (e) {
        debugPrint("Failed to schedule ${schedule.subject}: $e");
      }
    }));

    _classTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (mounted) {
        _updateCurrentAndNextClass();
      }
    });
  }

  String formatDeadline(String? raw) {
    if (raw == null || raw.isEmpty) return 'No date';
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('MMM dd, yyyy hh:mm a').format(dt);
    } catch (_) {
      return raw;
    }
  }

  Color _getDeadlineColor(String? deadlineRaw, Color defaultColor) {
    if (deadlineRaw == null || deadlineRaw.isEmpty) return defaultColor;
    try {
      final deadline = DateTime.parse(deadlineRaw);
      final now = DateTime.now();
      final diff = deadline.difference(now);
      if (diff.isNegative) return Colors.red;
      if (diff.inHours <= 5) return Colors.red;
      if (diff.inHours <= 15) return Colors.orange;
      return Colors.green;
    } catch (_) {
      return defaultColor;
    }
  }

  String _capitalize(String s) {
    if (s.isEmpty) return '';
    return s[0].toUpperCase() + s.substring(1);
  }

  String _formatCountdown(Schedule? schedule, {bool isNext = false}) {
    if (schedule == null) {
      return isNext ? "No upcoming classes" : "No class active";
    }
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;

    if (isNext) {
      final target = _parseTime(schedule.startTime);
      final duration = target.difference(now);
      if (duration.isNegative) return "Completed";
      if (duration.inSeconds < 60) return "Starting now";
      String twoDigits(int n) => n.toString().padLeft(2, "0");
      String h = duration.inHours > 0 ? "${twoDigits(duration.inHours)}h " : "";
      return "In $h${twoDigits(duration.inMinutes.remainder(60))}m";
    } else {
      int endMinutes = schedule.endMinutes;
      final startMinutes = schedule.startMinutes;
      if (endMinutes < startMinutes) {
        if (currentMinutes >= startMinutes) {
          endMinutes += 1440;
        }
      }
      int targetHour = endMinutes ~/ 60;
      int targetMinute = endMinutes % 60;
      var targetTime =
          DateTime(now.year, now.month, now.day, targetHour, targetMinute);
      if (targetTime.isBefore(now)) {
        targetTime = targetTime.add(const Duration(days: 1));
      }
      final duration = targetTime.difference(now);
      if (duration.isNegative) return "Completed";
      if (duration.inSeconds < 60) return "Ending now";
      String twoDigits(int n) => n.toString().padLeft(2, "0");
      String h = duration.inHours > 0 ? "${twoDigits(duration.inHours)}h " : "";
      return "$h${twoDigits(duration.inMinutes.remainder(60))}m left";
    }
  }

  @override
  void dispose() {
    _classTimer.cancel();
    _scrollController.dispose();
    _bgAnimationController.dispose();
    _speedDialAnimationController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    ref.invalidate(userProvider(widget.userId));
    ref.invalidate(themeProvider);

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const StudentPalLogin()),
      (Route<dynamic> route) => false,
    );
  }

  void _showSingleScheduleDetail(
      BuildContext context, Schedule schedule, Color accent) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: theme.scaffoldBackgroundColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            schedule.subject,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPopupDetailRow(Icons.access_time_filled_rounded, "Time",
                  "${schedule.startTime} - ${schedule.endTime}", accent),
              SizedBox(height: res(context, 12)),
              _buildPopupDetailRow(
                  Icons.location_on_rounded, "Room", schedule.room, accent),
              SizedBox(height: res(context, 12)),
              _buildPopupDetailRow(
                  Icons.calendar_today_rounded, "Days", schedule.days, accent),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Close",
                  style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showAssignmentDetail(
      BuildContext context, Map<String, dynamic> assignment, Color accent) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: theme.scaffoldBackgroundColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            assignment['title'] ?? "Assignment",
            style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w900),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPopupDetailRow(Icons.event_note_rounded, "Deadline",
                  formatDeadline(assignment['deadline']), accent),
              if (assignment['description'] != null) ...[
                SizedBox(height: res(context, 12)),
                Text("Description",
                    style: TextStyle(
                        fontSize: res(context, 10),
                        color: Colors.grey,
                        fontWeight: FontWeight.bold)),
                Text(assignment['description'],
                    style: TextStyle(fontSize: res(context, 14))),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Close",
                  style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPopupDetailRow(
      IconData icon, String label, String value, Color accent) {
    return Row(
      children: [
        Icon(icon, color: accent, size: res(context, 20)),
        SizedBox(width: res(context, 10)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: res(context, 10),
                    color: Colors.grey,
                    fontWeight: FontWeight.bold)),
            Text(value,
                style: TextStyle(
                    fontSize: res(context, 14), fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  void _navigateToSchedulePage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SchedulePage(userId: widget.userId),
      ),
    ).then((_) => _loadDashboardData());
  }

  void _navigateToAssignmentsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssignmentsScreen(userId: widget.userId),
      ),
    ).then((_) => _loadDashboardData());
  }

  void _navigateToProfilePage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(userId: widget.userId),
      ),
    );
  }

  void _showChatModal() {
    showCenteredModal(
      context: context,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          width: MediaQuery.of(context).size.width * 0.9,
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F0F),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 0.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: ChatScreen(userId: widget.userId),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color dynamicAccent = theme.colorScheme.primary;
    final themeState = ref.watch(themeProvider);
    final double scale = themeState.uiScale;
    double r(double v) => v * scale;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          RepaintBoundary(
            child: _buildBackground(dynamicAccent, r),
          ),
          SafeArea(
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              cacheExtent: 500,
              slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor:
                      theme.scaffoldBackgroundColor.withValues(alpha: 0.4),
                  elevation: 0,
                  expandedHeight: r(90),
                  collapsedHeight: r(75),
                  automaticallyImplyLeading: false,
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: EdgeInsets.zero,
                    centerTitle: true,
                    title: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: r(20), vertical: r(10)),
                      child: _buildFloatingHeader(dynamicAccent, r),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: r(20)),
                    child: SizedBox(height: r(10)),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: r(20)),
                    child:
                        _buildSectionTitle("Class Progress", dynamicAccent, r),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        EdgeInsets.only(left: r(20), right: r(20), top: r(15)),
                    child: RepaintBoundary(
                      child: _buildProgressRow(dynamicAccent, r),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        EdgeInsets.only(left: r(20), right: r(20), top: r(30)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildSectionTitle(
                                "Today's Schedule", dynamicAccent, r),
                            TextButton(
                              onPressed: _navigateToSchedulePage,
                              child: Text(
                                "Manage",
                                style: TextStyle(
                                  color: dynamicAccent,
                                  fontSize: r(13),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: r(4)),
                        Text(
                          DateFormat('EEEE, MMMM d').format(DateTime.now()),
                          style: TextStyle(
                            color: dynamicAccent,
                            fontSize: r(12),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        EdgeInsets.only(left: r(20), right: r(20), top: r(15)),
                    child: RepaintBoundary(
                      child: _buildHorizontalSchedule(dynamicAccent, r),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        EdgeInsets.only(left: r(20), right: r(20), top: r(30)),
                    child: _buildSectionTitle(
                      "Assignments",
                      dynamicAccent,
                      r,
                      trailing: "View All",
                      onTrailingTap: _navigateToAssignmentsPage,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        EdgeInsets.only(left: r(20), right: r(20), top: r(15)),
                    child: _recentAssignments.isEmpty
                        ? RepaintBoundary(
                            child: _buildAssignmentCard({
                              "title": "No Assignments",
                              "deadline": "Free day!"
                            }, dynamicAccent, r),
                          )
                        : Column(
                            children: _recentAssignments
                                .map(
                                  (a) => RepaintBoundary(
                                      child: _buildAssignmentCard(
                                          a, dynamicAccent, r)),
                                )
                                .toList(),
                          ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        EdgeInsets.only(left: r(20), right: r(20), top: r(30)),
                    child: _buildSectionTitle("Resources", dynamicAccent, r),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(
                        left: r(20), right: r(20), top: r(15)),
                    child: RepaintBoundary(
                      child: _buildResourcesGrid(dynamicAccent, r),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: r(40)),
                  ),
                ),
              ],
            ),
          ),
          _buildSpeedDial(dynamicAccent),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() { _selectedIndex = index; });
          if (index == 1) {
            _navigateToSchedulePage();
          } else if (index == 2) {
            _navigateToAssignmentsPage();
          } else if (index == 3) {
            _navigateToProfilePage();
          }
        },
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        type: BottomNavigationBarType.fixed,
        backgroundColor: theme.cardColor,
        elevation: 8,
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

  Widget _buildFloatingHeader(Color accent, double Function(double) r) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final themeState = ref.watch(themeProvider);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Hello!",
                  style: TextStyle(
                      color: accent,
                      fontSize: r(9),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5)),
              Text(_capitalize(themeState.username),
                  style: TextStyle(
                      color: onSurface,
                      fontSize: r(15),
                      fontWeight: FontWeight.w900),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1),
            ],
          ),
        ),
        LiveClockWidget(r: r, accent: accent, userId: widget.userId),
        SizedBox(width: r(8)),
        _buildProfileAvatar(onSurface, accent, r),
      ],
    );
  }

  Widget _buildProfileAvatar(
      Color onSurface, Color accent, double Function(double) r) {
    final theme = Theme.of(context);
    return PopupMenuButton<int>(
      offset: Offset(0, r(45)),
      color: theme.cardColor,
      elevation: 8,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: onSurface.withValues(alpha: 0.05))),
      onSelected: (value) {
        if (value == 0) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ProfileScreen(userId: widget.userId)));
        } else if (value == 1) {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()));
        } else if (value == 2) {
          _handleLogout();
        }
      },
      itemBuilder: (context) => [
        _buildPopupItem(0, Icons.person_rounded, "My Profile", accent, r),
        const PopupMenuDivider(height: 1),
        _buildPopupItem(1, Icons.settings_rounded, "Settings", accent, r),
        const PopupMenuDivider(height: 1),
        _buildPopupItem(2, Icons.logout_rounded, "Logout", accent, r,
            isDestructive: true),
      ],
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            border:
                Border.all(color: accent.withValues(alpha: 0.2), width: 1.5)),
        child: Consumer(
          builder: (context, ref, _) {
            final userAsync = ref.watch(userProvider(widget.userId));
            final profileImagePath = userAsync.asData?.value?['profilePath'] as String?;
            return CircleAvatar(
              radius: r(14),
              backgroundColor: accent.withValues(alpha: 0.1),
              backgroundImage: (profileImagePath != null &&
                      File(profileImagePath).existsSync())
                  ? FileImage(File(profileImagePath))
                  : null,
              child: (profileImagePath == null ||
                      !File(profileImagePath).existsSync())
                  ? Icon(Icons.person_rounded, color: accent, size: r(16))
                  : null,
            );
          },
        ),
      ),
    );
  }

  PopupMenuItem<int> _buildPopupItem(int value, IconData icon, String title,
      Color accent, double Function(double) r,
      {bool isDestructive = false}) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon,
              color: isDestructive ? Colors.redAccent : accent, size: r(18)),
          SizedBox(width: r(12)),
          Text(title,
              style: TextStyle(
                  fontSize: r(13),
                  fontWeight: FontWeight.w600,
                  color: isDestructive ? Colors.redAccent : null)),
        ],
      ),
    );
  }

  Widget _buildBackground(Color accent, double Function(double) r) {
    return AnimatedBuilder(
      animation: _bgAnimationController,
      builder: (context, child) {
        return Stack(
          children: [
            _buildAnimatedBlob(
                Alignment(0.7 + 0.1 * (_bgAnimationController.value), -0.8),
                accent,
                r(350)),
            _buildAnimatedBlob(
                Alignment(-0.8, 0.6 + 0.1 * (_bgAnimationController.value)),
                accent,
                r(450)),
          ],
        );
      },
    );
  }

  Widget _buildAnimatedBlob(Alignment align, Color color, double size) {
    return Align(
      alignment: align,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              color.withValues(alpha: 0.12),
              color.withValues(alpha: 0)
            ])),
      ),
    );
  }

  Widget _buildSectionTitle(
      String title, Color accent, double Function(double) r,
      {String? trailing, VoidCallback? onTrailingTap}) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(title,
            style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: r(20),
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5)),
        if (trailing != null)
          InkWell(
            onTap: onTrailingTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(trailing,
                    style: TextStyle(
                        color: accent,
                        fontSize: r(13),
                        fontWeight: FontWeight.w800))),
          ),
      ],
    );
  }

  Widget _buildProgressRow(Color accent, double Function(double) r) {
    final now = DateTime.now();
    double progress = 0.0;
    if (_currentClass != null) {
      final startTime = _parseTime(_currentClass!.startTime);
      final endTime = _parseTime(_currentClass!.endTime);
      final totalDuration = endTime.difference(startTime).inSeconds;
      final elapsed = now.difference(startTime).inSeconds;
      if (totalDuration > 0) {
        progress = (elapsed / totalDuration).clamp(0.0, 1.0);
      }
    }

    return Row(
      children: [
        Expanded(
            child: GestureDetector(
                child: _buildCountdownCard(
                    "CURRENT",
                    _currentClass?.subject ?? "Free Time",
                    _formatCountdown(_currentClass),
                    accent.withValues(alpha: 0.4),
                    r,
                    isActive: _currentClass != null,
                    showProgress: _currentClass != null,
                    progress: progress,
                    cardAccent: accent))),
        SizedBox(width: r(14)),
        Expanded(
            child: GestureDetector(
                child: _buildCountdownCard(
                    "UPCOMING",
                    _nextClass?.subject ?? "None Scheduled",
                    _formatCountdown(_nextClass, isNext: true),
                    accent,
                    r,
                    isActive: true,
                    showClock: true,
                    cardAccent: accent))),
      ],
    );
  }

  Widget _buildCountdownCard(String label, String className, String time,
      Color accent, double Function(double) r,
      {bool isActive = false,
      bool showProgress = false,
      double progress = 0.0,
      bool showClock = false,
      Color? cardAccent}) {
    final theme = Theme.of(context);
    final cardAccentColor = cardAccent ?? Colors.grey;
    final statusColor = label == "CURRENT"
        ? (isActive ? Colors.green : Colors.grey)
        : Colors.grey;
    final statusText = isActive ? "LIVE" : "FREE";

    return _buildGlassContainer(
      borderColor: isActive ? accent.withValues(alpha: 0.4) : null,
      r: r,
      child: Padding(
        padding: EdgeInsets.all(r(18)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: r(6),
                  height: r(6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: r(4)),
                Text(
                  "● $statusText",
                  style: TextStyle(
                    color: statusColor,
                    fontSize: r(10),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            SizedBox(height: r(10)),
            Text(className,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: r(15),
                  fontWeight: FontWeight.w800),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            SizedBox(height: r(4)),
            if (showClock)
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    size: r(11),
                  ),
                  SizedBox(width: r(4)),
                  Text(time,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: r(11),
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace')),
                ],
              )
            else
              Text(time,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: r(11),
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace')),
            if (showProgress) ...[
              SizedBox(height: r(8)),
              ClipRRect(
                borderRadius: BorderRadius.circular(r(2)),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: cardAccentColor.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(cardAccentColor),
                  minHeight: r(4),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalSchedule(Color accent, double Function(double) r) {
    final theme = Theme.of(context);
    if (_todaySchedules.isEmpty) {
      return _buildGlassContainer(
        r: r,
        child: Center(
            child: Padding(
                padding: EdgeInsets.all(r(20)),
                child: Text("No classes scheduled.",
                    style: TextStyle(
                        fontSize: r(14),
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface)))),
      );
    }
    return SizedBox(
      height: r(120),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _todaySchedules.length,
        itemBuilder: (context, index) {
          final item = _todaySchedules[index];
          final onSurface = theme.colorScheme.onSurface;
          final now = DateTime.now();
          final isCurrentClass = _currentClass != null &&
              _currentClass!.id == item.id;
          final isPast =
              _parseTime(item.endTime).isBefore(now);

          Color leftBorderColor;
          if (isCurrentClass) {
            leftBorderColor = accent;
          } else if (isPast) {
            leftBorderColor = Colors.grey.withValues(alpha: 0.4);
          } else {
            leftBorderColor = accent.withValues(alpha: 0.3);
          }

          return Padding(
            padding: EdgeInsets.only(right: r(12)),
            child: InkWell(
              onTap: () => _showSingleScheduleDetail(context, item, accent),
              borderRadius: BorderRadius.circular(r(16)),
              child: Container(
                width: r(140),
                decoration: BoxDecoration(
                  color: theme.cardColor.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(r(16)),
                  border: Border.all(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(r(16)),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: leftBorderColor,
                          width: r(3),
                        ),
                      ),
                    ),
                    padding: EdgeInsets.all(r(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isCurrentClass) ...[
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: r(6), vertical: r(2)),
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(r(4)),
                            ),
                            child: Text(
                              "NOW",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: r(8),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: r(4)),
                        ],
                        Text(item.subject,
                            style: TextStyle(
                                color: onSurface,
                                fontWeight: FontWeight.bold,
                                fontSize: r(13)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        SizedBox(height: r(4)),
                        Text("${item.displayStartTime} - ${item.displayEndTime}",
                            style: TextStyle(
                                color: onSurface.withValues(alpha: 0.6),
                                fontSize: r(10))),
                        SizedBox(height: r(8)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4)),
                          child: Text(item.room,
                              style: TextStyle(
                                  color: accent,
                                  fontSize: r(9),
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAssignmentCard(Map<String, dynamic> assignment, Color accent,
      double Function(double) r) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: r(10)),
      child: _buildGlassContainer(
        r: r,
        child: ListTile(
          onTap: () => _showAssignmentDetail(context, assignment, accent),
          contentPadding: EdgeInsets.symmetric(horizontal: r(15)),
          title: Text(
            assignment['title'] ?? "Untitled",
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: r(14)),
          ),
          subtitle: Text(
            "Due: ${formatDeadline(assignment['deadline'])}",
            style: TextStyle(
              color: _getDeadlineColor(assignment['deadline'],
                  theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              fontSize: r(12)),
          ),
          trailing: Icon(Icons.chevron_right, color: accent),
        ),
      ),
    );
  }

  Widget _buildResourcesGrid(Color accent, double Function(double) r) {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 1.1,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: r(10),
      crossAxisSpacing: r(10),
      children: [
        _buildResourceGridCard(
          "Study Notes",
          Icons.note_alt_rounded,
          "Manage your notes",
          accent,
          r,
          () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => NotesScreen(userId: widget.userId)),
          ).then((_) => _loadDashboardData()),
        ),
        _buildResourceGridCard(
          "Flashcards",
          Icons.style_rounded,
          "Review your decks",
          accent,
          r,
          () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => FlashcardsScreen(userId: widget.userId)),
          ),
        ),
        _buildResourceGridCard(
          "Sample Quizzes",
          Icons.psychology_alt_rounded,
          "Test your knowledge",
          accent,
          r,
          () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => QuizzesScreen(userId: widget.userId)),
          ),
        ),
        _buildResourceGridCard(
          "Summaries",
          Icons.article_outlined,
          "Quick review",
          accent,
          r,
          () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => SummariesScreen(userId: widget.userId)),
          ),
        ),
        _buildResourceGridCard(
          "Library Access",
          Icons.local_library_rounded,
          "Digital archives",
          accent,
          r,
          () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ResourcesScreen(userId: widget.userId)),
          ),
        ),
        _buildResourceGridCard(
          "AI Tutor",
          Icons.auto_awesome_rounded,
          "Get help now",
          accent,
          r,
          _showChatModal,
        ),
      ],
    );
  }

  Widget _buildResourceGridCard(String title, IconData icon, String subtitle,
      Color accent, double Function(double) r, VoidCallback onTap) {
    final theme = Theme.of(context);
    return _buildGlassContainer(
      r: r,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(r(16)),
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(r(8)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: accent, size: r(28)),
                  SizedBox(height: r(8)),
                  Text(
                    title,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: r(13),
                    ),
                    maxLines: 1,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: r(4)),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: r(10),
                    ),
                    maxLines: 1,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassContainer(
      {Widget? child,
      double? width,
      double borderRadius = 16,
      Color? borderColor,
      required double Function(double) r}) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
            color: borderColor ??
                theme.colorScheme.onSurface.withValues(alpha: 0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: child ?? const SizedBox(),
      ),
    );
  }

  Widget _buildSpeedDial(Color accent) {
    final theme = Theme.of(context);
    final themeState = ref.watch(themeProvider);
    final double scale = themeState.uiScale;
    double r(double v) => v * scale;

    return Positioned(
      bottom: 20,
      right: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.translate(
            offset: Offset(0, _isSpeedDialExpanded
                ? _speedDialAnimationController.value * 70
                : 0),
            child: Opacity(
              opacity: _isSpeedDialExpanded
                  ? _speedDialAnimationController.value
                  : 0,
              child: FloatingActionButton(
                heroTag: "speed_dial_1",
                mini: true,
                backgroundColor: theme.cardColor,
                onPressed: () {
                  setState(() { _isSpeedDialExpanded = false; });
                  _speedDialAnimationController.reverse();
                  _showChatModal();
                },
                child: Icon(Icons.auto_awesome, color: accent, size: 20),
              ),
            ),
          ),
          SizedBox(height: r(10)),
          Transform.translate(
            offset: Offset(0, _isSpeedDialExpanded
                ? _speedDialAnimationController.value * 70
                : 0),
            child: Opacity(
              opacity: _isSpeedDialExpanded
                  ? _speedDialAnimationController.value
                  : 0,
              child: FloatingActionButton(
                heroTag: "speed_dial_2",
                mini: true,
                backgroundColor: theme.cardColor,
                onPressed: () {
                  setState(() { _isSpeedDialExpanded = false; });
                  _speedDialAnimationController.reverse();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AssignmentsScreen(userId: widget.userId),
                    ),
                  ).then((_) => _loadDashboardData());
                },
                child: Icon(Icons.assignment_add, color: accent, size: 20),
              ),
            ),
          ),
          SizedBox(height: r(10)),
          FloatingActionButton(
            heroTag: "speed_dial_main",
            backgroundColor: accent,
            onPressed: () {
              setState(() { _isSpeedDialExpanded = !_isSpeedDialExpanded; });
              if (_isSpeedDialExpanded) {
                _speedDialAnimationController.forward();
              } else {
                _speedDialAnimationController.reverse();
              }
            },
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class AIFloatingChatHead extends StatelessWidget {
  final VoidCallback onPressed;
  const AIFloatingChatHead({super.key, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      right: 20,
      child: FloatingActionButton(
          heroTag: "ai_chat_btn",
          backgroundColor: Theme.of(context).primaryColor,
          elevation: 6,
          onPressed: onPressed,
          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 30)),
    );
  }
}