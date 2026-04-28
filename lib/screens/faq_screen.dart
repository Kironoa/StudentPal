import 'package:flutter/material.dart';
import 'package:mobile_app/widgets/app_back_button.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  final List<Map<String, String>> _faqItems = const [
    {
      'question': 'How do I add a class to my schedule?',
      'answer': 'Go to the Schedule tab, tap the + button in the bottom right, fill in the subject name, '
          'days, start/end times, room, and professor, then tap Save.'
    },
    {
      'question': 'How do I set a deadline for an assignment?',
      'answer': 'When creating or editing an assignment, tap the calendar icon next to "Deadline" to open '
          'the date picker. You will automatically receive reminders 3 days, 10 hours, 3 hours, '
          'and 1 hour before the deadline.'
    },
    {
      'question': 'Why am I not receiving notifications?',
      'answer': 'Make sure you allowed notifications when you first opened the app. If not, go to your '
          'phone\'s Settings, find StudentPal, and turn on Notifications. On Android, also make sure '
          'the app is not being blocked by battery saver.'
    },
    {
      'question': 'What does the AI chat do?',
      'answer': 'The AI chat is powered by Google Gemini. You can ask it to explain topics, summarize '
          'your notes, generate practice questions, or help with any study-related question. '
          'An internet connection is required.'
    },
    {
      'question': 'How do I recover my password?',
      'answer': 'On the login screen, tap "Forgot Password". You will need either your secret question '
          'answer or the QR code you received during registration. Scan the QR code or answer the '
          'question to reset your password.'
    },
    {
      'question': 'Is my data backed up to the cloud?',
      'answer': 'No. Everything you save (notes, schedules, assignments) is only stored on your phone. '
          'If you delete the app, your data will be gone too. Write down important things before uninstalling!'
    },
    {
      'question': 'How do flashcards work?',
      'answer': 'Go to the Resources tab and open any study material. Tap Flashcards and the app will '
          'automatically make flashcards for you using AI. Tap a card to flip it and see the answer.'
    },
    {
      'question': 'Can I change the app\'s appearance?',
      'answer': 'Yes. Go to Settings > Appearance to switch between dark and light mode, choose an '
          'accent color, and adjust the interface scale between 80% and 120%.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('FAQ'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _faqItems.length,
        itemBuilder: (context, index) {
          final item = _faqItems[index];
          return ExpansionTile(
            title: Text(
              item['question']!,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(item['answer']!),
              ),
            ],
          );
        },
      ),
    );
  }
}
