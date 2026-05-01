import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_app/helper/db_helper.dart';
import 'package:mobile_app/providers/theme_provider.dart';
import 'package:mobile_app/providers/user_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final int userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _picker = ImagePicker();
  final _fullNameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _schoolController = TextEditingController();
  final _courseController = TextEditingController();
  final _yearLevelController = TextEditingController();

  String? _profileImagePath;
  bool _isEditing = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _nicknameController.dispose();
    _schoolController.dispose();
    _courseController.dispose();
    _yearLevelController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await DatabaseHelper().getUser(widget.userId);
      if (mounted && user != null) {
        setState(() {
          _fullNameController.text = user['fullName'] ?? '';
          _nicknameController.text = user['nickname'] ?? '';
          _schoolController.text = user['school'] ?? '';
          _courseController.text = user['course'] ?? '';
          _yearLevelController.text = user['yearLevel'] ?? '';
          _profileImagePath = user['profilePath'];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      await DatabaseHelper()
          .updateUserProfilePhoto(widget.userId, pickedFile.path);
      setState(() => _profileImagePath = pickedFile.path);
      if (mounted) ref.invalidate(userProvider(widget.userId));
    }
  }

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();
    try {
      await DatabaseHelper().updateUserProfile(
        widget.userId,
        fullName: _fullNameController.text.trim().isNotEmpty
            ? _fullNameController.text.trim() : null,
        nickname: _nicknameController.text.trim().isNotEmpty
            ? _nicknameController.text.trim() : null,
        school: _schoolController.text.trim().isNotEmpty
            ? _schoolController.text.trim() : null,
        course: _courseController.text.trim().isNotEmpty
            ? _courseController.text.trim() : null,
        yearLevel: _yearLevelController.text.trim().isNotEmpty
            ? _yearLevelController.text.trim() : null,
      );

      final displayName = _nicknameController.text.trim().isNotEmpty
          ? _nicknameController.text.trim()
          : _fullNameController.text.trim();

      if (displayName.isNotEmpty) {
        await DatabaseHelper().saveSettings(name: displayName);
        if (mounted) ref.read(themeProvider.notifier).loadSettings();
      }

      setState(() => _isEditing = false);
      if (mounted) ref.invalidate(userProvider(widget.userId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated!',
                style: TextStyle(color: Colors.white)),
            backgroundColor: Theme.of(context).primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final mq = MediaQuery.of(context);
    // Use viewInsets (keyboard height) + safe area bottom for total bottom padding
    final bottomPadding = mq.viewInsets.bottom + mq.padding.bottom + 20;

    return Scaffold(
      // Let Scaffold resize so the scroll area shrinks when keyboard appears
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.grid_view_rounded,
              color: theme.colorScheme.primary, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('MY PROFILE',
            style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w900,
                fontSize: 14,
                letterSpacing: 1.5)),
        actions: [
          if (!_isEditing && !_isLoading)
            TextButton.icon(
              onPressed: () => setState(() => _isEditing = true),
              icon: Icon(Icons.edit_outlined, color: accent, size: 18),
              label: Text('EDIT',
                  style:
                      TextStyle(color: accent, fontWeight: FontWeight.w900)),
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: accent))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              // Top padding accounts for status bar via SafeArea equivalent
              padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _isEditing ? _pickImage : null,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: accent.withValues(alpha: 0.3), width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: accent.withValues(alpha: 0.1),
                        backgroundImage: (_profileImagePath != null &&
                                File(_profileImagePath!).existsSync())
                            ? FileImage(File(_profileImagePath!))
                            : null,
                        child: (_profileImagePath == null ||
                                !File(_profileImagePath!).existsSync())
                            ? Icon(Icons.person_rounded,
                                color: accent, size: 50)
                            : null,
                      ),
                    ),
                  ),
                  if (_isEditing)
                    TextButton(
                      onPressed: _pickImage,
                      child: Text('Change Photo',
                          style: TextStyle(
                              color: accent, fontWeight: FontWeight.w600)),
                    ),
                  const SizedBox(height: 24),
                  _buildProfileCard(theme, accent),
                  const SizedBox(height: 20),
                  if (_isEditing)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                setState(() => _isEditing = false),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: theme.hintColor),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text('CANCEL',
                                style: TextStyle(
                                    color: theme.hintColor,
                                    fontWeight: FontWeight.w900)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('SAVE',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900)),
                          ),
                        ),
                      ],
                    ),
                  // Extra breathing room below buttons
                  const SizedBox(height: 8),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileCard(ThemeData theme, Color accent) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildField('Full Name', Icons.person_rounded,
              _fullNameController, _isEditing),
          _buildDivider(),
          _buildField('Nickname', Icons.face_rounded,
              _nicknameController, _isEditing),
          _buildDivider(),
          _buildField('School/University', Icons.school_rounded,
              _schoolController, _isEditing),
          _buildDivider(),
          _buildField('Course/Program', Icons.menu_book_rounded,
              _courseController, _isEditing),
          _buildDivider(),
          _buildField('Year Level', Icons.calendar_today_rounded,
              _yearLevelController, _isEditing),
        ],
      ),
    );
  }

  Widget _buildField(String label, IconData icon,
      TextEditingController controller, bool isEditing) {
    final theme = Theme.of(context);
    final accent = theme.primaryColor;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 10,
                        color: theme.hintColor,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                isEditing
                    ? TextField(
                        controller: controller,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          isDense: true,
                        ),
                      )
                    : Text(
                        controller.text.isNotEmpty
                            ? controller.text
                            : 'Not set',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: controller.text.isNotEmpty
                                ? theme.colorScheme.onSurface
                                : theme.hintColor),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
        height: 1,
        color: Theme.of(context).dividerColor.withValues(alpha: 0.3));
  }
}
