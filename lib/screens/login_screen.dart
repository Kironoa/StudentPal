import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/models/app_user.dart';
import 'package:mobile_app/screens/dashboard_screen.dart';
import 'package:mobile_app/screens/signup_screen.dart';
import 'package:mobile_app/screens/forgot_password_screen.dart';
import 'package:mobile_app/glass_modal.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/providers/theme_provider.dart';

class StudentPalLogin extends ConsumerStatefulWidget {
  const StudentPalLogin({super.key});

  @override
  ConsumerState<StudentPalLogin> createState() => _StudentPalLoginState();
}

class LowerCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toLowerCase());
  }
}

class _StudentPalLoginState extends ConsumerState<StudentPalLogin> {
  bool isPressed = false;
  final AuthService _authService = AuthService();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final _passwordFocusNode = FocusNode();

  double res(BuildContext context, double value) {
    return value * ref.read(themeProvider).uiScale;
  }

  Widget buildGlassIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
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

  void _handleLogin() async {
    FocusScope.of(context).unfocus();
    final username = _userController.text.trim().toLowerCase();
    final password = _passController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showErrorModal("Fields cannot be empty.");
      return;
    }

    try {
      final user = await _authService.login(username, password);

      if (user != null) {
        _showSuccessModal(user);
      } else {
        _showErrorModal("Invalid username or password.");
      }
    } catch (e) {
      debugPrint("Login Error: $e");
      _showErrorModal("Database error occurred.");
    }
  }

  void _showSuccessModal(AppUser user) {
    final theme = Theme.of(context);
    GlassModal.show(
      context,
      title: "Login Successful",
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildGlassIcon(Icons.check_rounded, theme.colorScheme.primary),
          SizedBox(height: res(context, 20)),
          Text(
            "Welcome, @${user.username} enjoy and study well.",
            textAlign: TextAlign.center,
            style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
          ),
        ],
      ),
      onNavigate: () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => StudentDashboard(userId: user.id),
              ),
            );
          }
        });
      },
    );
  }

  void _showErrorModal(String message) {
    final theme = Theme.of(context);
    GlassModal.show(
      context,
      title: "Error",
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildGlassIcon(Icons.close_rounded, theme.colorScheme.error),
          SizedBox(height: res(context, 20)),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/logo.png',
                  height: res(context, 80),
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.school_rounded,
                    color: theme.colorScheme.primary,
                    size: res(context, 80),
                  ),
                ),
                SizedBox(height: res(context, 10)),
                Text(
                  "STUDENT PAL",
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    letterSpacing: 4,
                    fontSize: res(context, 18),
                    fontWeight: FontWeight.w300,
                  ),
                ),
                SizedBox(height: res(context, 30)),
                GestureDetector(
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
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(res(context, 20)),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: res(context, 40.0),
                            vertical: res(context, 40.0),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Login",
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                  fontSize: res(context, 22),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: res(context, 25)),
                              _buildField(
                                 context,
                                 Icons.alternate_email,
                                 "Username",
                                 controller: _userController,
                                 formatters: [LowerCaseTextFormatter()],
                                 textInputAction: TextInputAction.next,
                                 onSubmitted: (_) {
                                   FocusScope.of(context).requestFocus(_passwordFocusNode);
                                 },
                               ),
                               SizedBox(height: res(context, 15)),
                               _buildField(
                                 context,
                                 Icons.lock,
                                 "Password",
                                 isPassword: true,
                                 controller: _passController,
                                 focusNode: _passwordFocusNode,
                                 textInputAction: TextInputAction.done,
                                 onSubmitted: (_) => _handleLogin(),
                               ),
                              SizedBox(height: res(context, 30)),
                              Row(
                                children: [
                                  Expanded(
                                      child: _buildButton(context, "Login")),
                                  SizedBox(width: res(context, 10)),
                                  Expanded(
                                      child: _buildButton(context, "Sign Up")),
                                ],
                              ),
                              SizedBox(height: res(context, 15)),
                              _buildButton(context, "Forgot Password",
                                  isFullWidth: true),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
    List<TextInputFormatter>? formatters,
    TextInputAction? textInputAction,
    FocusNode? focusNode,
    Function(String)? onSubmitted,
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
        inputFormatters: formatters,
        textInputAction: textInputAction,
        focusNode: focusNode,
        onSubmitted: onSubmitted,
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

  Widget _buildButton(BuildContext context, String text,
      {bool isFullWidth = false}) {
    final theme = Theme.of(context);
    return Container(
      width: isFullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(res(context, 8)),
      ),
      child: TextButton(
        onPressed: () {
          if (text == "Login") {
            _handleLogin();
          } else if (text == "Sign Up") {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SignUpScreen()),
            );
          } else if (text == "Forgot Password") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ForgotPasswordScreen(),
              ),
            );
          }
        },
        child: Text(
          text,
          style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: res(context, 13),
              fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
