import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'faq_screen.dart';
import 'package:mobile_app/widgets/app_back_button.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    setState(() {});
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
            body: 'Have a bug to report or a feature request? Reach out at '
                'kirigayaroro@gmail.com or visit our GitHub issues page.',
            onTap: () => launchUrl(Uri.parse('mailto:kirigayaroro@gmail.com')),
          ),
          const SizedBox(height: 12),
          _buildCard(
            icon: Icons.bug_report_outlined,
            title: 'Report a Bug',
            body:
                'Encountered something broken? Describe what happened, what you expected, and your '
                'device model. Screenshots help a lot.',
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
                'New to StudentPal? Check the FAQ section for step-by-step answers to the most '
                'common questions.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FaqScreen()),
              );
            },
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
