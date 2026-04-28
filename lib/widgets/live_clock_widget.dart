import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/services/notification_service.dart';
import 'package:mobile_app/helper/db_helper.dart';

class LiveClockWidget extends StatefulWidget {
  final double Function(double) r;
  final Color accent;
  final int userId;

  const LiveClockWidget({super.key, required this.r, required this.accent, required this.userId});

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
    return GestureDetector(
      onTap: () => _showCalendarDialog(context, widget.userId),
      child: Container(
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
      ),
    );
  }

  void _showCalendarDialog(BuildContext context, int userId) {
    final now = DateTime.now();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.accent.withValues(alpha: 0.3),
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
                        color: widget.accent,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 1.2,
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.close_rounded,
                        color: Theme.of(context)
                          .colorScheme.onSurface
                          .withValues(alpha: 0.5),
                        size: 18),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              CalendarWidget(
                accent: widget.accent,
                today: now,
                userId: userId,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CalendarWidget extends StatefulWidget {
  final Color accent;
  final DateTime today;
  final int userId;
  const CalendarWidget(
    {super.key, required this.accent, required this.today, required this.userId});

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  late DateTime _displayed;
  Map<DateTime, List<Map<String, dynamic>>> _remindersByDate = {};

  @override
  void initState() {
    super.initState();
    _displayed = DateTime(widget.today.year, widget.today.month);
    _loadReminders();
  }

  @override
  void didUpdateWidget(covariant CalendarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId || oldWidget.today != widget.today) {
      _loadReminders();
    }
  }

  Future<void> _loadReminders() async {
    final data = await DatabaseHelper().getRemindersForMonth(
      widget.userId, _displayed.year, _displayed.month);
    if (mounted) setState(() => _remindersByDate = data);
  }

  void _prev() {
    setState(() {
      _displayed = DateTime(_displayed.year, _displayed.month - 1);
      _loadReminders();
    });
  }

  void _next() {
    setState(() {
      _displayed = DateTime(_displayed.year, _displayed.month + 1);
      _loadReminders();
    });
  }

  bool _hasReminder(DateTime date) {
    final key = DateTime(date.year, date.month, date.day);
    return _remindersByDate.containsKey(key);
  }

  List<Map<String, dynamic>> _getRemindersForDay(DateTime date) {
    final key = DateTime(date.year, date.month, date.day);
    return _remindersByDate[key] ?? [];
  }

  void _onDayTapped(BuildContext context, DateTime date) {
    if (date.isBefore(DateTime.now().subtract(const Duration(days: 1)))) return;
    final reminders = _getRemindersForDay(date);
    if (reminders.isNotEmpty) {
      _showRemindersBottomSheet(context, date, reminders);
      return;
    }
    _showSetReminderDialog(context, date);
  }

  void _showRemindersBottomSheet(BuildContext context, DateTime date, List<Map<String, dynamic>> reminders) {
    final theme = Theme.of(context);
    final reminderWidgets = reminders.map((r) {
      final reminderTime = DateTime.tryParse(r['reminderTime'] ?? '');
      final timeStr = reminderTime != null ? DateFormat('h:mm a').format(reminderTime) : '';
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.notifications_active_rounded, color: widget.accent, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(timeStr, style: TextStyle(color: theme.hintColor, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: widget.accent.withValues(alpha: 0.3)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 16),
            Text(DateFormat('EEE, MMM d').format(date),
              style: TextStyle(fontWeight: FontWeight.w900, color: widget.accent, fontSize: 16)),
            const SizedBox(height: 12),
            ...reminderWidgets,
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('CLOSE', style: TextStyle(color: widget.accent, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }

  void _showSetReminderDialog(BuildContext context, DateTime date) {
    if (date.isBefore(DateTime.now().subtract(const Duration(days: 1)))) return;
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) {
        final titleController = TextEditingController();
        TimeOfDay selectedTime = TimeOfDay.now();
        return StatefulBuilder(
          builder: (ctx, setS) {
            return AlertDialog(
              backgroundColor: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(DateFormat('EEE, MMM d').format(date), style: TextStyle(fontWeight: FontWeight.w900, color: widget.accent, fontSize: 15)),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(controller: titleController, decoration: InputDecoration(hintText: 'Reminder title', hintStyle: TextStyle(color: theme.hintColor), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                const SizedBox(height: 12),
                ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.access_time_rounded, color: widget.accent), title: Text(selectedTime.format(ctx), style: const TextStyle(fontWeight: FontWeight.w600)), onTap: () async { final t = await showTimePicker(context: ctx, initialTime: selectedTime); if (t != null) setS(() => selectedTime = t); }),
              ]),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: Text('CANCEL', style: TextStyle(color: theme.hintColor))),
                TextButton(onPressed: () async {
                  final title = titleController.text.trim();
                  if (title.isEmpty) return;
                  final reminderTime = DateTime(date.year, date.month, date.day, selectedTime.hour, selectedTime.minute);
                  if (reminderTime.isBefore(DateTime.now())) {
                    if (ctx.mounted) Navigator.pop(ctx);
                    return;
                  }
                  try {
                    final id = await DatabaseHelper().insertReminder(widget.userId, title, reminderTime);
                    await NotificationService().scheduleNoteReminders(noteId: id, noteTitle: title, reminderTime: reminderTime);
                    await _loadReminders();
                  } catch (_) {}
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Reminder set: $title', style: const TextStyle(color: Colors.white)),
                        backgroundColor: widget.accent,
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                }, child: Text('SET', style: TextStyle(color: widget.accent, fontWeight: FontWeight.w900))),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final daysInMonth = DateUtils.getDaysInMonth(
      _displayed.year, _displayed.month);
    final firstWeekday = DateTime(
      _displayed.year, _displayed.month, 1).weekday % 7;

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity == null) return;
        if (details.primaryVelocity! < -200) {
          _next();
        } else if (details.primaryVelocity! > 200) {
          _prev();
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _prev,
                icon: Icon(Icons.chevron_left_rounded,
                  color: onSurface.withValues(alpha: 0.6))),
              Text(
                DateFormat('MMMM yyyy').format(_displayed),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: onSurface),
              ),
              IconButton(
                onPressed: _next,
                icon: Icon(Icons.chevron_right_rounded,
                  color: onSurface.withValues(alpha: 0.6))),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['S','M','T','W','T','F','S'].map((d) =>
              SizedBox(
                width: 32,
                child: Text(d,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: onSurface.withValues(alpha: 0.4))),
              )
            ).toList(),
          ),
          const SizedBox(height: 6),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
              childAspectRatio: 1,
            ),
            itemCount: firstWeekday + daysInMonth,
            itemBuilder: (ctx, i) {
              if (i < firstWeekday) return const SizedBox();
              final day = i - firstWeekday + 1;
              final date = DateTime(_displayed.year, _displayed.month, day);
              final isToday = day == widget.today.day &&
                _displayed.month == widget.today.month &&
                _displayed.year == widget.today.year;
              final isPast = date.isBefore(DateTime.now().subtract(const Duration(days: 1)));
              final hasReminder = _hasReminder(date);
              return GestureDetector(
                onTap: isPast ? null : () => _onDayTapped(context, date),
                child: Container(
                  decoration: BoxDecoration(
                    color: isToday
                      ? widget.accent
                      : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isToday
                              ? FontWeight.w900 : FontWeight.normal,
                            color: isToday
                              ? Colors.white
                              : onSurface.withValues(alpha: isPast ? 0.3 : 0.8)),
                        ),
                        if (hasReminder)
                          Positioned(
                            bottom: -2,
                            child: Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}