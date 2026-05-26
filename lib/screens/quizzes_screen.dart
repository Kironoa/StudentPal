import 'package:flutter/material.dart';
import 'package:mobile_app/models/study_resource_model.dart';
import 'package:mobile_app/services/study_resource_service.dart';
import 'package:mobile_app/providers/theme_provider.dart';
import 'package:mobile_app/services/alert_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'package:mobile_app/utils/responsive.dart';

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
  });
}

class QuizzesScreen extends ConsumerStatefulWidget {
  final int userId;
  const QuizzesScreen({super.key, required this.userId});

  @override
  ConsumerState<QuizzesScreen> createState() => _QuizzesScreenState();
}

class _QuizzesScreenState extends ConsumerState<QuizzesScreen> {
  final _resourceService = StudyResourceService();
  List<StudyResource> _quizzes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await _resourceService.getResources(widget.userId, 'quiz');
      if (mounted) {
        setState(() {
          _quizzes = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      if (mounted) AlertService().showError(context, "Error loading quizzes");
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
              Icons.quiz_outlined,
              size: res(context, 60),
              color: theme.hintColor.withValues(alpha: 0.2),
            ),
          ),
          SizedBox(height: res(context, 16)),
          Text(
            "No quizzes found",
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

  void _confirmDelete(StudyResource quiz) {
    AlertService().showConfirmDialog(
      context,
      title: 'Delete Quiz?',
      body: 'This action cannot be undone.',
      confirmLabel: 'DELETE',
      onConfirm: () async {
        await _resourceService.deleteResource(quiz.id!);
        if (!mounted) return;
        _loadQuizzes();
        _showGlassAlert("Quiz Deleted", color: Colors.redAccent);
      },
    );
  }

  void _showQuizOptions(StudyResource quiz, Color accent) {
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
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    Text("QUIZ OPTIONS",
                        style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2)),
                    SizedBox(height: res(context, 20)),
                    ListTile(
                      leading: Container(
                        padding: EdgeInsets.all(res(context, 8)),
                        decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12)),
                        child:
                            Icon(Icons.edit_note_rounded, color: accent),
                      ),
                      title: Text("Rename Quiz",
                          style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.bold)),
                      subtitle: Text("Change the title of this quiz",
                          style: TextStyle(
                              color: theme.hintColor,
                              fontSize: 11)),
                      onTap: () {
                        Navigator.pop(context);
                        _showRenameDialog(quiz, accent);
                      },
                    ),
                    ListTile(
                      onTap: () {
                        Navigator.pop(context);
                        _confirmDelete(quiz);
                      },
                      leading: Container(
                        padding: EdgeInsets.all(res(context, 8)),
                        decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12)),
                        child:
                            const Icon(Icons.delete_outline, color: Colors.redAccent),
                      ),
                      title: Text("Delete Quiz",
                          style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.bold)),
                      subtitle: Text("Remove this quiz from your library",
                          style: TextStyle(
                              color: theme.hintColor,
                              fontSize: 11)),
                    ),
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

  void _showRenameDialog(StudyResource quiz, Color accent) {
    final theme = Theme.of(context);
    final controller = TextEditingController(text: quiz.fileName);
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(res(context, 20))),
          title: Text("RENAME QUIZ",
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
                  quiz.fileName = controller.text;
                  await _resourceService.updateResource(quiz);
                  if (context.mounted) Navigator.pop(context);
                  if (!mounted) return;
                  _loadQuizzes();
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("QUIZZES",
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
          : _quizzes.isEmpty
              ? _buildEmptyState(theme)
              : ListView.builder(
                  padding: EdgeInsets.all(res(context, 20)),
                  itemCount: _quizzes.length,
                  itemBuilder: (context, index) {
                    final quiz = _quizzes[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: res(context, 15)),
                      decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(res(context, 24)),
                          border: Border.all(
                              color: theme.dividerColor.withValues(alpha: 0.1)),
                          boxShadow: [
                            if (themeState.brightness != Brightness.dark)
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4))
                          ]),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: res(context, 20),
                            vertical: res(context, 10)),
                        leading: Container(
                          padding: EdgeInsets.all(res(context, 10)),
                          decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(15)),
                          child: Icon(Icons.quiz_rounded, color: accentColor),
                        ),
                        title: Text(quiz.fileName,
                            style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.bold)),
                        subtitle: Text("Knowledge Test",
                            style: TextStyle(
                                color: theme.hintColor,
                                fontSize: 11)),
                        trailing: IconButton(
                          icon: Icon(Icons.more_horiz,
                              color: theme.hintColor),
                          onPressed: () => _showQuizOptions(quiz, accentColor),
                        ),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    QuizPlayInternal(resource: quiz))),
                      ),
                    );
                  },
                ),
    );
  }
}

