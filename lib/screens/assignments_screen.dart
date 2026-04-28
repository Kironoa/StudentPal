import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:mobile_app/models/assignment_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/services/assignment_service.dart';
import 'package:mobile_app/widgets/text_field.dart';
import 'package:mobile_app/utils/responsive.dart';
import 'package:mobile_app/services/alert_service.dart';

class AssignmentsScreen extends ConsumerStatefulWidget {
  final int userId;
  const AssignmentsScreen({super.key, required this.userId});

  @override
  ConsumerState<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends ConsumerState<AssignmentsScreen> {
  final AssignmentService _assignmentService = AssignmentService();
  late Future<List<Assignment>> _assignmentsFuture;

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

  @override
  void initState() {
    super.initState();
    _refreshAssignments();
  }

  void _refreshAssignments() {
    setState(() {
      _assignmentsFuture = _assignmentService.getAssignments(widget.userId);
    });
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
          "ASSIGNMENTS",
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w900,
            fontSize: res(context, 16),
            letterSpacing: 1.5,
          ),
        ),
        leading: IconButton(
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.grid_view_rounded, color: accentColor, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<Assignment>>(
        future: _assignmentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: accentColor));
          }
          final data = snapshot.data ?? [];
          if (data.isEmpty) return _buildEmptyState(theme);

          return ListView.builder(
            padding: EdgeInsets.fromLTRB(res(context, 20), res(context, 10),
                res(context, 20), res(context, 100)),
            itemCount: data.length,
            itemBuilder: (context, index) =>
                _buildAssignmentTile(data[index], index, data.length),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        backgroundColor: accentColor,
        elevation: 4,
        icon: Icon(Icons.add_task_rounded,
            color: Colors.white, size: res(context, 20)),
        label: Text(
          "ADD TASK",
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: res(context, 14)),
        ),
      ),
    );
  }

  Widget _buildAssignmentTile(Assignment item, int index, int totalItems) {
    final theme = Theme.of(context);
    const priority = "Normal";
    final priorityColor = priority == "High"
        ? theme.colorScheme.error
        : theme.colorScheme.primary;

    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: res(context, 15),
                height: res(context, 15),
                decoration: BoxDecoration(
                  color: priorityColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: theme.scaffoldBackgroundColor,
                      width: res(context, 3)),
                  boxShadow: [
                    BoxShadow(
                        color: priorityColor.withValues(alpha: 0.3),
                        blurRadius: 5)
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  width: res(context, 2),
                  color: index == totalItems - 1
                      ? Colors.transparent
                      : theme.colorScheme.onSurface.withValues(alpha: 0.1),
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
                  onTap: () => _viewDetailsSheet(item),
                  child: Padding(
                    padding: EdgeInsets.all(res(context, 16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("DUE: ${formatDeadline(item.deadline)}",
                                style: TextStyle(
                                    color: _getDeadlineColor(
                                        item.deadline, priorityColor),
                                    fontWeight: FontWeight.bold,
                                    fontSize: res(context, 11))),
                            Icon(Icons.more_vert_rounded,
                                size: res(context, 18),
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.3)),
                          ],
                        ),
                        SizedBox(height: res(context, 8)),
                        Text(item.title,
                            style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: res(context, 17),
                                fontWeight: FontWeight.bold)),
                        SizedBox(height: res(context, 4)),
                        Row(
                          children: [
                            Icon(Icons.bookmark_outline_rounded,
                                size: res(context, 14),
                                color: theme.colorScheme.secondary),
                            SizedBox(width: res(context, 4)),
                            Text(item.subject ?? "General",
                                style: TextStyle(
                                    color: theme.colorScheme.secondary,
                                    fontSize: res(context, 13),
                                    fontWeight: FontWeight.w500)),
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

  void _showForm({Assignment? assignment}) {
    final isEdit = assignment != null;
    final theme = Theme.of(context);
    final subjectCtrl =
        TextEditingController(text: isEdit ? assignment.subject : "");
    final titleCtrl =
        TextEditingController(text: isEdit ? assignment.title : "");
    final descCtrl =
        TextEditingController(text: isEdit ? assignment.description : "");
    DateTime? tempDeadline = assignment?.deadlineDate;

    showCenteredModal(
      context: context,
      child: StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.all(res(context, 25)),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(28),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(isEdit ? "Update Assignment" : "New Assignment",
                    style: TextStyle(
                        fontSize: res(context, 20),
                        fontWeight: FontWeight.bold)),
                SizedBox(height: res(context, 20)),
                CustomTextField(
                    controller: subjectCtrl,
                    hintText: "Course/Subject",
                    prefixIcon: Icons.book_rounded),
                SizedBox(height: res(context, 10)),
                CustomTextField(
                    controller: titleCtrl,
                    hintText: "Assignment Title",
                    prefixIcon: Icons.edit_note_rounded),
                SizedBox(height: res(context, 10)),
                CustomTextField(
                    controller: descCtrl,
                    hintText: "Instructions or Notes",
                    prefixIcon: Icons.notes_rounded,
                    maxLines: 3),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.calendar_today_rounded,
                      color: theme.colorScheme.primary),
                  title: Text(tempDeadline == null
                      ? "Set Due Date"
                      : DateFormat('MMM dd, yyyy • hh:mm a')
                          .format(tempDeadline!)),
                  trailing:
                      Icon(Icons.chevron_right_rounded, color: theme.hintColor),
                  onTap: () async {
                    if (!context.mounted) return;
                    final date = await showDatePicker(
                        context: context,
                        initialDate: tempDeadline ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030));
                    if (date != null) {
                      if (!context.mounted) return;
                      final time = await showTimePicker(
                          context: context,
                          initialTime: tempDeadline != null
                              ? TimeOfDay.fromDateTime(tempDeadline!)
                              : TimeOfDay.now());
                      if (time != null) {
                        setModalState(() => tempDeadline = DateTime(date.year,
                            date.month, date.day, time.hour, time.minute));
                      }
                    }
                  },
                ),
                SizedBox(height: res(context, 20)),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, res(context, 55)),
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18))),
                  onPressed: () async {
                    if (titleCtrl.text.isNotEmpty) {
                      final assignmentData = Assignment(
                        id: assignment?.id,
                        userId: widget.userId,
                        subject: subjectCtrl.text,
                        title: titleCtrl.text,
                        description: descCtrl.text,
                        deadline: tempDeadline?.toIso8601String(),
                      );
                      await _assignmentService.saveAssignment(
                        widget.userId,
                        assignmentData,
                      );
                      if (!context.mounted) return;
                      _showGlassAlert(
                        isEdit ? "Task Updated" : "Task Saved",
                        theme.colorScheme.primary,
                      );
                      _refreshAssignments();
                      if (mounted) Navigator.pop(context);
                    }
                  },
                  child: const Text("CONFIRM CHANGES",
                      style: TextStyle(
                          fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _viewDetailsSheet(Assignment item) {
    final theme = Theme.of(context);

    showCenteredModal(
      context: context,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          padding: EdgeInsets.fromLTRB(
            res(context, 15),
            res(context, 15),
            res(context, 25),
            res(context, 25),
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: res(context, 40),
                height: res(context, 4),
                decoration: BoxDecoration(
                  color: theme.hintColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              SizedBox(height: res(context, 25)),
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      Text(
                        item.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: res(context, 22),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: res(context, 20)),
                      _detailItem(Icons.book_rounded, "Subject",
                          item.subject ?? "General"),
                      _detailItem(Icons.event_note_rounded, "Deadline",
                          formatDeadline(item.deadline),
                          valueColor: _getDeadlineColor(
                              item.deadline, theme.colorScheme.primary)),
                      _detailItem(
                          Icons.notes_rounded,
                          "Description",
                          (item.description == null ||
                                  item.description!.isEmpty)
                              ? "No additional notes."
                              : item.description!),
                      SizedBox(height: res(context, 20)),
                    ],
                  ),
                ),
              ),
              SizedBox(height: res(context, 20)),
              SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.only(bottom: res(context, 8)),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                vertical: res(context, 15)),
                            side: const BorderSide(color: Colors.redAccent),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(res(context, 12)),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            if (item.id != null) {
                              _confirmDelete(item.id!);
                            }
                          },
                          child: Text(
                            "DELETE",
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: res(context, 14),
                            ),
                          ),
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
                              borderRadius:
                                  BorderRadius.circular(res(context, 12)),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            _showForm(assignment: item);
                          },
                          child: Text(
                            "EDIT TASK",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: res(context, 14),
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailItem(IconData icon, String label, String value,
      {Color? valueColor}) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: res(context, 8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size: res(context, 20),
              color: valueColor ?? theme.colorScheme.primary),
          SizedBox(width: res(context, 15)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: res(context, 12),
                    color: theme.hintColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: res(context, 15),
                    fontWeight: FontWeight.w500,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(int id) {
    AlertService().showConfirmDialog(
      context,
      title: 'Delete Task?',
      body: 'This action cannot be undone.',
      confirmLabel: 'DELETE',
      onConfirm: () async {
        await _assignmentService.deleteAssignment(id);
        _refreshAssignments();
        if (!context.mounted) return;
        _showGlassAlert('Task removed', Colors.redAccent);
      },
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
              Icons.assignment_outlined,
              size: res(context, 60),
              color: theme.hintColor.withValues(alpha: 0.2),
            ),
          ),
          SizedBox(height: res(context, 16)),
          Text(
            "No pending assignments",
            style: TextStyle(
              color: theme.hintColor,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              fontSize: res(context, 14),
            ),
          ),
          SizedBox(height: res(context, 8)),
          Text(
            "Tap + to add a task",
            style: TextStyle(
              color: theme.hintColor.withValues(alpha: 0.5),
              fontSize: res(context, 11),
            ),
          ),
        ],
      ),
    );
  }
}
