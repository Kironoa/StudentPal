import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:mobile_app/models/study_resource_model.dart';
import 'package:mobile_app/services/study_resource_service.dart';
import 'package:mobile_app/providers/theme_provider.dart';
import 'package:mobile_app/services/alert_service.dart';
import 'package:mobile_app/utils/responsive.dart';

class ResourcesScreen extends ConsumerStatefulWidget {
  final int userId;
  const ResourcesScreen({super.key, required this.userId});

  @override
  ConsumerState<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends ConsumerState<ResourcesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _resourceService = StudyResourceService();
  final _searchController = TextEditingController();

  bool _isLoading = false;
  bool _isSearching = false;
  String _currentCategory = 'pdf';
  String _searchQuery = "";
  List<StudyResource> _resources = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadResources();
  }

  void _handleTabSelection() {
    if (!_tabController.indexIsChanging) {
      final categories = ['pdf', 'doc', 'jpg'];
      setState(() => _currentCategory = categories[_tabController.index]);
      _loadResources();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadResources() async {
    final data =
        await _resourceService.getResources(widget.userId, _currentCategory);
    setState(() => _resources = data);
  }

  
  void _showGlassAlert(String message, {Color? color}) {
    AlertService().showGlassAlert(context, message, color: color);
  }

  void _confirmDeleteResource(StudyResource data) {
    AlertService().showConfirmDialog(
      context,
      title: 'Delete File?',
      body: 'This action cannot be undone.',
      confirmLabel: 'DELETE',
      onConfirm: () async {
        await _resourceService.deleteResource(data.id!);
        _loadResources();
        _showGlassAlert("File Deleted", color: Colors.redAccent);
      },
    );
  }

  void _showRenameDialog(StudyResource data, Color accent) {
    final theme = Theme.of(context);
    final controller = TextEditingController(text: data.fileName);
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(res(context, 20))),
          title: Text("RENAME FILE",
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
                  data.fileName = controller.text;
                  await _resourceService.updateResource(data);
                  if (context.mounted) Navigator.pop(context);
                  _loadResources();
                  _showGlassAlert("File Renamed");
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

  Future<void> _handleFileAction(StudyResource fileData) async {
    final path = fileData.localPath;
    if (path != null && await File(path).exists()) {
      await OpenFilex.open(path);
    } else {
      _showGlassAlert("File missing or moved", color: Colors.redAccent);
    }
  }

  Future<void> _uploadResource() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png', 'jpeg'],
    );

    if (result == null || result.files.single.path == null) return;

    final file = result.files.single;
    setState(() => _isLoading = true);

    try {
      final directory = await getApplicationDocumentsDirectory();
      final localPath =
          '${directory.path}/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      await File(file.path!).copy(localPath);

      final ext = file.extension?.toLowerCase() ?? '';
      final category = (ext == 'pdf')
          ? 'pdf'
          : (ext == 'doc' || ext == 'docx')
              ? 'doc'
              : 'jpg';

      await _resourceService.addResource(
        widget.userId,
        StudyResource(
          fileName: file.name,
          localPath: localPath,
          category: category,
          content: "",
        ),
      );

      await _loadResources();
      _showGlassAlert("File Uploaded Successfully!");
    } catch (e) {
      _showGlassAlert("Upload failed: $e", color: Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showResourceOptions(StudyResource data, Color accent) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
                  Text("RESOURCE OPTIONS",
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: res(context, 16),
                          letterSpacing: 1.2,
                          fontFamily: 'Poppins')),
                  SizedBox(height: res(context, 20)),
                  _buildOptionTile(
                      Icons.visibility_rounded, "View File", "Open this document",
                      () {
                    Navigator.pop(context);
                    _handleFileAction(data);
                  }),
                  _buildOptionTile(
                      Icons.edit_note_rounded, "Rename", "Change file name",
                      () {
                    Navigator.pop(context);
                    _showRenameDialog(data, accent);
                  }),
                  _buildOptionTile(
                      Icons.delete_outline_rounded, "Delete", "Remove from library",
                      () {
                    Navigator.pop(context);
                    _confirmDeleteResource(data);
                  }, isDestructive: true),
                  SizedBox(height: res(context, 10)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile(
      IconData icon, String title, String subtitle, VoidCallback onTap,
      {bool isDestructive = false}) {
    final theme = Theme.of(context);
    final color = isDestructive ? Colors.redAccent : theme.colorScheme.primary;
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(res(context, 8)),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color),
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
    final accentColor = ref.read(themeProvider).accentColor;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: _buildAppBar(accentColor),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildFileGrid('pdf', Icons.picture_as_pdf_rounded, accentColor),
              _buildFileGrid('doc', Icons.description_rounded, accentColor),
              _buildFileGrid('jpg', Icons.image_rounded, accentColor),
            ],
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: FloatingActionButton.extended(
            heroTag: "upload_resource",
            onPressed: _uploadResource,
            backgroundColor: accentColor,
            elevation: 4,
            icon: Icon(Icons.cloud_upload_rounded,
                color: Colors.white, size: res(context, 20)),
            label: Text(
              "UPLOAD FILE",
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

  PreferredSizeWidget _buildAppBar(Color accentColor) {
    final theme = Theme.of(context);
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.grid_view_rounded,
            size: res(context, 22), color: accentColor),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: _isSearching ? _buildSearchField() : _buildTitleText(),
      actions: [
        IconButton(
          icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded,
              size: res(context, 22), color: theme.colorScheme.onSurface),
          onPressed: () => setState(() {
            _isSearching = !_isSearching;
            if (!_isSearching) {
              _searchController.clear();
              _searchQuery = "";
            }
          }),
        ),
        SizedBox(width: res(context, 10)),
      ],
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: accentColor,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: accentColor,
        unselectedLabelColor: theme.hintColor,
        labelStyle: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: res(context, 11),
            letterSpacing: 1.2),
        tabs: const [Tab(text: "PDFS"), Tab(text: "DOCS"), Tab(text: "IMAGES")],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      style: TextStyle(fontSize: res(context, 14)),
      decoration: const InputDecoration(
          hintText: "Search Resources...", border: InputBorder.none),
      onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
    );
  }

  Widget _buildTitleText() {
    return Text("STUDY RESOURCES",
        style: TextStyle(
            letterSpacing: 1.5,
            fontWeight: FontWeight.w900,
            fontSize: res(context, 16)));
  }

  Widget _buildFileGrid(String category, IconData icon, Color accent) {
    final files = _resources
        .where((f) => f.fileName.toLowerCase().contains(_searchQuery))
        .toList();
    if (files.isEmpty) {
      return _buildEmptyState(icon, "No $category files found");
    }

    return GridView.builder(
      padding: EdgeInsets.fromLTRB(res(context, 20), res(context, 20),
          res(context, 20), res(context, 100)),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: res(context, 15),
          crossAxisSpacing: res(context, 15),
          childAspectRatio: 0.85),
      itemCount: files.length,
      itemBuilder: (context, index) =>
          _buildResourceCard(files[index], icon, index, accent),
    );
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  Widget _buildResourceCard(
      StudyResource data, IconData icon, int index, Color accentColor) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => _handleFileAction(data),
      onLongPress: () => _showResourceOptions(data, accentColor),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(res(context, 20)),
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(res(context, 20))),
                ),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.all(res(context, 14)),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(res(context, 16)),
                    ),
                    child: Icon(icon, size: res(context, 36), color: accentColor),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: res(context, 12)),
              child: Column(
                children: [
                  Text(data.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: res(context, 12), fontWeight: FontWeight.bold)),
                  Text(
                    _formatDate(data.dateAdded),
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.hintColor.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(res(context, 10)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.more_vert_rounded,
                        size: res(context, 18),
                        color: theme.hintColor),
                    onPressed: () => _showResourceOptions(data, accentColor),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    final theme = Theme.of(context);
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
            child: Icon(icon,
                size: res(context, 60),
                color: theme.hintColor.withValues(alpha: 0.2)),
          ),
          SizedBox(height: res(context, 16)),
          Text(message,
              style: TextStyle(
                  color: theme.hintColor, fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: res(context, 14))),
          const SizedBox(height: 8),
          Text(
            "Upload a file to get started",
            style: TextStyle(
              color: theme.hintColor.withValues(alpha: 0.5),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}


