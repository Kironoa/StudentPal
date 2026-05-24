import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/helper/db_helper.dart';
import 'package:mobile_app/models/reminder_model.dart';
import 'package:mobile_app/providers/theme_provider.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  final int userId;
  final bool showAsModal;

  const CalendarScreen({super.key, required this.userId, this.showAsModal = false});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  Map<DateTime, List<Reminder>> _remindersByDate = {};
  List<Reminder> _selectedDayReminders = [];

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _loadRemindersForMonth(_focusedDay);
  }

  Future<void> _loadRemindersForMonth(DateTime date) async {
    final start = DateTime(date.year, date.month);
    final end = DateTime(date.year, date.month + 1);

    final maps = await DatabaseHelper().getRemindersForDateRange(
      widget.userId,
      start,
      end,
    );

    final reminders = maps.map((map) => Reminder.fromMap(map));

    final Map<DateTime, List<Reminder>> grouped = {};
    for (var reminder in reminders) {
      final dateKey = DateTime(
        reminder.reminderTime.year,
        reminder.reminderTime.month,
        reminder.reminderTime.day,
      );
      grouped.putIfAbsent(dateKey, () => []).add(reminder);
    }

    if (!mounted) return;
    setState(() {
      _remindersByDate = grouped;
      _updateSelectedDayReminders();
    });
  }

  void _updateSelectedDayReminders() {
    final dateKey = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    );
    _selectedDayReminders = _remindersByDate[dateKey] ?? [];
  }

  List<Reminder> _getRemindersForDay(DateTime day) {
    final dateKey = DateTime(day.year, day.month, day.day);
    return _remindersByDate[dateKey] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _updateSelectedDayReminders();
    });

    final reminders = _getRemindersForDay(selectedDay);
    if (reminders.isNotEmpty) {
      _showRemindersBottomSheet(reminders);
    }
  }

  void _showRemindersBottomSheet(List<Reminder> reminders) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Reminders for ${DateFormat.yMMMd().format(_selectedDay)}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...reminders.map((reminder) => _buildReminderTile(reminder)),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderTile(Reminder reminder) {
    final timeFormat = DateFormat.jm();
    final accentColor = ref.watch(themeProvider).accentColor;

    return Card(
      child: ListTile(
        title: Text(reminder.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(timeFormat.format(reminder.reminderTime)),
            if (reminder.note != null && reminder.note!.isNotEmpty)
              Text(
                reminder.note!,
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: accentColor),
              onPressed: () {
                Navigator.pop(context);
                _showEditReminderDialog(reminder);
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                Navigator.pop(context);
                _showDeleteConfirmation(reminder);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddReminderDialog() {
    final titleController = TextEditingController();
    final noteController = TextEditingController();
    DateTime selectedDate = _selectedDay;
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Reminder'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(DateFormat.yMMMd().format(selectedDate)),
                    ),
                    TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 365),
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (date != null) {
                          setState(() => selectedDate = date);
                        }
                      },
                      child: const Text('Change Date'),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(selectedTime.format(context)),
                    ),
                    TextButton(
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (time != null) {
                          setState(() => selectedTime = time);
                        }
                      },
                      child: const Text('Change Time'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) {
                  return;
                }

                final dateTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );

                Navigator.of(context).pop();
                await DatabaseHelper().insertReminder(
                  Reminder(
                    userId: widget.userId,
                    title: titleController.text.trim(),
                    reminderTime: dateTime,
                    note: noteController.text.trim().isEmpty
                        ? null
                        : noteController.text.trim(),
                    createdAt: DateTime.now(),
                  ),
                );

                if (mounted) {
                  _loadRemindersForMonth(_focusedDay);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditReminderDialog(Reminder reminder) {
    final titleController = TextEditingController(text: reminder.title);
    final noteController = TextEditingController(text: reminder.note ?? '');
    DateTime selectedDate = reminder.reminderTime;
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(reminder.reminderTime);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Reminder'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(DateFormat.yMMMd().format(selectedDate)),
                    ),
                    TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 365),
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (date != null) {
                          setState(() => selectedDate = date);
                        }
                      },
                      child: const Text('Change Date'),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(selectedTime.format(context)),
                    ),
                    TextButton(
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (time != null) {
                          setState(() => selectedTime = time);
                        }
                      },
                      child: const Text('Change Time'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) {
                  return;
                }

                final dateTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );

                final updatedReminder = reminder.copyWith(
                  title: titleController.text.trim(),
                  reminderTime: dateTime,
                  note: noteController.text.trim().isEmpty
                      ? null
                      : noteController.text.trim(),
                );

                Navigator.of(context).pop();
                await DatabaseHelper().updateReminder(updatedReminder);

                if (mounted) {
                  _loadRemindersForMonth(_focusedDay);
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Reminder reminder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: const Text('Are you sure you want to delete this reminder?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await DatabaseHelper().deleteReminder(reminder.id!);

              if (mounted) {
                _loadRemindersForMonth(_focusedDay);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProvider);
    final accentColor = themeState.accentColor;

    final content = Column(
      children: [
        if (widget.showAsModal)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Calendar',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        TableCalendar<Reminder>(
          firstDay: DateTime.utc(2020),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          calendarFormat: _calendarFormat,
          eventLoader: _getRemindersForDay,
          onDaySelected: _onDaySelected,
          onFormatChanged: (format) {
            setState(() {
              _calendarFormat = format;
            });
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
            _loadRemindersForMonth(focusedDay);
          },
          calendarStyle: CalendarStyle(
            markerDecoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
          ),
          calendarBuilders: CalendarBuilders<Reminder>(
            markerBuilder: (context, date, reminders) {
              if (reminders.isNotEmpty) {
                return Positioned(
                  bottom: 1,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.cyan,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }
              return null;
            },
          ),
          headerStyle: const HeaderStyle(
            titleCentered: true,
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Reminders for ${DateFormat.yMMMd().format(_selectedDay)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _selectedDayReminders.isEmpty
              ? Center(
                    child: Text(
                      'No reminders for this day',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                    ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _selectedDayReminders.length,
                  itemBuilder: (context, index) {
                    final reminder = _selectedDayReminders[index];
                    return _buildReminderTile(reminder);
                  },
                ),
        ),
      ],
    );

    if (widget.showAsModal) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        backgroundColor: accentColor,
      ),
      body: content,
      floatingActionButton: FloatingActionButton(
        heroTag: "add_reminder",
        onPressed: _showAddReminderDialog,
        backgroundColor: accentColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}
