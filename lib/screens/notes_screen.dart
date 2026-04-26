import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:mobile_app/models/study_note_model.dart';
import 'package:mobile_app/models/study_resource_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/widgets/text_field.dart';
import 'package:mobile_app/services/notes_service.dart';
import 'package:mobile_app/providers/theme_provider.dart';
import 'package:mobile_app/services/ai_service.dart';
import 'package:mobile_app/services/study_resource_service.dart';
import 'package:mobile_app/services/notification_service.dart';
import 'package:mobile_app/services/alert_service.dart';
import 'package:mobile_app/screens/flashcards_screen.dart';
import 'package:mobile_app/utils/responsive.dart';

class NotesScreen extends ConsumerStatefulWidget {
  final int userId;
  const NotesScreen({super.key, required this.userId});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  final NotesService _notesService = NotesService();
  final AIService _aiService = AIService();
  final StudyResourceService _resourceService = StudyResourceService();
  final NotificationService _notificationService = NotificationService();
  final AlertService _alertService = AlertService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  Future<List<StudyNote>>? _notesFuture;
  bool _isLoading = false;
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _refreshNotes();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _refreshNotes() {
    setState(() {
      _notesFuture = _notesService.getNotes(widget.userId);
    });
  }

  // --- AI GENERATION LOGIC ---

