import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/models/class_model.dart';
import 'package:mobile_app/repositories/class_repository.dart';
import 'package:mobile_app/widgets/text_field.dart';
import 'package:mobile_app/providers/class_update_notifier.dart';
import 'package:mobile_app/utils/schedule_utils.dart';
import 'package:mobile_app/glass_modal.dart';
import 'package:mobile_app/utils/responsive.dart';
import 'package:mobile_app/services/alert_service.dart';

class SchedulePage extends ConsumerStatefulWidget {
  final int userId;
  const SchedulePage({super.key, required this.userId});

  @override
  ConsumerState<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends ConsumerState<SchedulePage> {
  final ClassRepository _repository = ClassRepository();
  List<ClassModel> allSchedules = [], filteredSchedules = [];
  List<List<ClassModel>> conflicts = [];
  String selectedDayFilter = 'M';
  final List<String> weekDays = ['M', 'T', 'W', 'Th', 'F', 'S', 'Sun'];

  @override
  void initState() {
    super.initState();
    _refreshSchedules();
  }

  void _refreshSchedules() async {
    final data = await _repository.getAllClasses(widget.userId);
    final conflictData = findConflicts(data);
    setState(() {
      allSchedules = data;
      conflicts = conflictData;
      _applyFilter(selectedDayFilter);
    });
  }

  void _applyFilter(String day) {
    setState(() {
      selectedDayFilter = day;
      filteredSchedules =
          allSchedules.where((s) => _matchesDay(s.days, day)).toList();
      filteredSchedules.sort(
        (a, b) => ClassModel.timeToMinutes(a.startTime)
            .compareTo(ClassModel.timeToMinutes(b.startTime)),
      );
    });
  }

  bool _matchesDay(String scheduleDays, String filterDay) {
    final sd = scheduleDays.toUpperCase();
    final fd = filterDay.toUpperCase();
    if (fd == 'WED')
      return sd.contains('WED') ||
          (sd.contains('W') && !sd.contains('TUE') && !sd.contains('FRI'));
    if (fd == 'MON') return sd.contains('MON') || sd.contains('M');
    if (fd == 'TUE') return sd.contains('TUE') || sd.contains('T');
    if (fd == 'THU')
      return sd.contains('THU') || (sd.contains('TH') && !sd.contains('MON'));
    if (fd == 'FRI') return sd.contains('FRI');
    if (fd == 'SAT') return sd.contains('SAT') || sd.contains('S');
    if (fd == 'SUN') return sd.contains('SUN');
    return sd.contains(fd);
  }

  void _showGlassAlert(String msg, Color themeColor) {
    AlertService().showGlassAlert(context, msg, color: themeColor);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "CLASS SCHEDULE",
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w900,
            fontSize: res(context, 16),
            letterSpacing: 1.5,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        leading: IconButton(
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.grid_view_rounded, color: accentColor, size: 22),
          onPressed: () {},
        ),
      ),
      body: Column(
        children: [
          if (conflicts.isNotEmpty) _buildConflictBanner(theme),
          _buildDayPicker(),
          const SizedBox(height: 8),
          if (filteredSchedules.isEmpty)
            Expanded(
              child: _buildEmptyState(theme),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredSchedules.length,
                itemBuilder: (context, index) {
                  final item = filteredSchedules[index];
                  return _buildTimelineTile(item, index);
                },
              ),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormDialog(),
        backgroundColor: theme.colorScheme.primary,
        elevation: 4,
        icon: Icon(Icons.add_task_rounded,
            color: Colors.white, size: res(context, 20)),
        label: Text(
          "ADD CLASS",
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: res(context, 14)),
        ),
      ),
    );
  }

  Widget _buildConflictBanner(ThemeData theme) {
    return MaterialBanner(
      backgroundColor: theme.colorScheme.error.withValues(alpha: 0.1),
      content: Text(
        "${conflicts.length} schedule conflict(s) detected",
        style: TextStyle(
          color: theme.colorScheme.error,
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: Icon(Icons.warning_rounded, color: theme.colorScheme.error),
      actions: [
        TextButton(
          onPressed: () => _showConflictModal(),
          child: Text(
            "REVIEW",
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ),
      ],
    );
  }

  void _showConflictModal() {
    final theme = Theme.of(context);
    GlassModal.show(
      context,
      title: "Schedule Conflicts",
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: conflicts.map((pair) {
          final a = pair[0];
          final b = pair[1];
          return Padding(
            padding: EdgeInsets.symmetric(vertical: res(context, 8)),
            child: Container(
              padding: EdgeInsets.all(res(context, 10)),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(res(context, 8)),
              ),
              child: Text(
                "${a.subject} ↔ ${b.subject} (${a.days}, ${a.displayStartTime}-${a.displayEndTime})",
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: res(context, 12),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDayPicker() {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;

    return Container(
      height: res(context, 100),
      padding: EdgeInsets.symmetric(vertical: res(context, 15)),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: weekDays.length,
        padding: EdgeInsets.symmetric(horizontal: res(context, 20)),
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final day = weekDays[index];
          final isActive = selectedDayFilter == day;

          final fullDayNames = {
            'M': 'Mon',
            'T': 'Tue',
            'W': 'Wed',
            'Th': 'Thu',
            'F': 'Fri',
            'S': 'Sat',
            'Sun': 'Sun'
          };

          return GestureDetector(
            onTap: () => _applyFilter(day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutQuart,
              margin: EdgeInsets.only(right: res(context, 14)),
              width: res(context, 65),
              decoration: BoxDecoration(
                color: isActive
                    ? accentColor
                    : theme.colorScheme.onSurface.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(res(context, 22)),
                gradient: isActive
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accentColor,
                          accentColor.withValues(alpha: 0.8)
                        ],
                      )
                    : null,
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [],
                border: Border.all(
                  color: isActive
                      ? accentColor.withValues(alpha: 0.5)
                      : theme.dividerColor.withValues(alpha: 0.05),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    day,
                    style: TextStyle(
                      color: isActive
                          ? Colors.white
                          : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w900,
                      fontSize: res(context, 19),
                    ),
                  ),
                  SizedBox(height: res(context, 2)),
                  Text(
                    fullDayNames[day] ?? "",
                    style: TextStyle(
                      color: isActive
                          ? Colors.white.withValues(alpha: 0.8)
                          : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      fontWeight: FontWeight.bold,
                      fontSize: res(context, 10),
                      letterSpacing: 0.5,
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: EdgeInsets.only(top: res(context, 8)),
                    width: isActive ? res(context, 5) : 0,
                    height: isActive ? res(context, 5) : 0,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimelineTile(ClassModel item, int index) {
    final theme = Theme.of(context);
    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: res(context, 15),
                height: res(context, 15),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: theme.scaffoldBackgroundColor,
                      width: res(context, 3)),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 5,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  width: res(context, 2),
                  color: index == filteredSchedules.length - 1
                      ? Colors.transparent
                      : theme.colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
            ],
          ),
          SizedBox(width: res(context, 20)),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: res(context, 20)),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(res(context, 20)),
                border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.05)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(res(context, 20)),
                child: InkWell(
                  onTap: () => _showDetailsModal(item),
                  child: Padding(
                    padding: EdgeInsets.all(res(context, 16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${item.displayStartTime} - ${item.displayEndTime}",
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: res(context, 12),
                              ),
                            ),
                            Icon(
                              Icons.more_vert_rounded,
                              size: res(context, 18),
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.3),
                            ),
                          ],
                        ),
                        SizedBox(height: res(context, 8)),
                        Text(
                          item.subject,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: res(context, 18),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: res(context, 4)),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: res(context, 14),
                                color: theme.colorScheme.secondary),
                            SizedBox(width: res(context, 4)),
                            Text(
                              item.room,
                              style: TextStyle(
                                color: theme.colorScheme.secondary,
                                fontSize: res(context, 13),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(res(context, 20)),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.02),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.calendar_today_outlined,
              size: res(context, 60),
              color: theme.hintColor.withValues(alpha: 0.2),
            ),
          ),
          SizedBox(height: res(context, 16)),
          Text(
            "No classes scheduled",
            style: TextStyle(
              color: theme.hintColor,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              fontSize: res(context, 14),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tap + to add your first class",
            style: TextStyle(
              color: theme.hintColor.withValues(alpha: 0.5),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailsModal(ClassModel item) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) {
        return RepaintBoundary(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Container(
                padding: EdgeInsets.all(res(context, 25)),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.97),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: res(context, 40),
                        height: res(context, 4),
                        decoration: BoxDecoration(
                          color: theme.dividerColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      SizedBox(height: res(context, 25)),
                      Text(item.subject,
                          style: TextStyle(
                              fontSize: res(context, 22),
                              fontWeight: FontWeight.bold)),
                      SizedBox(height: res(context, 20)),
                      _detailItem(Icons.access_time, "Time",
                          "${item.displayStartTime} - ${item.displayEndTime}"),
                      _detailItem(Icons.room_rounded, "Room", item.room),
                      _detailItem(
                          Icons.person_outline, "Professor", item.professor),
                      _detailItem(
                          Icons.calendar_today_outlined, "Days", item.days),
                      SizedBox(height: res(context, 30)),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                    vertical: res(context, 15)),
                                side: const BorderSide(color: Colors.redAccent),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        res(context, 12))),
                              ),
                              onPressed: () {
                                _confirmDelete(item.id!);
                              },
                              child: Text("DELETE",
                                  style: TextStyle(
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: res(context, 14))),
                            ),
                          ),
                          SizedBox(width: res(context, 15)),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                padding: EdgeInsets.symmetric(
                                    vertical: res(context, 15)),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        res(context, 12))),
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                _showFormDialog(existingSchedule: item);
                              },
                              child: Text("EDIT CLASS",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: res(context, 14),
                                      color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: res(context, 20)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailItem(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: res(context, 10)),
      child: Row(
        children: [
          Icon(icon,
              size: res(context, 20),
              color: Theme.of(context).colorScheme.primary),
          SizedBox(width: res(context, 15)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: res(context, 11), color: Colors.grey.shade500)),
              Text(value,
                  style: TextStyle(
                      fontSize: res(context, 15), fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(int id) {
    AlertService().showConfirmDialog(
      context,
      title: 'Remove Class?',
      body: 'This will permanently remove this subject from your schedule.',
      confirmLabel: 'DELETE',
      onConfirm: () async {
        await _repository.deleteClass(id);
        ClassUpdateProvider.instance.notifyClassUpdate();
        _refreshSchedules();
        if (context.mounted) Navigator.pop(context);
        _showGlassAlert("Class removed", Colors.redAccent);
      },
    );
  }

  void _showFormDialog({ClassModel? existingSchedule}) {
    final theme = Theme.of(context);
    final isEdit = existingSchedule != null;
    final subjectCtrl = TextEditingController(text: existingSchedule?.subject);
    final roomCtrl = TextEditingController(text: existingSchedule?.room);
    final profCtrl = TextEditingController(text: existingSchedule?.professor);

    TimeOfDay? startT;
    TimeOfDay? endT;
    List<String> selectedDays =
        isEdit ? existingSchedule.days.split(", ") : [selectedDayFilter];

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) {
        return RepaintBoundary(
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Container(
                    padding: EdgeInsets.all(res(context, 25)),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.97),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(isEdit ? "Update Class" : "New Class",
                              style: TextStyle(
                                  fontSize: res(context, 20),
                                  fontWeight: FontWeight.bold)),
                          SizedBox(height: res(context, 20)),
                          CustomTextField(
                            controller: subjectCtrl,
                            hintText: "Subject Name",
                            prefixIcon: Icons.book_rounded,
                          ),
                          SizedBox(height: res(context, 15)),
                          Row(
                            children: [
                              Expanded(
                                child: CustomTextField(
                                  controller: roomCtrl,
                                  hintText: "Room",
                                  prefixIcon: Icons.room_rounded,
                                ),
                              ),
                              SizedBox(width: res(context, 15)),
                              Expanded(
                                child: CustomTextField(
                                  controller: profCtrl,
                                  hintText: "Professor",
                                  prefixIcon: Icons.person_rounded,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: res(context, 25)),
                          Align(
                              alignment: Alignment.centerLeft,
                              child: Text("Days",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: res(context, 14)))),
                          SizedBox(height: res(context, 10)),
                          Wrap(
                            spacing: res(context, 8),
                            children: weekDays.map((d) {
                              bool isSel = selectedDays.contains(d);
                              return FilterChip(
                                selected: isSel,
                                label: Text(d,
                                    style: TextStyle(
                                        color: isSel
                                            ? Colors.white
                                            : theme.colorScheme.onSurface,
                                        fontSize: res(context, 12))),
                                selectedColor: theme.colorScheme.primary,
                                onSelected: (val) => setDialogState(() => val
                                    ? selectedDays.add(d)
                                    : selectedDays.remove(d)),
                              );
                            }).toList(),
                          ),
                          SizedBox(height: res(context, 20)),
                          Row(
                            children: [
                              Expanded(
                                child: _timeTile(
                                    "Starts",
                                    startT != null
                                        ? _formatTimeOfDay(startT!)
                                        : (existingSchedule?.displayStartTime ??
                                            "Select"), () async {
                                  final t = await showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay.now());
                                  if (t != null)
                                    setDialogState(() => startT = t);
                                }),
                              ),
                              SizedBox(width: res(context, 15)),
                              Expanded(
                                child: _timeTile(
                                    "Ends",
                                    endT != null
                                        ? _formatTimeOfDay(endT!)
                                        : (existingSchedule?.displayEndTime ??
                                            "Select"), () async {
                                  final t = await showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay.now());
                                  if (t != null) setDialogState(() => endT = t);
                                }),
                              ),
                            ],
                          ),
                          SizedBox(height: res(context, 30)),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              minimumSize:
                                  Size(double.infinity, res(context, 50)),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(res(context, 15))),
                            ),
                            onPressed: () async {
                              if (subjectCtrl.text.isNotEmpty) {
                                String startTimeStr = startT != null
                                    ? _formatTimeOfDay(startT!)
                                    : (existingSchedule?.startTime ??
                                        "9:00 AM");
                                String endTimeStr = endT != null
                                    ? _formatTimeOfDay(endT!)
                                    : (existingSchedule?.endTime ?? "10:00 AM");
                                final classModel = ClassModel(
                                  id: existingSchedule?.id,
                                  subject: subjectCtrl.text,
                                  days: selectedDays.join(", "),
                                  startTime: startTimeStr,
                                  endTime: endTimeStr,
                                  room: roomCtrl.text.isEmpty
                                      ? "TBA"
                                      : roomCtrl.text,
                                  professor: profCtrl.text.isEmpty
                                      ? "TBA"
                                      : profCtrl.text,
                                );
                                if (isEdit) {
                                  await _repository.updateClass(classModel);
                                  ClassUpdateProvider.instance
                                      .notifyClassUpdate();
                                } else {
                                  await _repository.createClass(
                                      widget.userId, classModel);
                                  ClassUpdateProvider.instance
                                      .notifyClassUpdate();
                                }
                                _refreshSchedules();
                                if (context.mounted) Navigator.pop(context);
                                _showGlassAlert(
                                    isEdit ? "Schedule updated" : "Class added",
                                    theme.colorScheme.primary);
                              }
                            },
                            child: Text("SAVE SCHEDULE",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: res(context, 14))),
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
      },
    );
  }

  String _formatTimeOfDay(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Widget _timeTile(String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(res(context, 12)),
        decoration: BoxDecoration(
          color:
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(res(context, 12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    TextStyle(fontSize: res(context, 10), color: Colors.grey)),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: res(context, 14))),
          ],
        ),
      ),
    );
  }
}
