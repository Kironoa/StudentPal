import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/glass_modal.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/screens/login_screen.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobile_app/services/alert_service.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  bool isPressed = false;
  final AuthService _authService = AuthService();
  final TextEditingController _userController = TextEditingController();

  Widget buildGlassIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Icon(icon, color: color, size: 25),
    );
  }

  void handleAnswerSecretQuestion() async {
    final username = _userController.text.trim();
    if (username.isEmpty) {
      showError("Please enter your username.");
      return;
    }

    try {
      final question = await _authService.getSecretQuestion(username);
      if (question == null) {
        showError("Username not found.");
        return;
      }

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SecretQuestionScreen(username: username, question: question),
        ),
      );
    } catch (e) {
      debugPrint("Error: $e");
      showError("An error occurred.");
    }
  }

  void handleScanQr() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QrScanScreen()),
    );
  }

  void showError(String message) {
    final theme = Theme.of(context);
    GlassModal.show(
      context,
      title: "Error",
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildGlassIcon(Icons.close_rounded, theme.colorScheme.error),
          const SizedBox(height: 20),
          Text(message, style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
        ],
      ),
    );
  }

  BoxDecoration buildOuterDecoration(ThemeData theme) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      gradient: LinearGradient(
        colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: theme.colorScheme.primary.withValues(alpha: isPressed ? 0.5 : 0.2),
          blurRadius: isPressed ? 35 : 20,
          spreadRadius: 1,
        ),
      ],
    );
  }

  Widget buildField(IconData icon, String hint, {TextEditingController? controller}) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), offset: const Offset(2, 5), blurRadius: 10),
        ],
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.8)),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: theme.colorScheme.onSurface, size: 18),
          hintText: hint,
          hintStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.24)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _userController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Forgot Password", style: TextStyle(color: theme.colorScheme.onSurface)),
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
                  width: MediaQuery.of(context).size.width * 0.88,
                  padding: const EdgeInsets.all(2),
                  decoration: buildOuterDecoration(theme),
                  child: Container(
                    decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Recover Password", style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 25),
                        buildField(Icons.person, "Username", controller: _userController),
                        const SizedBox(height: 30),
                        buildButton("Answer Secret Question", onPressed: handleAnswerSecretQuestion),
                        const SizedBox(height: 10),
                        buildButton("Scan QR Code", onPressed: handleScanQr),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildButton(String text, {required VoidCallback onPressed}) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(color: theme.cardColor.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(5)),
      child: TextButton(
        onPressed: onPressed,
        child: Text(text, style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class SecretQuestionScreen extends ConsumerStatefulWidget {
  final String username;
  final String question;

  const SecretQuestionScreen({super.key, required this.username, required this.question});

  @override
  ConsumerState<SecretQuestionScreen> createState() => _SecretQuestionScreenState();
}

class _SecretQuestionScreenState extends ConsumerState<SecretQuestionScreen> {
  bool showAnswer = false;
  final AuthService _authService = AuthService();
  final TextEditingController _answerController = TextEditingController();

  void handleSubmit() async {
    final answer = _answerController.text.trim();
    if (answer.isEmpty) {
      showError("Please enter your answer.");
      return;
    }

    try {
      final isValid = await _authService.verifySecretAnswer(widget.username, answer);
      if (!isValid) {
        showError("Incorrect answer.");
        return;
      }

      final user = await _authService.getUserByUsername(widget.username);
      if (user == null) {
        showError("User not found.");
        return;
      }

      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ResetPasswordScreen(userId: user.id)));
    } catch (e) {
      debugPrint("Error: $e");
      showError("An error occurred.");
    }
  }

  void showError(String message) {
    final theme = Theme.of(context);
    GlassModal.show(
      context,
      title: "Error",
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: theme.colorScheme.error.withValues(alpha: 0.1), shape: BoxShape.circle)),
        const SizedBox(height: 20),
        Text(message, style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
      ]),
    );
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: Text("Secret Question", style: TextStyle(color: theme.colorScheme.onSurface))),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.88,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.secondary])),
              child: Container(
                decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text("Answer Question", style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Text(widget.question, textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.primary, fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), offset: const Offset(2, 5), blurRadius: 10)],
                    ),
                    child: TextField(
                      controller: _answerController,
                      obscureText: false,
                      style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.8)),
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.question_answer, color: theme.colorScheme.onSurface, size: 18),
                        hintText: 'Type your answer here',
                        hintStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.24)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(width: double.infinity, child: TextButton(onPressed: handleSubmit, child: const Text("SUBMIT"))),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class QrScanScreen extends ConsumerStatefulWidget {
  const QrScanScreen({super.key});

  @override
  ConsumerState<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends ConsumerState<QrScanScreen> {
  final AuthService _authService = AuthService();
  bool hasScanned = false;

  void handleDetect(BarcodeCapture capture) async {
    if (hasScanned) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;
    setState(() => hasScanned = true);

    try {
      final userMap = await _authService.verifyRecoveryToken(rawValue);
      if (userMap == null) {
        if (!mounted) return;
        AlertService().showError(context, "Invalid or unrecognised QR code.");
        setState(() => hasScanned = false);
        return;
      }
      final userId = userMap['id'] as int;
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ResetPasswordScreen(userId: userId)));
    } catch (e) {
      debugPrint("Error: $e");
      if (!mounted) return;
      AlertService().showError(context, "Error scanning QR code.");
      setState(() => hasScanned = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: Text("Scan QR Code", style: TextStyle(color: theme.colorScheme.onSurface))),
      body: Stack(children: [
        MobileScanner(onDetect: handleDetect),
        Center(child: Container(width: 250, height: 250, decoration: BoxDecoration(color: Colors.transparent, border: Border.all(color: theme.colorScheme.primary, width: 3), borderRadius: BorderRadius.circular(20)))),
      ]),
    );
  }
}

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final int userId;

  const ResetPasswordScreen({super.key, required this.userId});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  bool showPassword = false;
  bool showConfirmPassword = false;
  final AuthService _authService = AuthService();
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  void handleSave() async {
    final newPassword = _newPassController.text.trim();
    final confirmPassword = _confirmPassController.text.trim();

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      showError("Fields cannot be empty.");
      return;
    }
    if (newPassword.length < 6) {
      showError("Password must be at least 6 characters.");
      return;
    }
    if (newPassword != confirmPassword) {
      showError("Passwords do not match.");
      return;
    }

    try {
      await _authService.updatePassword(widget.userId, newPassword);
      if (!mounted) return;
      showSuccess();
    } catch (e) {
      debugPrint("Error: $e");
      showError("An error occurred.");
    }
  }

  void showSuccess() {
    final theme = Theme.of(context);
    GlassModal.show(
      context,
      title: "Success",
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle)),
        const SizedBox(height: 20),
        Text("Password updated!", style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
      ]),
      onNavigate: () {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const StudentPalLogin()), (route) => false);
      },
    );
  }

  void showError(String message) {
    final theme = Theme.of(context);
    GlassModal.show(
      context,
      title: "Error",
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: theme.colorScheme.error.withValues(alpha: 0.1), shape: BoxShape.circle)),
        const SizedBox(height: 20),
        Text(message, style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
      ]),
    );
  }

  @override
  void dispose() {
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: Text("Reset Password", style: TextStyle(color: theme.colorScheme.onSurface))),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.88,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.secondary])),
              child: Container(
                decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text("New Password", style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 25),
                  Container(
                    decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(25)),
                    child: TextField(
                      controller: _newPassController,
                      obscureText: !showPassword,
                      style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.8)),
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.lock, color: theme.colorScheme.onSurface),
                        hintText: "New Password",
                        border: InputBorder.none,
                        suffixIcon: IconButton(icon: Icon(showPassword ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => showPassword = !showPassword)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(25)),
                    child: TextField(
                      controller: _confirmPassController,
                      obscureText: !showConfirmPassword,
                      style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.8)),
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.lock_reset, color: theme.colorScheme.onSurface),
                        hintText: "Confirm New Password",
                        border: InputBorder.none,
                        suffixIcon: IconButton(icon: Icon(showConfirmPassword ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => showConfirmPassword = !showConfirmPassword)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(width: double.infinity, child: TextButton(onPressed: handleSave, child: const Text("SAVE"))),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}