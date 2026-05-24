import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:mobile_app/models/study_resource_model.dart';
import 'package:mobile_app/services/study_resource_service.dart';
import 'package:mobile_app/providers/theme_provider.dart';
import 'package:mobile_app/services/alert_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/utils/responsive.dart';

class SummariesScreen extends ConsumerStatefulWidget {
  final int userId;
  const SummariesScreen({super.key, required this.userId});

  @override
  ConsumerState<SummariesScreen> createState() => _SummariesScreenState();
}

class _SummariesScreenState extends ConsumerState<SummariesScreen> {
  final _resourceService = StudyResourceService();
  List<StudyResource> _summaries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSummaries();
  }

  Future<void> _loadSummaries() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final data = await _resourceService.getResources(widget.userId, 'summary');
    if (mounted) {
      setState(() {
        _summaries = data;
        _isLoading = false;
      });
    }
  }

  void _showGlassAlert(String message, {Color? color}) {
    AlertService().showGlassAlert(context, message, color: color);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = ref.read(themeProvider).accentColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.grid_view_rounded,
              size: res(context, 22), color: accentColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text("SUMMARIES",
            style: TextStyle(
                color: theme.colorScheme.onSurface,
                letterSpacing: 4,
                fontWeight: FontWeight.w900,
                fontSize: res(context, 16))),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: accentColor))
          : _summaries.isEmpty
              ? _buildEmptyState(theme)
              : _buildSummaryList(accentColor, theme),
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
            child: Icon(Icons.summarize_outlined,
                size: res(context, 60),
                color: theme.hintColor.withValues(alpha: 0.2)),
          ),
          SizedBox(height: res(context, 16)),
          Text("No summaries found",
              style: TextStyle(
                  color: theme.hintColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  fontSize: res(context, 14))),
          const SizedBox(height: 8),
          Text("Generate one using your notes",
              style: TextStyle(
                  color: theme.hintColor.withValues(alpha: 0.5), fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildSummaryList(Color accentColor, ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _loadSummaries,
      color: accentColor,
      backgroundColor: theme.cardColor,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        padding:
            EdgeInsets.symmetric(horizontal: res(context, 20), vertical: 10),
        itemCount: _summaries.length,
        itemBuilder: (context, index) {
          final summary = _summaries[index];
          return Padding(
            padding: EdgeInsets.only(bottom: res(context, 12)),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(res(context, 24)),
                border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.05)),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.all(res(context, 12)),
                onTap: () => _viewSummaryDetails(summary, accentColor, theme),
                onLongPress: () =>
                    _showDeleteOptions(summary, accentColor, theme),
                leading: Container(
                  padding: EdgeInsets.all(res(context, 10)),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(res(context, 15)),
                  ),
                  child: Icon(Icons.short_text_rounded, color: accentColor),
                ),
                title: Text(
                  summary.fileName,
                  style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  summary.content ?? "No content",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: theme.hintColor, fontSize: 11),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.more_vert_rounded,
                      color: theme.hintColor, size: 20),
                  onPressed: () =>
                      _showDeleteOptions(summary, accentColor, theme),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteOptions(
      StudyResource summary, Color accent, ThemeData theme) {
    showCenteredModal(
      context: context,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.only(bottom: res(context, 20)),
                  decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(10)),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.edit_note_rounded,
                        color: accent),
                  ),
                  title: Text("Rename Summary",
                      style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold)),
                  subtitle: Text("Change the title of this summary",
                      style: TextStyle(color: theme.hintColor, fontSize: 11)),
                  onTap: () {
                    Navigator.pop(context);
                    _showRenameDialog(summary, accent, theme);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: Colors.redAccent),
                  ),
                  title: Text("Delete Summary",
                      style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold)),
                  subtitle: Text("This cannot be undone",
                      style: TextStyle(color: theme.hintColor, fontSize: 11)),
                  onTap: () {
                    Navigator.pop(context);
                    AlertService().showConfirmDialog(
                      context,
                      title: 'Delete Summary?',
                      body: 'This action cannot be undone.',
                      confirmLabel: 'DELETE',
                      confirmColor: Colors.redAccent,
                      onConfirm: () async {
                        await _resourceService.deleteResource(summary.id!);
                        if (!mounted) return;
                        _loadSummaries();
                        _showGlassAlert('Summary Deleted',
                            color: Colors.redAccent);
                      },
                    );
                  },
                ),
                SizedBox(height: res(context, 20)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRenameDialog(
      StudyResource summary, Color accent, ThemeData theme) {
    final controller = TextEditingController(text: summary.fileName);
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(res(context, 20))),
          title: Text("RENAME SUMMARY",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                  fontSize: res(context, 16),
                  letterSpacing: 1.2)),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: theme.colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: "Enter name...",
              hintStyle:
                  TextStyle(color: theme.hintColor),
              enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: accent.withValues(alpha: 0.5))),
              focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: accent, width: 2)),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("CANCEL",
                    style: TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.bold))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(res(context, 12)))),
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  summary.fileName = controller.text;
                  await _resourceService.updateResource(summary);
                  if (context.mounted) Navigator.pop(context);
                  if (!mounted) return;
                  _loadSummaries();
                  _showGlassAlert("Renamed Successfully");
                }
              },
              child: const Text("SAVE",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }

  void _viewSummaryDetails(
      StudyResource summary, Color accentColor, ThemeData theme) {
    showCenteredModal(
      context: context,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(28),
            border:
                Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
          ),
          padding: EdgeInsets.all(res(context, 25)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              SizedBox(height: res(context, 25)),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.article_rounded,
                        color: accentColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      summary.fileName.toUpperCase(),
                      style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          fontSize: res(context, 16)),
                    ),
                  ),
                ],
              ),
              SizedBox(height: res(context, 20)),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(res(context, 20)),
                  decoration: BoxDecoration(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                          color: theme.dividerColor.withValues(alpha: 0.05))),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Text(
                      summary.content ?? "No content generated.",
                      style: TextStyle(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.8),
                          fontSize: res(context, 15),
                          height: 1.8,
                          fontFamily: 'Poppins'),
                    ),
                  ),
                ),
              ),
              SizedBox(height: res(context, 20)),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: theme.scaffoldBackgroundColor,
                    minimumSize: Size(double.infinity, res(context, 55)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                    elevation: 0),
                child: const Text("CLOSE READER",
                    style: TextStyle(
                        fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              )
            ],
          ),
        ),
      ),
    );
  }
}