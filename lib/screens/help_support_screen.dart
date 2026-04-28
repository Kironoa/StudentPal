import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'faq_screen.dart';
import 'package:mobile_app/widgets/app_back_button.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  String _version = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _version = info.version);
    } catch (_) {
      if (mounted) setState(() => _version = 'Unknown');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Help & Support'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCard(
            icon: Icons.email_outlined,
            title: 'Send Feedback',
            body: 'Found something you don\'t like or have an idea to make the app better? Send us a message!',
            onTap: () => launchUrl(Uri.parse('mailto:kirigayaroro@gmail.com')),
          ),
          const SizedBox(height: 12),
          _buildCard(
            icon: Icons.bug_report_outlined,
            title: 'Report a Bug',
            body:
                'Something not working right? Let us know what happened and we\'ll try to fix it. A screenshot helps a lot!',
            onTap: () => launchUrl(
              Uri.parse(
                  'mailto:kirigayaroro@gmail.com?subject=Bug Report — StudentPal'),
            ),
          ),
          const SizedBox(height: 12),
          _buildCard(
            icon: Icons.menu_book_outlined,
            title: 'User Guide',
            body:
                'New to StudentPal? Tap here to see answers to the most common questions students ask.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FaqScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('App Version',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('Version $_version',
                        style: TextStyle(color: Theme.of(context).hintColor)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required String body,
    VoidCallback? onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(body),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
