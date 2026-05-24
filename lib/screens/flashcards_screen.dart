import 'package:flutter/material.dart';
import 'package:flip_card/flip_card.dart';
import 'package:mobile_app/models/study_resource_model.dart';
import 'package:mobile_app/services/study_resource_service.dart';
import 'package:mobile_app/providers/theme_provider.dart';
import 'package:mobile_app/services/alert_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'package:mobile_app/utils/responsive.dart';

class Flashcard {
  final String question;
  final String answer;
  Flashcard({required this.question, required this.answer});
}

class FlashcardsScreen extends ConsumerStatefulWidget {
  final int userId;
  const FlashcardsScreen({super.key, required this.userId});

  @override
  ConsumerState<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends ConsumerState<FlashcardsScreen> {
  final _resourceService = StudyResourceService();
  List<StudyResource> _groups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final data =
        await _resourceService.getResources(widget.userId, 'flashcard');
    if (mounted) {
      setState(() {
        _groups = data;
        _isLoading = false;
      });
    }
  }

  void _showGlassAlert(String message, {Color? color}) {
    AlertService().showGlassAlert(context, message, color: color);
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
              Icons.style_outlined,
              size: res(context, 60),
              color: theme.hintColor.withValues(alpha: 0.2),
            ),
          ),
          SizedBox(height: res(context, 16)),
          Text(
            "No flashcard sets found",
            style: TextStyle(
              color: theme.hintColor,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              fontSize: res(context, 14),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Generate one using your notes",
            style: TextStyle(
              color: theme.hintColor.withValues(alpha: 0.5),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(StudyResource group) {
    AlertService().showConfirmDialog(
      context,
      title: 'Delete Set?',
      body: 'This action cannot be undone.',
      confirmLabel: 'DELETE',
      onConfirm: () async {
        await _resourceService.deleteResource(group.id!);
        if (!mounted) return;
        _loadGroups();
        _showGlassAlert("Set Deleted", color: Colors.redAccent);
      },
    );
  }

  void _showGroupOptions(StudyResource group, Color accent) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          constraints: BoxConstraints(
            minWidth: 280,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
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
                      margin: EdgeInsets.only(bottom: res(context, 15)),
                      decoration: BoxDecoration(
                        color: theme.dividerColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Text(
                      "GROUP OPTIONS",
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w900,
                        fontSize: res(context, 14),
                        letterSpacing: 2,
                      ),
                    ),
                    SizedBox(height: res(context, 20)),
                    _buildOptionTile(Icons.edit_note_rounded, "Rename Set",
                        "Change the title of this set", () {
                      Navigator.pop(context);
                      _showRenameDialog(group, accent);
                    }, accent),
                    _buildOptionTile(Icons.delete_outline_rounded, "Delete Set",
                        "Remove these flashcards forever", () {
                      Navigator.pop(context);
                      _confirmDelete(group);
                    }, Colors.redAccent),
                    SizedBox(height: res(context, 20)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile(IconData icon, String title, String subtitle,
      VoidCallback onTap, Color color) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: EdgeInsets.all(res(context, 8)),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color),
      ),
      title: Text(title,
          style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle,
          style: TextStyle(
              color: theme.hintColor, fontSize: 11)),
    );
  }

  void _showRenameDialog(StudyResource group, Color accent) {
    final theme = Theme.of(context);
    final controller = TextEditingController(text: group.fileName);
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(res(context, 20))),
          title: Text("RENAME SET",
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
                  group.fileName = controller.text;
                  await _resourceService.updateResource(group);
                  if (context.mounted) Navigator.pop(context);
                  if (!mounted) return;
                  _loadGroups();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeState = ref.read(themeProvider);
    final accentColor = themeState.accentColor;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("FLASHCARDS",
            style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                fontSize: res(context, 16))),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.grid_view_rounded,
              size: res(context, 22), color: accentColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: accentColor))
          : _groups.isEmpty
              ? _buildEmptyState(theme)
              : ListView.builder(
                  padding: EdgeInsets.all(res(context, 20)),
                  itemCount: _groups.length,
                  itemBuilder: (context, index) {
                    final group = _groups[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: res(context, 15)),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(res(context, 24)),
                        border: Border.all(
                            color: theme.dividerColor.withValues(alpha: 0.1)),
                        boxShadow: [
                          if (!isDark)
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4))
                        ],
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: res(context, 20),
                            vertical: res(context, 10)),
                        leading: Container(
                          padding: EdgeInsets.all(res(context, 10)),
                          decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(15)),
                          child: Icon(Icons.style_rounded, color: accentColor),
                        ),
                        title: Text(group.fileName,
                            style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.bold)),
                        subtitle: Text("Reviewing Cards",
                            style: TextStyle(
                                color: theme.hintColor,
                                fontSize: 11)),
                        trailing: IconButton(
                          icon: Icon(Icons.more_horiz,
                              color: theme.hintColor),
                          onPressed: () =>
                              _showGroupOptions(group, accentColor),
                        ),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    FlashcardPlayScreen(resource: group))),
                      ),
                    );
                  },
                ),
    );
  }
}

class FlashcardPlayScreen extends ConsumerStatefulWidget {
  final StudyResource resource;
  const FlashcardPlayScreen({super.key, required this.resource});

  @override
  ConsumerState<FlashcardPlayScreen> createState() => _FlashcardPlayScreenState();
}

