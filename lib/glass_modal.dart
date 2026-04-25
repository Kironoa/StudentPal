import 'dart:ui';
import 'package:flutter/material.dart';

class GlassModal {
  static void show(
    BuildContext context, {
    required String title,
    required Widget content,
    VoidCallback? onNavigate,
    VoidCallback? onConfirm,
    String? confirmText,
    bool showConfirm = false,
    bool barrierDismissible = false,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'GlassModal',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
            ),
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 20),
                            content,
                            const SizedBox(height: 10),
                            if (showConfirm && confirmText != null) ...[
                              TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF00FF75),
                                ),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  if (onConfirm != null) {
                                    Future.delayed(
                                      const Duration(milliseconds: 100),
                                      () {
                                        onConfirm();
                                      },
                                    );
                                  }
                                },
                                child: Text(
                                  confirmText.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),
                            ],
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF00FF75),
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                                if (onNavigate != null) {
                                  Future.delayed(
                                    const Duration(milliseconds: 100),
                                    () {
                                      onNavigate();
                                    },
                                  );
                                }
                              },
                              child: Text(
                                showConfirm ? "CLOSE" : "CLOSE",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
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
      },
    );
  }
}
