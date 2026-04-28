import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/providers/theme_provider.dart';
import 'package:mobile_app/themes/app_themes.dart';
import 'package:mobile_app/widgets/about.dart';
import 'package:mobile_app/screens/notification_settings_sheet.dart';
import 'package:mobile_app/screens/faq_screen.dart';
import 'package:mobile_app/screens/help_support_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final theme = Theme.of(context);

    final primaryColor = themeState.accentColor;
    final double scale = themeState.uiScale;
    final bool isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "SETTINGS",
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w900,
            fontSize: scale * 12,
            letterSpacing: 1.5,
          ),
        ),
        leading: IconButton(
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.grid_view_rounded, color: primaryColor, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader("Look & Feel", primaryColor, context, scale),
                  ListTile(
                    leading: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                    title: const Text("Dark Mode"),
                    subtitle: Text(isDark ? "Using dark colors" : "Using light colors"),
                    trailing: Switch(
                      value: isDark,
                      activeThumbColor: primaryColor,
                      onChanged: (value) {
                        ref.read(themeProvider.notifier).setBrightness(
                            value ? Brightness.dark : Brightness.light);
                      },
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.palette_outlined),
                    title: const Text("App Color"),
                    subtitle: const Text("Pick your favorite color"),
                    trailing: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    onTap: () => _showThemeDialog(context, ref),
                  ),
                   Padding(
                     padding: EdgeInsets.symmetric(
                       horizontal: scale * 16.0,
                       vertical: scale * 8.0,
                     ),
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Row(
                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                           children: [
                             Text(
                               "Text & Button Size",
                               style: TextStyle(fontSize: scale * 16),
                             ),
                             Text(
                               "${(scale * 100).round()}%",
                               style: TextStyle(
                                 color: primaryColor,
                                 fontWeight: FontWeight.bold,
                               ),
                             ),
                           ],
                         ),
                         Slider(
                           value: scale,
                           min: 0.8,
                           max: 1.2,
                           divisions: 4,
                           label: "${(scale * 100).round()}%",
                           activeColor: primaryColor,
                           onChanged: (double value) {
                             ref.read(themeProvider.notifier).setScale(value);
                           },
                         ),
                         Text(
                           "Make everything bigger or smaller to fit your screen",
                           style: TextStyle(
                             fontSize: scale * 12,
                             color: Theme.of(context).hintColor,
                           ),
                         ),
                       ],
                     ),
                   ),
                  Divider(indent: scale * 16, endIndent: scale * 16),
                   _buildSectionHeader("Other Settings", primaryColor, context, scale),
                  _buildListTile(context, Icons.notifications_none, "Reminders", "Control when the app reminds you", () {
                     showModalBottomSheet(
                       context: context,
                       isScrollControlled: true,
                       backgroundColor: Colors.transparent,
                       builder: (_) => const NotificationSettingsSheet(),
                     );
                   }, scale),
                  _buildListTile(context, Icons.lock_outline, "Your Privacy", "", () {
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      builder: (_) => Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Container(
                                width: 40, height: 4,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).dividerColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text("Your Privacy",
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            const Text(
                              "Your info stays on your phone. We don't send your data to anyone. "
                              "Only chat messages go to Google Gemini to get answers.\n\n"
                              "Your password is kept safe with special protection. "
                              "Your security answer is only stored on your phone.\n\n"
                              "To delete everything, just uninstall the app.",
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    );
                  }, scale),
                  _buildListTile(context, Icons.help_outline, "Common Questions (FAQ)", "Find quick answers to common questions", () {
                     Navigator.push(context, MaterialPageRoute(builder: (_) => const FaqScreen()));
                   }, scale),
                  _buildListTile(context, Icons.support_agent_outlined, "Talk to Support", "Get help from our support team", () {
                     Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen()));
                   }, scale),
                  _buildListTile(
                    context,
                    Icons.info_outline,
                    "About",
                    "",
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ProviderScope(child: AboutScreen())),
                      );
                    },
                    scale,
                  ),
                  SizedBox(height: scale * 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color, BuildContext context, double scale) {
    return Padding(
      padding: EdgeInsets.fromLTRB(scale * 16.0, scale * 16.0, scale * 16.0, scale * 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  String _getAppearanceLabel(bool isDark) {
    return isDark ? "Dark mode on" : "Light mode on";
  }

  String _getBrightnessLabel(bool isDark) {
    return isDark ? "Switch to light mode" : "Switch to dark mode";
  }

  Widget _buildListTile(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap, double scale) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle, style: TextStyle(fontSize: scale * 12, color: Theme.of(context).hintColor)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: onTap,
    );
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    final themeEntries = AppThemes.colors.entries.toList();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Select Accent Color"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SizedBox(
          width: double.maxFinite,
          height: 320,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 15,
              crossAxisSpacing: 15,
              childAspectRatio: 0.8,
            ),
            itemCount: themeEntries.length,
            itemBuilder: (context, index) {
              final entry = themeEntries[index];
              final selected = ref.read(themeProvider).accentColor == entry.value;

              return GestureDetector(
                onTap: () {
                  ref.read(themeProvider.notifier).setColor(entry.value);
                  Navigator.pop(dialogContext);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      backgroundColor: entry.value,
                      radius: 25,
                      child: selected
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                    SizedBox(height: 4),
                    Text(
                      entry.key,
                      style: const TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("CLOSE"),
          ),
        ],
      ),
    );
  }
}