class _FlashcardPlayScreenState extends ConsumerState<FlashcardPlayScreen> {
  List<Flashcard> _cards = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _parseContent(widget.resource.content ?? "");
  }

  void _parseContent(String content) {
    List<Flashcard> tempCards = [];
    final RegExp regExp = RegExp(
      r'(?:Q|Question):\s*(.*?)\s*(?:A|Answer):\s*(.*?)(?=(?:Q|Question):|$)',
      dotAll: true,
      caseSensitive: false,
    );
    final matches = regExp.allMatches(content);
    for (var match in matches) {
      String q = match.group(1)?.trim() ?? "";
      String a = match.group(2)?.trim() ?? "";
      if (q.isNotEmpty && a.isNotEmpty) {
        tempCards.add(Flashcard(question: q, answer: a));
      }
    }
    setState(() {
      _cards = tempCards;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.read(themeProvider);
    final theme = Theme.of(context);
    final accentColor = themeState.accentColor;
    final isDark = theme.brightness == Brightness.dark;

    if (_cards.isEmpty) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: Center(
          child: Text(
            "No flashcards found in this set.",
            style: TextStyle(
                color: theme.hintColor,
                fontSize: res(context, 14)),
          ),
        ),
      );
    }
    final progress = (_currentIndex + 1) / _cards.length;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.resource.fileName.toUpperCase(),
            style: TextStyle(
                color: accentColor,
                fontSize: res(context, 12),
                fontWeight: FontWeight.w900,
                letterSpacing: 2)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: res(context, 30), vertical: res(context, 20)),
            child: LinearProgressIndicator(
                value: progress,
                backgroundColor: theme.dividerColor.withValues(alpha: 0.3),
                color: accentColor,
                minHeight: res(context, 6),
                borderRadius: BorderRadius.circular(10)),
          ),
          const Spacer(),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            width: MediaQuery.of(context).size.width * 0.85,
            child: FlipCard(
              key: ValueKey(_currentIndex),
              front: _buildFace(_cards[_currentIndex].question, "QUESTION",
                  true, accentColor, isDark),
              back: _buildFace(_cards[_currentIndex].answer, "ANSWER", false,
                  accentColor, isDark),
            ),
          ),
          const Spacer(),
          Padding(
            padding: EdgeInsets.only(bottom: res(context, 60)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _navBtn(
                    Icons.arrow_back_ios_new_rounded,
                    () => setState(() => _currentIndex--),
                    _currentIndex > 0,
                    isDark),
                SizedBox(width: res(context, 50)),
                _navBtn(
                    Icons.arrow_forward_ios_rounded,
                    () => setState(() => _currentIndex++),
                    _currentIndex < _cards.length - 1,
                    isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFace(
      String text, String label, bool isFront, Color accent, bool isDark) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(res(context, 30)),
      decoration: BoxDecoration(
        color: isDark
            ? (isFront ? theme.colorScheme.surface : theme.colorScheme.surface.withValues(alpha: 0.9))
            : Colors.white,
        borderRadius: BorderRadius.circular(res(context, 30)),
        border: Border.all(
            color: isDark
                ? (isFront ? theme.colorScheme.onSurface.withValues(alpha: 0.1) : accent.withValues(alpha: 0.3))
                : (isFront ? Colors.black12 : accent.withValues(alpha: 0.4)),
            width: 2),
        boxShadow: [
          if (!isDark)
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05), blurRadius: 20),
          if (!isFront)
            BoxShadow(color: accent.withValues(alpha: 0.1), blurRadius: 40)
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: TextStyle(
                  color: isFront
                      ? theme.hintColor
                      : accent,
                  fontSize: res(context, 11),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2)),
          const Spacer(),
          SingleChildScrollView(
            child: Text(text,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: isDark ? theme.colorScheme.onSurface : Colors.black87,
                    fontSize: res(context, 18),
                    height: 1.5)),
          ),
          const Spacer(),
          Text("TAP TO REVEAL",
              style: TextStyle(
                  color: isDark ? theme.colorScheme.onSurface.withValues(alpha: 0.1) : Colors.black12,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _navBtn(IconData icon, VoidCallback onTap, bool active, bool isDark) {
    final theme = Theme.of(context);
    return IconButton(
      icon: Icon(icon,
          color: active
              ? theme.colorScheme.onSurface
              : theme.colorScheme.onSurface.withValues(alpha: 0.05),
          size: res(context, 28)),
      onPressed: active ? onTap : null,
    );
  }
}

class _GlassAlertAnimated extends StatefulWidget {
  final String message;
  final Color themeColor;
  final VoidCallback onDismiss;
  const _GlassAlertAnimated(
      {required this.message,
      required this.themeColor,
      required this.onDismiss});

  @override
  State<_GlassAlertAnimated> createState() => _GlassAlertAnimatedState();
}

class _GlassAlertAnimatedState extends State<_GlassAlertAnimated>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _scaleAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _controller.forward();
    Future.delayed(const Duration(milliseconds: 2000), () async {
      if (mounted) {
        await _controller.reverse();
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Material(
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(res(context, 25)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: res(context, 40)),
                padding: EdgeInsets.symmetric(
                    vertical: res(context, 18), horizontal: res(context, 35)),
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        widget.themeColor.withValues(alpha: 0.8),
                        widget.themeColor.withValues(alpha: 0.95),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(res(context, 25)),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.2))),
                child: Text(widget.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: res(context, 16))),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
