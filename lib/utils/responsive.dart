import 'package:flutter/material.dart';

double res(BuildContext context, double value) => value;

Future<T?> showCenteredModal<T>({
  required BuildContext context,
  required Widget child,
}) {
  return showDialog<T>(
    context: context,
    barrierColor: Colors.black54,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
          horizontal: 20, vertical: 24),
      constraints: BoxConstraints(
        minWidth: 280,
        maxHeight: MediaQuery.of(ctx).size.height * 0.85,
      ),
      child: child,
    ),
  );
}