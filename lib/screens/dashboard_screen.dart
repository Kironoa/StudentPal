import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_app/models/schedule_model.dart';
import 'package:mobile_app/helper/db_helper.dart';
import 'package:mobile_app/screens/resource_screen.dart' hide res;
import 'package:mobile_app/screens/schedule_screen.dart' hide res;
import 'package:mobile_app/screens/settings_screen.dart';
import 'package:mobile_app/providers/theme_provider.dart';
import 'package:mobile_app/services/notification_service.dart';
import 'package:mobile_app/screens/notes_screen.dart' hide res;
import 'package:mobile_app/screens/assignments_screen.dart' hide res;
import 'package:mobile_app/screens/chat_screen.dart' hide res;
import 'package:mobile_app/screens/quizzes_screen.dart' hide res;
import 'package:mobile_app/screens/flashcards_screen.dart' hide res;
import 'package:mobile_app/screens/summaries_screen.dart' hide res;
import 'package:mobile_app/screens/login_screen.dart';

class LiveClockWidget extends StatefulWidget {
  final double Function(double) r;
  final Color accent;

  const LiveClockWidget({super.key, required this.r, required this.accent});

  @override
  State<LiveClockWidget> createState() => _LiveClockWidgetState();
}

class _LiveClockWidgetState extends State<LiveClockWidget> {
  late Timer _clockTimer;
  String _timeString = DateFormat('hh:mm:ss a').format(DateTime.now());
  String _dateString = DateFormat('EEE, MMM dd, yyyy').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _timeString = DateFormat('hh:mm:ss a').format(DateTime.now());
          _dateString = DateFormat('EEE, MMM dd, yyyy').format(DateTime.now());
        });
      }
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: onSurface.withValues(alpha: 0.1)),
      ),
      padding:
          EdgeInsets.symmetric(horizontal: widget.r(10), vertical: widget.r(6)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_timeString.split(' ')[0],
                  style: TextStyle(
                      color: onSurface,
                      fontSize: widget.r(11),
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace')),
              SizedBox(width: widget.r(3)),
              Text(_timeString.split(' ')[1],
                  style: TextStyle(
                      color: widget.accent,
                      fontSize: widget.r(8),
                      fontWeight: FontWeight.w900)),
            ],
          ),
          Text(_dateString.toUpperCase(),
              style: TextStyle(
                  color: onSurface.withValues(alpha: 0.6),
                  fontSize: widget.r(7),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5)),
        ],
      ),
    );
  }
}

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
  late ScrollController _scrollController;
  String? _profileImagePath;

  final ImagePicker _picker = ImagePicker();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final NotificationService _notifService = NotificationService();

  List<Schedule> _todaySchedules = [];
  List<Map<String, dynamic>> _recentAssignments = [];
  Schedule? _currentClass;
  Schedule? _nextClass;

  void initState() {
    super.initState();
    _fetchUserData();
    _loadDashboardData();
    _scrollController = ScrollController(keepScrollOffset: true);
    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  double res(BuildContext context, double value) => value;

  Future<void> _fetchUserData() async {
    final user = await _dbHelper.getUser(widget.userId);
    if (user != null) {
      if (user['profilePath'] != null) {
        setState(() => _profileImagePath = user['profilePath']);
      }
      final username = user['username'] as String?;
      if (username != null && username.isNotEmpty) {
        await DatabaseHelper().saveSettings(name: username);
        ref.read(themeProvider.notifier).loadSettings();
      }
    }
  }

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
    debugPrint("Current time: $now");
    Schedule? foundCurrent;
    Schedule? foundNext;
    Duration minNextGap = const Duration(days: 1);

    for (var schedule in _todaySchedules) {
      final start = _parseTime(schedule.startTime);
      final end = _parseTime(schedule.endTime);
      debugPrint("Schedule ${schedule.subject}: start=$start, end=$end");
      if (now.isAfter(start) && now.isBefore(end)) {
        debugPrint("  -> Matched as current");
        foundCurrent = schedule;
      }
      if (start.isAfter(now)) {
        final gap = start.difference(now);
        debugPrint("  -> Gap: $gap");
        if (gap < minNextGap) {
          debugPrint("  -> New next (gap: $gap)");
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
    super.dispose();
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const StudentPalLogin()),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      await _dbHelper.updateUserProfilePhoto(widget.userId, pickedFile.path);
      setState(() => _profileImagePath = pickedFile.path);
    }
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
                    child: _buildSectionTitle(
                      "Today's Schedule",
                      dynamicAccent,
                      r,
                      trailing: "Manage",
                      onTrailingTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SchedulePage(userId: widget.userId),
                        ),
                      ).then((_) => _loadDashboardData()),
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
                      onTrailingTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AssignmentsScreen(userId: widget.userId),
                        ),
                      ).then((_) => _loadDashboardData()),
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
                    padding:
                        EdgeInsets.only(left: r(20), right: r(20), top: r(15)),
                    child: RepaintBoundary(
                      child: _buildResourceTile(
                        "Study Notes",
                        Icons.note_alt_rounded,
                        "Manage your quick notes",
                        dynamicAccent,
                        r,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  NotesScreen(userId: widget.userId)),
                        ).then((_) => _loadDashboardData()),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(left: r(20), right: r(20)),
                    child: RepaintBoundary(
                      child: _buildResourceTile(
                        "Flashcards",
                        Icons.style_rounded,
                        "Review your active decks",
                        dynamicAccent,
                        r,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  FlashcardsScreen(userId: widget.userId)),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(left: r(20), right: r(20)),
                    child: RepaintBoundary(
                      child: _buildResourceTile(
                        "Sample Quizzes",
                        Icons.psychology_alt_rounded,
                        "Test your knowledge",
                        dynamicAccent,
                        r,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  QuizzesScreen(userId: widget.userId)),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(left: r(20), right: r(20)),
                    child: RepaintBoundary(
                      child: _buildResourceTile(
                        "Summaries",
                        Icons.article_outlined,
                        "Quick review of key points",
                        dynamicAccent,
                        r,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  SummariesScreen(userId: widget.userId)),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(left: r(20), right: r(20)),
                    child: RepaintBoundary(
                      child: _buildResourceTile(
                        "Library Access",
                        Icons.local_library_rounded,
                        "Digital archives available",
                        dynamicAccent,
                        r,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  ResourcesScreen(userId: widget.userId)),
                        ),
                      ),
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
          AIFloatingChatHead(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                clipBehavior: Clip.antiAliasWithSaveLayer,
                useSafeArea: true,
                builder: (context) => const ChatScreen(),
              );
            },
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
        LiveClockWidget(r: r, accent: accent),
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
        if (value == 1) _pickImage();
        if (value == 2)
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()));
        if (value == 3) _handleLogout();
      },
      itemBuilder: (context) => [
        _buildPopupItem(1, Icons.image_outlined, "Change Photo", accent, r),
        _buildPopupItem(2, Icons.settings_rounded, "Settings", accent, r),
        const PopupMenuDivider(height: 1),
        _buildPopupItem(3, Icons.logout_rounded, "Logout", accent, r,
            isDestructive: true),
      ],
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            border:
                Border.all(color: accent.withValues(alpha: 0.2), width: 1.5)),
        child: CircleAvatar(
          radius: r(14),
          backgroundColor: accent.withValues(alpha: 0.1),
          backgroundImage: (_profileImagePath != null &&
                  File(_profileImagePath!).existsSync())
              ? FileImage(File(_profileImagePath!))
              : null,
          child: (_profileImagePath == null ||
                  !File(_profileImagePath!).existsSync())
              ? Icon(Icons.person_rounded, color: accent, size: r(16))
              : null,
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
                    isActive: _currentClass != null))),
        SizedBox(width: r(14)),
        Expanded(
            child: GestureDetector(
                child: _buildCountdownCard(
                    "UPCOMING",
                    _nextClass?.subject ?? "None Scheduled",
                    _formatCountdown(_nextClass, isNext: true),
                    accent,
                    r,
                    isActive: true))),
      ],
    );
  }

  Widget _buildCountdownCard(String label, String className, String time,
      Color accent, double Function(double) r,
      {bool isActive = false}) {
    final theme = Theme.of(context);
    return _buildGlassContainer(
      borderColor: isActive ? accent.withValues(alpha: 0.4) : null,
      r: r,
      child: Padding(
        padding: EdgeInsets.all(r(18)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    color: accent,
                    fontSize: r(10),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5)),
            SizedBox(height: r(10)),
            Text(className,
                style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: r(15),
                    fontWeight: FontWeight.w800),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            SizedBox(height: r(4)),
            Text(time,
                style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: r(11),
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace')),
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
          return Padding(
            padding: EdgeInsets.only(right: r(12)),
            child: InkWell(
              onTap: () => _showSingleScheduleDetail(context, item, accent),
              borderRadius: BorderRadius.circular(16),
              child: _buildGlassContainer(
                width: r(140),
                r: r,
                child: Padding(
                  padding: EdgeInsets.all(r(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
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
                color: _getDeadlineColor(assignment['deadline'], theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                fontSize: r(12)),
          ),
          trailing: Icon(Icons.chevron_right, color: accent),
        ),
      ),
    );
  }

  Widget _buildResourceTile(String title, IconData icon, String sub,
      Color accent, double Function(double) r,
      {VoidCallback? onTap}) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: r(10)),
      child: _buildGlassContainer(
        r: r,
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon, color: accent),
          title: Text(title,
              style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: r(14))),
          subtitle: Text(sub,
              style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: r(11))),
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
