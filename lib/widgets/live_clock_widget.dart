import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LiveClockWidget extends StatefulWidget {
  final double Function(double) r;
  final Color accent;

  const LiveClockWidget({super.key, required this.r, required this.accent});

  @override
  State<LiveClockWidget> createState() => _LiveClockWidgetState();
}

class _LiveClockWidgetState extends State<LiveClockWidget> {
  late Timer _clockTimer;
  String _timeString = DateFormat('hh:mm:ss a').format(DateTime.now());
  String _dateString = DateFormat('EEE, MMM dd, yyyy').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _timeString = DateFormat('hh:mm:ss a').format(DateTime.now());
          _dateString = DateFormat('EEE, MMM dd, yyyy').format(DateTime.now());
        });
      }
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: onSurface.withValues(alpha: 0.1)),
      ),
      padding:
          EdgeInsets.symmetric(horizontal: widget.r(10), vertical: widget.r(6)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_timeString.split(' ')[0],
                  style: TextStyle(
                      color: onSurface,
                      fontSize: widget.r(11),
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace')),
              SizedBox(width: widget.r(3)),
              Text(_timeString.split(' ')[1],
                  style: TextStyle(
                      color: widget.accent,
                      fontSize: widget.r(8),
                      fontWeight: FontWeight.w900)),
            ],
          ),
          Text(_dateString.toUpperCase(),
              style: TextStyle(
                  color: onSurface.withValues(alpha: 0.6),
                  fontSize: widget.r(7),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5)),
        ],
      ),
    );
  }
}