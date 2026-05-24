import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/glass_modal.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/providers/theme_provider.dart';
import 'package:mobile_app/screens/login_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  bool isPressed = false;
  bool isStep2 = false;
  final AuthService _authService = AuthService();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();
  String? selectedQuestion;
  String recoveryToken = '';

  static const List<String> secretQuestions = [
    "What is your mother's maiden name?",
    "What was the name of your first pet?",
    "What city were you born in?",
    "What is your favorite childhood book?",
    "What was your first school's name?",
  ];

  double res(BuildContext context, double value) {
    return value * ref.read(themeProvider).uiScale;
  }

  Widget buildGlassIcon(IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(res(context, 12)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 25),
    );
  }

  void _handleSignUp() async {
    final username = _userController.text.trim();
    final password = _passController.text.trim();
    final confirmPass = _confirmPassController.text.trim();

    if (username.isEmpty || password.isEmpty || confirmPass.isEmpty) {
      _showModal("Error", "Fields cannot be empty.", isError: true);
      return;
    }

    if (password != confirmPass) {
      _showModal("Error", "Passwords do not match!", isError: true);
      return;
    }

    if (password.length < 6) {
      _showModal("Error", "Password must be at least 6 characters.",
          isError: true);
      return;
    }

    try {
      if (await _authService.usernameExists(username)) {
        _showModal("Error", "Username taken.", isError: true);
        return;
      }

      setState(() => isStep2 = true);
    } catch (e) {
      _showModal("Error", "Registration failed.", isError: true);
    }
  }

  void _handleStep2Confirm() async {
    final username = _userController.text.trim();
    final password = _passController.text.trim();
    final answer = _answerController.text.trim();
    final question = selectedQuestion;

    if (question == null || answer.isEmpty) {
      _showModal("Error", "Please select a question and provide an answer.",
          isError: true);
      return;
    }

    if (answer.length < 2) {
      _showModal("Error", "Answer must be at least 2 characters.",
          isError: true);
      return;
    }

    try {
      final result = await _authService.registerWithRecoveryToken(
        username,
        password,
        question,
        answer,
      );

      final user = result['user'];
      recoveryToken = result['recoveryToken'];

      if (!mounted) return;

      _showRecoveryQrCode(user!);
    } catch (e) {
      debugPrint("Registration error: $e");
      _showModal("Error", "Registration failed.", isError: true);
    }
  }

  void _showRecoveryQrCode(dynamic user) {
    final theme = Theme.of(context);
    GlassModal.show(
      context,
      title: "Your Recovery QR Code",
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildGlassIcon(Icons.qr_code_2_rounded, theme.colorScheme.primary),
          SizedBox(height: res(context, 20)),
          Text(
            "Save or screenshot this QR code. You can scan it anytime to reset your password. Do not share it.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: res(context, 12),
            ),
          ),
          SizedBox(height: res(context, 20)),
          Container(
            padding: EdgeInsets.all(res(context, 10)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(res(context, 10)),
            ),
            child: QrImageView(
              data: recoveryToken,
              version: QrVersions.auto,
              size: res(context, 200),
              eyeStyle: QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: theme.colorScheme.primary,
              ),
              dataModuleStyle: QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
      onNavigate: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const StudentPalLogin()),
        );
      },
      confirmText: "After saving it, just press close",
      showConfirm: true,
    );
  }

  void _showModal(String title, String msg, {bool isError = false}) {
    final theme = Theme.of(context);
    GlassModal.show(
      context,
      title: title,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildGlassIcon(
            isError ? Icons.close_rounded : Icons.info_outline,
            isError ? theme.colorScheme.error : theme.colorScheme.primary,
          ),
          SizedBox(height: res(context, 20)),
          Text(msg,
              style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: GestureDetector(
              onTapDown: (_) => setState(() => isPressed = true),
              onTapUp: (_) => setState(() => isPressed = false),
              onTapCancel: () => setState(() => isPressed = false),
              child: AnimatedScale(
                scale: isPressed ? 0.96 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: screenWidth * 0.88,
                  padding: EdgeInsets.all(res(context, 2)),
                  decoration: _buildOuterDecoration(theme),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: isStep2
                        ? _buildStep2Card(theme, screenWidth)
                        : _buildStep1Card(theme),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1Card(ThemeData theme) {
    return Container(
      key: const ValueKey('step1'),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(res(context, 20)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: res(context, 25.0),
          vertical: res(context, 30),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Register",
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: res(context, 22),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: res(context, 25)),
            _buildField(
              context,
              Icons.person,
              "Username",
              controller: _userController,
            ),
            SizedBox(height: res(context, 10)),
            _buildField(
              context,
              Icons.lock,
              "Password",
              isPassword: true,
              controller: _passController,
            ),
            SizedBox(height: res(context, 10)),
            _buildField(
              context,
              Icons.lock_reset,
              "Confirm",
              isPassword: true,
              controller: _confirmPassController,
            ),
            SizedBox(height: res(context, 30)),
            _buildButton(context, "Register"),
            SizedBox(height: res(context, 15)),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Text(
                "Back to Login",
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.38),
                  fontSize: res(context, 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2Card(ThemeData theme, double screenWidth) {
    return Container(
      key: const ValueKey('step2'),
      constraints: BoxConstraints(
        maxHeight: screenWidth * 1.5,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(res(context, 20)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: res(context, 25.0),
            vertical: res(context, 30),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Security Question",
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: res(context, 22),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: res(context, 10)),
              Text(
                "Set a secret question for password recovery",
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: res(context, 12),
                ),
              ),
              SizedBox(height: res(context, 25)),
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(res(context, 25)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      offset: Offset(res(context, 2), res(context, 5)),
                      blurRadius: res(context, 10),
                    ),
                  ],
                ),
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: selectedQuestion,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.help_outline,
                        color: theme.colorScheme.onSurface, size: 18),
                    hintText: "Select a question",
                    hintStyle: TextStyle(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.24),
                      fontSize: res(context, 14),
                    ),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(vertical: res(context, 15)),
                  ),
                  items: secretQuestions.map((q) {
                    return DropdownMenuItem(
                      value: q,
                      child: Container(
                        width: double.infinity,
                        constraints: BoxConstraints(
                            maxWidth: screenWidth * 0.55),
                        child: Text(
                          q,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          softWrap: true,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.8),
                            fontSize: res(context, 13),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => selectedQuestion = v),
                ),
              ),
              SizedBox(height: res(context, 10)),
              _buildField(
                context,
                Icons.question_answer,
                "Your Answer",
                isPassword: false,
                controller: _answerController,
              ),
              SizedBox(height: res(context, 30)),
              _buildButton(context, "Confirm"),
              SizedBox(height: res(context, 15)),
              GestureDetector(
                onTap: () => setState(() => isStep2 = false),
                child: Text(
                  "Go Back",
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.38),
                    fontSize: res(context, 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildOuterDecoration(ThemeData theme) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(res(context, 22)),
      gradient: LinearGradient(
        colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: theme.colorScheme.primary
              .withValues(alpha: isPressed ? 0.5 : 0.2),
          blurRadius: isPressed ? res(context, 35) : res(context, 20),
          spreadRadius: 1,
        ),
      ],
    );
  }

  Widget _buildField(
    BuildContext context,
    IconData icon,
    String hint, {
    bool isPassword = false,
    TextEditingController? controller,
  }) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(res(context, 25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            offset: Offset(res(context, 2), res(context, 5)),
            blurRadius: res(context, 10),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8)),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: theme.colorScheme.onSurface, size: 18),
          hintText: hint,
          hintStyle: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.24),
              fontSize: res(context, 14)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: res(context, 15)),
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(res(context, 5)),
      ),
      child: TextButton(
        onPressed: isStep2 ? _handleStep2Confirm : _handleSignUp,
        child: Text(
          text,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: res(context, 14),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
