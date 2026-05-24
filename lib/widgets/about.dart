import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/providers/theme_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  Future<void> _launchFB() async {
    final Uri fbUrl = Uri.parse("https://fb.com/Sinharoro");
    if (!await launchUrl(fbUrl, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $fbUrl');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final accent = theme.accentColor;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "ABOUT STUDENT PAL",
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 1.5,
          ),
        ),
        leading: IconButton(
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.grid_view_rounded, color: accent, size: 22),
          onPressed: () {
            int count = 0;
            Navigator.popUntil(context, (route) {
              return count++ == 2;
            });
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [accent, accent.withValues(alpha: 0.5)],
                  ),
                ),
                child: const Icon(Icons.school, size: 80, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              "Student Pal",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: accent,
              ),
            ),
            const SizedBox(height: 30),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: accent.withValues(alpha: 0.3)),
              ),
              child: const Column(
                children: [
                  Text(
                    "Developed by Kironoa",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "A comprehensive management tool for students. Designed to sync resources, manage schedules, and boost academic productivity.",
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTechIcon(Icons.bolt, "Flutter"),
                _buildTechIcon(Icons.storage, "Local Storage"),
                _buildTechIcon(Icons.palette, "Simple Design"),
              ],
            ),
            const SizedBox(height: 60),

            
            const Text(
              "Have feedback or a feature request? Let me know!",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Text(
                "I can't promise to add every request, but I'd love to hear your thoughts.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _launchFB,
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                elevation: 2,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FaIcon(FontAwesomeIcons.facebook, size: 18),
                  SizedBox(width: 12),
                  Text(
                    "fb.com/Sinharoro",
                    style: TextStyle(letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTechIcon(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, size: 30),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