class QuizPlayInternal extends ConsumerStatefulWidget {
  final StudyResource resource;
  const QuizPlayInternal({super.key, required this.resource});

  @override
  ConsumerState<QuizPlayInternal> createState() => _QuizPlayInternalState();
}

class _QuizPlayInternalState extends ConsumerState<QuizPlayInternal> {
  List<QuizQuestion> _questions = [];
  int _currentIndex = 0;
  int _score = 0;
  int? _selectedIdx;
  bool _isAnswered = false;

  @override
  void initState() {
    super.initState();
    _parseContent(widget.resource.content ?? "");
  }

  void _parseContent(String content) {
    List<QuizQuestion> temp = [];
    final blocks = content.split(RegExp(r'Q:'));
    for (var block in blocks) {
      if (block.trim().isEmpty) continue;
      try {
        final lines = block.split('\n');
        String question = lines[0].trim();
        List<String> options = [];
        int correct = 0;

        for (var line in lines) {
          if (line.contains('A)')) {
            options.add(line.replaceAll('A)', '').trim());
          }
          if (line.contains('B)')) {
            options.add(line.replaceAll('B)', '').trim());
          }
          if (line.contains('C)')) {
            options.add(line.replaceAll('C)', '').trim());
          }
          if (line.contains('D)')) {
            options.add(line.replaceAll('D)', '').trim());
          }
          if (line.contains('Correct:')) {
            String letter = line.split(':')[1].trim().toUpperCase();
            correct = letter.codeUnitAt(0) - 65;
          }
        }
        if (options.length >= 2) {
          temp.add(QuizQuestion(
              question: question, options: options, correctIndex: correct));
        }
      } catch (_) {}
    }
    setState(() => _questions = temp);
  }

  void _handleAnswer(int idx) {
    if (_isAnswered) return;
    setState(() {
      _selectedIdx = idx;
      _isAnswered = true;
      if (idx == _questions[_currentIndex].correctIndex) _score++;
    });
  }

  void _next() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedIdx = null;
        _isAnswered = false;
      });
    } else {
      _showFinishDialog();
    }
  }

  void _showFinishDialog() {
    final theme = Theme.of(context);
    final themeState = ref.read(themeProvider);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          title: Text("QUIZ FINISHED",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("$_score / ${_questions.length}",
                  style: TextStyle(
                      color: themeState.accentColor,
                      fontSize: 40,
                      fontWeight: FontWeight.w900)),
              Text("Correct Answers",
                  style: TextStyle(
                      color: theme.hintColor)),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15))),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Text("BACK TO LIBRARY",
                    style:
                        TextStyle(color: theme.colorScheme.onSurface)),
              ),
            )
          ],
        ),
      ),
    );
  }

@override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeState = ref.read(themeProvider);
    final accent = themeState.accentColor;

    if (_questions.isEmpty) {
      return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor);
    }

    final q = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("QUESTION ${_currentIndex + 1}",
            style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 2)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: EdgeInsets.all(res(context, 25)),
        child: Column(
          children: [
            LinearProgressIndicator(
                value: progress,
                backgroundColor: theme.dividerColor.withValues(alpha: 0.3),
                color: accent,
                minHeight: 6,
                borderRadius: BorderRadius.circular(10)),
            SizedBox(height: res(context, 40)),
            Flexible(
              child: Text(q.question,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: res(context, 20),
                      fontWeight: FontWeight.bold)),
            ),
            const Spacer(),
            ...List.generate(q.options.length, (index) {
              Color cardColor = theme.colorScheme.surface;
              Color borderColor = theme.dividerColor;
              Color textColor = theme.colorScheme.onSurface;

              if (_isAnswered) {
                if (index == q.correctIndex) {
                  cardColor = Colors.green.withValues(alpha: 0.15);
                  borderColor = Colors.green;
                  textColor = Colors.green.shade700;
                } else if (index == _selectedIdx) {
                  cardColor = Colors.red.withValues(alpha: 0.15);
                  borderColor = Colors.red;
                  textColor = Colors.red.shade700;
                }
              } else if (_selectedIdx == index) {
                borderColor = accent;
              }

              return GestureDetector(
                onTap: () => _handleAnswer(index),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor, width: 2),
                      boxShadow: [
                        if (theme.brightness != Brightness.dark && !_isAnswered)
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10)
                      ]),
                  child: Text(q.options[index],
                      style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w500)),
                ),
              );
            }),
            const Spacer(),
            if (_isAnswered)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    padding: EdgeInsets.symmetric(vertical: 18, horizontal: 32),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15))),
                onPressed: _next,
                child: Text("CONTINUE",
                    style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w900)),
              ),
          ],
        ),
      ),
    );
  }

}

