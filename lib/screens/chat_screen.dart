import 'package:flutter/material.dart';
import 'package:mobile_app/services/ai_service.dart';
import 'package:mobile_app/providers/theme_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/utils/responsive.dart';
import 'package:mobile_app/helper/db_helper.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final int userId;
  const ChatScreen({super.key, required this.userId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AIService _aiService = AIService();
  bool _isLoading = false;
  final List<Map<String, String>> _messages = [];

  final String _defaultWelcome = "Hello! I'm your Student Pal. How can I help you with your studies today?";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _scrollToBottom(instant: true));
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    try {
      final history = await DatabaseHelper().getChatHistory(widget.userId);
      if (history.isEmpty) {
        setState(() {
          _messages.add({"role": "bot", "content": _defaultWelcome});
        });
        await DatabaseHelper().saveChatMessage(widget.userId, 'bot', _defaultWelcome);
      } else {
        setState(() {
          _messages.clear();
          _messages.addAll(history.map((msg) => {
                "role": msg['role'] as String,
                "content": msg['content'] as String,
              }));
        });
        // Replay history into AI session so the AI has context
        _aiService.restoreHistory(history.map((msg) => {
          'role': msg['role'] as String,
          'content': msg['content'] as String,
        }).toList());
      }
    } catch (_) {
      if (_messages.isEmpty) {
        setState(() {
          _messages.add({"role": "bot", "content": _defaultWelcome});
        });
      }
    }
    _scrollToBottom(instant: true);
  }

  void _scrollToBottom({bool instant = false}) {
    if (_scrollController.hasClients) {
      if (instant) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      } else {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  Future<void> _handleSendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "content": text});
      _isLoading = true;
      _controller.clear();
    });
    _scrollToBottom();

    try {
      await DatabaseHelper().saveChatMessage(widget.userId, 'user', text);
      final response = await _aiService.sendMessage(text);
      setState(() {
        _messages.add({"role": "bot", "content": response});
        _isLoading = false;
      });
      await DatabaseHelper().saveChatMessage(widget.userId, 'bot', response);
    } catch (e) {
      setState(() {
        _messages.add({
          "role": "bot",
          "content": "Sorry, I encountered an error. Please try again."
        });
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  Future<void> _clearChat() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear Chat', style: TextStyle(color: Colors.white)),
        content: const Text('Delete all chat messages? This cannot be undone.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('CLEAR', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper().clearChatHistory(widget.userId);
      setState(() {
        _messages.clear();
        _messages.add({"role": "bot", "content": _defaultWelcome});
      });
      await DatabaseHelper().saveChatMessage(widget.userId, 'bot', _defaultWelcome);
      _aiService.resetSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = ref.read(themeProvider).accentColor;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(res(context, 30))),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.1), width: 0.5),
      ),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(
                top: res(context, 15), bottom: res(context, 10)),
            width: res(context, 40),
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: res(context, 20), vertical: res(context, 10)),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(res(context, 8)),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.auto_awesome_rounded,
                      color: accentColor, size: res(context, 20)),
                ),
                SizedBox(width: res(context, 15)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("STUDENT PAL",
                          style: TextStyle(
                              fontSize: res(context, 14),
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              color: Colors.white)),
                      Text("Always here to help",
                          style: TextStyle(
                              fontSize: res(context, 11),
                              color: Colors.white38)),
                    ],
                  ),
                ),
                IconButton(
                    onPressed: _clearChat,
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Colors.white38, size: 22)),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: Colors.white38, size: 28)),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(res(context, 20)),
              itemCount:
                  _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _buildLoadingBubble(accentColor);
                }

                final msg = _messages[index];
                final isUser = msg["role"] == "user";

                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.only(bottom: res(context, 15)),
                    padding: EdgeInsets.symmetric(
                        horizontal: res(context, 18),
                        vertical: res(context, 12)),
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isUser
                          ? accentColor
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20).copyWith(
                        bottomRight: isUser
                            ? const Radius.circular(0)
                            : const Radius.circular(20),
                        bottomLeft: isUser
                            ? const Radius.circular(20)
                            : const Radius.circular(0),
                      ),
                    ),
                    child: Text(
                      msg["content"]!,
                      style: TextStyle(
                        color: isUser ? Colors.black : Colors.white,
                        fontWeight:
                            isUser ? FontWeight.bold : FontWeight.normal,
                        fontSize: res(context, 14),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              bottom:
                  MediaQuery.of(context).viewInsets.bottom + res(context, 20),
              left: res(context, 20),
              right: res(context, 20),
              top: res(context, 10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: res(context, 20)),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.white),
                      onSubmitted: (_) => _handleSendMessage(),
                      decoration: const InputDecoration(
                        hintText: "Type a message...",
                        hintStyle: TextStyle(color: Colors.white24),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: res(context, 10)),
                GestureDetector(
                  onTap: _isLoading ? null : _handleSendMessage,
                  child: CircleAvatar(
                    backgroundColor: _isLoading ? accentColor.withValues(alpha: 0.4) : accentColor,
                    radius: res(context, 24),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.black, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingBubble(Color accent) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.all(res(context, 12)),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(15),
        ),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: accent),
        ),
      ),
    );
  }
}