  Future<void> _generateAISummary(StudyNote note) async {
    setState(() => _isLoading = true);
    try {
      final promptText =
          "Summarize the following study note into concise bullet points. Focus on key concepts:\n\n${note.description ?? note.content ?? ''}";

      final summary = await _aiService.sendMessage(promptText);

      if (mounted && summary.isNotEmpty) {
        final newResource = StudyResource(
          fileName:
              "Summary: ${note.title.isNotEmpty ? note.title : 'Untitled'}",
          category: 'summary',
          content: summary,
          localPath: '',
          userId: widget.userId,
        );
        await _resourceService.addResource(widget.userId, newResource);

        _showGlassAlert("Summary Saved to Resources!");
      }
    } catch (e) {
      _showGlassAlert("Summary failed: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _generateFlashcards(StudyNote note, int count) async {
    String currentContent = note.description ?? note.content ?? "";

    if (currentContent.trim().length < 10) {
      _showGlassAlert("Content is too short to generate useful cards!",
          color: Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final promptText = """
Generate exactly $count Flashcards based on this text.
Format: Q: [Question] A: [Answer]

TEXT:
$currentContent
""";

      final response = await _aiService.sendMessage(promptText);

      if (mounted && response.isNotEmpty) {
        final newResource = StudyResource(
          fileName: "Cards: ${note.title.isNotEmpty ? note.title : 'Untitled'}",
          category: 'flashcard',
          content: response,
          localPath: '',
          userId: widget.userId,
        );
        await _resourceService.addResource(widget.userId, newResource);
        if (mounted && context.mounted) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      FlashcardsScreen(userId: widget.userId)));
        }
      }
    } catch (e) {
      _showGlassAlert("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _generateQuiz(StudyNote note, int count) async {
    setState(() => _isLoading = true);
    try {
      final promptText = """
Generate a $count question multiple choice quiz. 
Format:
Q: [Question]
A) [Option]
B) [Option]
C) [Option]
D) [Option]
Correct: [Letter]

Text: ${note.description ?? note.content ?? ''}
""";

      final response = await _aiService.sendMessage(promptText);

      if (mounted && response.isNotEmpty) {
        final newResource = StudyResource(
          fileName: "Quiz: ${note.title.isNotEmpty ? note.title : 'Untitled'}",
          category: 'quiz',
          content: response,
          localPath: '',
          userId: widget.userId,
        );
        await _resourceService.addResource(widget.userId, newResource);
        _showGlassAlert("Quiz Generated & Saved to Resources!");
      }
    } catch (e) {
      _showGlassAlert("Quiz error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- UI COMPONENTS ---

  void _showGlassAlert(String message, {Color? color}) {
    if (!mounted) return;
    _alertService.showGlassAlert(context, message, color: color);
  }

  void _showAiTools(StudyNote note) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.all(res(context, 25)),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.9),
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(res(context, 30))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("STUDY ASSISTANT",
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: res(context, 16),
                      letterSpacing: 1.2,
                      fontFamily: 'Poppins')),
              SizedBox(height: res(context, 20)),
              _buildAiTile(Icons.summarize_rounded, "Summarize Note",
                  "Get a quick breakdown of your content", () {
                Navigator.pop(context);
                _generateAISummary(note);
              }),
              _buildAiTile(Icons.style_rounded, "Create Flashcards",
                  "Turn this note into study cards", () {
                Navigator.pop(context);
                _showQuantityPicker(note, "Flashcards");
              }),
              _buildAiTile(Icons.quiz_rounded, "Generate Quiz",
                  "Test your knowledge on this topic", () {
                Navigator.pop(context);
                _showQuantityPicker(note, "Quiz Questions");
              }),
              SizedBox(height: res(context, 10)),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuantityPicker(StudyNote note, String type) {
    int quantity = 5;
    final theme = Theme.of(context);
    final accent = ref.read(themeProvider).accentColor;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: EdgeInsets.all(res(context, 30)),
            decoration: BoxDecoration(
              color: const Color(0xFF141414).withValues(alpha: 0.95),
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(res(context, 30))),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("HOW MANY $type?",
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                SizedBox(height: res(context, 30)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildQtyBtn(Icons.remove, () {
                      if (quantity > 1) setModalState(() => quantity--);
                    }),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text("$quantity",
                          style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              color: accent,
                              fontFamily: 'Poppins')),
                    ),
                    _buildQtyBtn(Icons.add, () {
                      if (quantity < 20) setModalState(() => quantity++);
                    }),
                  ],
                ),
                const SizedBox(height: 10),
                const Text("Select between 1 and 20",
                    style: TextStyle(color: Colors.white24, fontSize: 12)),
                SizedBox(height: res(context, 40)),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      if (type == "Flashcards") {
                        _generateFlashcards(note, quantity);
                      } else {
                        _generateQuiz(note, quantity);
                      }
                    },
                    child: Text("GENERATE NOW",
                        style: TextStyle(
                            color: theme.scaffoldBackgroundColor,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(color: Colors.white10),
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildAiTile(
      IconData icon, String title, String subtitle, VoidCallback onTap) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(res(context, 8)),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: theme.colorScheme.primary),
      ),
      title: Text(title,
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: res(context, 14))),
      subtitle: Text(subtitle,
          style: TextStyle(fontSize: res(context, 11), color: theme.hintColor)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: Text(
              "STUDY NOTES",
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
            actions: [
              IconButton(
                icon: Icon(
                  _isSearching ? Icons.close : Icons.search_rounded,
                  color: accentColor,
                  size: 22,
                ),
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      _searchQuery = '';
                      _searchController.clear();
                    }
                  });
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                if (_isSearching)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      res(context, 16), res(context, 8),
                      res(context, 16), 0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(res(context, 12)),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.4)),
                      ),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: TextStyle(
                          fontSize: res(context, 14),
                          color: theme.colorScheme.onSurface),
                        decoration: InputDecoration(
                          hintText: 'Search notes...',
                          hintStyle: TextStyle(
                            color: theme.hintColor,
                            fontSize: res(context, 13)),
                          prefixIcon: Icon(Icons.search_rounded,
                            color: accentColor, size: 20),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: res(context, 12)),
                        ),
                        onChanged: (v) => setState(
                          () => _searchQuery = v.toLowerCase()),
                      ),
                    ),
                  ),
                Expanded(
                  child: _notesFuture == null
                      ? Center(child: CircularProgressIndicator(color: accentColor))
                      : FutureBuilder<List<StudyNote>>(
                          future: _notesFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Center(
                                  child:
                                      CircularProgressIndicator(color: accentColor));
                            }
                            final allNotes = snapshot.data ?? [];
                            final data = _searchQuery.isEmpty
                              ? allNotes
                              : allNotes.where((n) =>
                                  n.title.toLowerCase().contains(_searchQuery) ||
                                  (n.description ?? '').toLowerCase().contains(_searchQuery) ||
                                  (n.content ?? '').toLowerCase().contains(_searchQuery)
                                ).toList();

                            if (data.isEmpty && _searchQuery.isNotEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.search_off_rounded,
                                      size: res(context, 50),
                                      color: theme.hintColor.withValues(alpha: 0.2)),
                                    SizedBox(height: res(context, 12)),
                                    Text('No notes match "$_searchQuery"',
                                      style: TextStyle(
                                        color: theme.hintColor,
                                        fontSize: res(context, 13))),
                                  ],
                                ),
                              );
                            }

                            if (data.isEmpty) return _buildEmptyState(theme);

                            return ListView.builder(
                              padding: EdgeInsets.fromLTRB(
                                res(context, 20),
                                res(context, 10),
                                res(context, 20),
                                res(context, 100),
                              ),
                              itemCount: data.length,
                              itemBuilder: (context, index) =>
                                  _buildNoteTile(data[index], index, data.length),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: FloatingActionButton.extended(
            heroTag: "add_note",
            onPressed: () => _showNoteForm(),
            backgroundColor: accentColor,
            elevation: 4,
            icon: Icon(Icons.note_add_rounded,
                color: Colors.white, size: res(context, 20)),
            label: Text(
              "NEW NOTE",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: res(context, 14)),
            ),
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black54,
            child: Center(child: CircularProgressIndicator(color: accentColor)),
          ),
      ],
    );
  }

  Widget _buildNoteTile(StudyNote item, int index, int totalItems) {
    final theme = Theme.of(context);
    final formattedDate =
        DateFormat('MMM dd, yyyy').format(item.createdAt ?? DateTime.now());

    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: res(context, 12),
                height: res(context, 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: theme.scaffoldBackgroundColor,
                      width: res(context, 2)),
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
                  onTap: () => _viewNoteDetails(item),
                  child: Padding(
                    padding: EdgeInsets.all(res(context, 16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(formattedDate.toUpperCase(),
                                style: TextStyle(
                                    color: theme.colorScheme.secondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: res(context, 10))),
                            Icon(Icons.auto_awesome,
                                size: 14,
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.5)),
                          ],
                        ),
                        SizedBox(height: res(context, 4)),
                        Text(item.title.isEmpty ? "Untitled Note" : item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: res(context, 17),
                                fontWeight: FontWeight.bold)),
                        SizedBox(height: res(context, 6)),
                        Text(item.description ?? "No content provided.",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                                fontSize: res(context, 13))),
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

  void _viewNoteDetails(StudyNote item) {
    final theme = Theme.of(context);
    final formattedDate = DateFormat('MMMM dd, yyyy • hh:mm a')
        .format(item.createdAt ?? DateTime.now());

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85),
          padding: EdgeInsets.all(res(context, 25)),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.9),
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(res(context, 30))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: res(context, 40),
                  height: res(context, 4),
                  decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10))),
              SizedBox(height: res(context, 25)),
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      Text(item.title.isEmpty ? "Untitled Note" : item.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: res(context, 22),
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface)),
                      SizedBox(height: res(context, 20)),
                      _detailItem(Icons.calendar_today_rounded, "Created On",
                          formattedDate),
                      _detailItem(Icons.notes_rounded, "Content",
                          item.description ?? "No content provided."),
                      if (item.content != null && item.content!.isNotEmpty)
                        _detailItem(Icons.summarize_rounded, "AI Summary",
                            item.content!),
                    ],
                  ),
                ),
              ),
              SizedBox(height: res(context, 30)),
              Row(
                children: [
                  IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showAiTools(item);
                      },
                      icon: Icon(Icons.auto_awesome,
                          color: theme.colorScheme.primary),
                      tooltip: "AI Tools"),
                  IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showReminderPicker(item);
                      },
                      icon:
                          Icon(Icons.alarm, color: theme.colorScheme.secondary),
                      tooltip: "Set Reminder"),
                  SizedBox(width: res(context, 10)),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                          padding:
                              EdgeInsets.symmetric(vertical: res(context, 15)),
                          side: const BorderSide(color: Colors.redAccent),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(res(context, 12)))),
                      onPressed: () {
                        Navigator.pop(context);
                        if (item.id != null) _confirmDelete(item.id!);
                      },
                      child: Text("DELETE",
                          style: TextStyle(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.bold,
                              fontSize: res(context, 14))),
                    ),
                  ),
                  SizedBox(width: res(context, 15)),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          padding:
                              EdgeInsets.symmetric(vertical: res(context, 15)),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(res(context, 12)))),
                      onPressed: () {
                        Navigator.pop(context);
                        _showNoteForm(note: item);
                      },
                      child: Text("EDIT NOTE",
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
    );
  }

  void _confirmDelete(int noteId) {
    AlertService().showConfirmDialog(
      context,
      title: 'Delete Note?',
      body: 'This action cannot be undone.',
      confirmLabel: 'DELETE',
      onConfirm: () async {
        await _notesService.deleteNote(noteId);
        _refreshNotes();
        _showGlassAlert("Note Deleted", color: Colors.redAccent);
      },
    );
  }

  Widget _detailItem(IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: res(context, 15)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              color: theme.colorScheme.secondary, size: res(context, 20)),
          SizedBox(width: res(context, 15)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(),
                    style: TextStyle(
                        fontSize: res(context, 10),
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.secondary
                            .withValues(alpha: 0.7))),
                Text(value,
                    style: TextStyle(
                        fontSize: res(context, 14),
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.9))),
              ],
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
              Icons.note_outlined,
              size: res(context, 60),
              color: theme.hintColor.withValues(alpha: 0.2),
            ),
          ),
          SizedBox(height: res(context, 16)),
          Text(
            "No notes yet",
            style: TextStyle(
              color: theme.hintColor,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              fontSize: res(context, 14),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tap + to create your first note",
            style: TextStyle(
              color: theme.hintColor.withValues(alpha: 0.5),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  void _showNoteForm({StudyNote? note}) {
    final theme = Theme.of(context);

    _titleController.text = note?.title ?? "";
    _contentController.text = note?.description ?? "";

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: EdgeInsets.all(res(context, 25)),
            decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.vertical(
                    top: Radius.circular(res(context, 30)))),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: res(context, 20)),
                  Text(note == null ? "NEW NOTE" : "EDIT NOTE",
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: res(context, 18))),
                  SizedBox(height: res(context, 20)),
                  CustomTextField(
                      controller: _titleController, // Using class field
                      hintText: "Note Title",
                      prefixIcon: Icons.title_rounded),
                  SizedBox(height: res(context, 15)),
                  CustomTextField(
                      controller: _contentController, // Using class field
                      hintText: "Start writing...",
                      prefixIcon: Icons.notes_rounded,
                      maxLines: 8),
                  SizedBox(height: res(context, 25)),
                  Row(
                    children: [
                      Expanded(
                          child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text("CANCEL",
                                  style: TextStyle(color: theme.hintColor)))),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12))),
                          onPressed: () async {
                            // Trim text to ensure it's truly not empty
                            final String title = _titleController.text.trim();
                            final String desc = _contentController.text.trim();

                            if (title.isNotEmpty) {
                              final noteData = StudyNote(
                                  id: note?.id,
                                  userId: widget.userId,
                                  title: title,
                                  description: desc,
                                  content: note?.content ?? '',
                                  dateCreated:
                                      note?.createdAt?.toIso8601String());

                              await _notesService.saveNote(
                                  widget.userId, noteData);

                              // Clear controllers after saving to reset for next use
                              _titleController.clear();
                              _contentController.clear();

                              if (context.mounted) Navigator.pop(context);
                              _refreshNotes();
                              _showGlassAlert(note == null
                                  ? "Note Saved!"
                                  : "Note Updated!");
                            } else {
                              _showGlassAlert("Please enter a title",
                                  color: Colors.orange);
                            }
                          },
                          child: Text(note == null ? "SAVE" : "UPDATE",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: res(context, 10)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showReminderPicker(StudyNote note) async {
    final theme = Theme.of(context);
    final now = DateTime.now();
    DateTime selectedDate = now.add(const Duration(days: 1));
    int selectedOption = 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.all(res(context, 25)),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.95),
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(res(context, 30))),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("SET REMINDER",
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: res(context, 16),
                        letterSpacing: 1.2)),
                SizedBox(height: res(context, 20)),
                ListTile(
                  leading: Icon(Icons.wb_sunny,
                      color: selectedOption == 0
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                  title: Text("Tomorrow",
                      style: TextStyle(
                          color: selectedOption == 0
                              ? theme.colorScheme.primary
                              : null)),
                  subtitle: Text(DateFormat('MMM dd, h:mm a')
                      .format(now.add(const Duration(days: 1)))),
                  selected: selectedOption == 0,
                  onTap: () {
                    setModalState(() {
                      selectedOption = 0;
                      selectedDate = now.add(const Duration(days: 1));
                    });
                  },
                ),
                ListTile(
                  leading: Icon(Icons.calendar_today,
                      color: selectedOption == 1
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                  title: Text("Next Week",
                      style: TextStyle(
                          color: selectedOption == 1
                              ? theme.colorScheme.primary
                              : null)),
                  subtitle: Text(DateFormat('MMM dd, h:mm a')
                      .format(now.add(const Duration(days: 7)))),
                  selected: selectedOption == 1,
                  onTap: () {
                    setModalState(() {
                      selectedOption = 1;
                      selectedDate = now.add(const Duration(days: 7));
                    });
                  },
                ),
                ListTile(
                  leading: Icon(Icons.event,
                      color: selectedOption == 2
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                  title: Text("Pick Date",
                      style: TextStyle(
                          color: selectedOption == 2
                              ? theme.colorScheme.primary
                              : null)),
                  subtitle: const Text("Choose a custom date"),
                  selected: selectedOption == 2,
                  onTap: () async {
                    if (!mounted) return;
                    Navigator.pop(context);
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: now,
                      lastDate: now.add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedDate),
                      );
                      if (time != null) {
                        selectedDate = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      }
                    }
                    if (note.id != null && selectedDate.isAfter(now)) {
                      await _notificationService.scheduleNoteReminders(
                        noteId: note.id!,
                        noteTitle: note.title.isNotEmpty
                            ? note.title
                            : 'Untitled Note',
                        reminderTime: selectedDate,
                      );
                      _showGlassAlert(
                          "Reminder set for ${DateFormat('MMM dd, h:mm a').format(selectedDate)}");
                    }
                  },
                ),
                SizedBox(height: res(context, 20)),
                if (note.id != null) ...[
                  OutlinedButton(
                    onPressed: () async {
                      await _notificationService.cancelNoteReminder(note.id!);
                      if (context.mounted) Navigator.pop(context);
                      _showGlassAlert("Reminder cancelled",
                          color: Colors.orange);
                    },
                    child: const Text("CANCEL REMINDER"),
                  ),
                  SizedBox(height: res(context, 10)),
                ],
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    minimumSize: Size(double.infinity, res(context, 50)),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    if (note.id != null) {
                      await _notificationService.scheduleNoteReminders(
                        noteId: note.id!,
                        noteTitle: note.title.isNotEmpty
                            ? note.title
                            : 'Untitled Note',
                        reminderTime: selectedDate,
                      );
                      _showGlassAlert(
                          "Reminder set for ${DateFormat('MMM dd, h:mm a').format(selectedDate)}");
                    }
                  },
                  child: const Text("SET REMINDER"),
                ),
              ],
            ),
          ),
        ),
      ),
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
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: res(context, 50)),
            padding: EdgeInsets.symmetric(
                vertical: res(context, 20), horizontal: res(context, 25)),
            decoration: BoxDecoration(
                color: widget.themeColor.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(res(context, 20)),
                boxShadow: [
                  BoxShadow(
                      color: widget.themeColor.withValues(alpha: 0.4),
                      blurRadius: 20)
                ]),
            child: Text(widget.message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ),
        ),
      ),
    );
  }
}
