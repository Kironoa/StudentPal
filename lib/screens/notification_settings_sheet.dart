import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_app/helper/db_helper.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificationSettingsSheet extends StatefulWidget {
  const NotificationSettingsSheet({super.key});

  @override
  State<NotificationSettingsSheet> createState() => _NotificationSettingsSheetState();
}

class _NotificationSettingsSheetState extends State<NotificationSettingsSheet> {
  bool _notifyClasses = true;
  bool _notifyAssignments = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await DatabaseHelper().getSettings();
      setState(() {
        _notifyClasses = (settings['notifyClasses'] ?? 1) == 1;
        _notifyAssignments = (settings['notifyAssignments'] ?? 1) == 1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSetting(String key, bool value) async {
    try {
      await DatabaseHelper().saveSettings();
      
      
      final db = await DatabaseHelper().database;
      await db.update('settings', {key: value ? 1 : 0}, where: 'id = 1');
    } catch (e) {
      debugPrint('Error saving notification setting: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Notification Preferences',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Control which alerts StudentPal sends you',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Class Reminders'),
                  subtitle: const Text('10 min and 1 min before a class starts'),
                  value: _notifyClasses,
                  onChanged: (value) async {
                    setState(() => _notifyClasses = value);
                    await _saveSetting('notifyClasses', value);
                    if (!value) {
                      
                      
                    }
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Assignment Deadlines'),
                  subtitle: const Text('3 days, 10 hrs, 3 hrs, and 1 hr before due'),
                  value: _notifyAssignments,
                  onChanged: (value) async {
                    setState(() => _notifyAssignments = value);
                    await _saveSetting('notifyAssignments', value);
                  },
                ),
                const Divider(height: 1),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('System Notification Settings'),
                  subtitle: const Text('Manage sound, banners, and badges'),
                  onTap: () async {
                    if (Platform.isAndroid) {
                      const intent = AndroidIntent(
                        action: 'android.settings.APP_NOTIFICATION_SETTINGS',
                        arguments: <String, dynamic>{
                          'android.provider.extra.APP_PACKAGE': 'com.example.mobile_app',
                        },
                      );
                      await intent.launch();
                    } else if (Platform.isIOS) {
                      await launchUrl(Uri.parse('app-settings:'));
                    }
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
    );
  }
}
