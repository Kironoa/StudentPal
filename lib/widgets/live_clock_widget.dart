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
    return GestureDetector(
      onTap: () => _showCalendarDialog(context),
      child: Container(
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
      ),
    );
  }

  void _showCalendarDialog(BuildContext context) {
    final now = DateTime.now();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.accent.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8, horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('MMMM yyyy').format(now).toUpperCase(),
                      style: TextStyle(
                        color: widget.accent,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 1.2,
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.close_rounded,
                        color: Theme.of(context)
                          .colorScheme.onSurface
                          .withValues(alpha: 0.5),
                        size: 18),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              CalendarWidget(
                accent: widget.accent,
                today: now,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CalendarWidget extends StatefulWidget {
  final Color accent;
  final DateTime today;
  const CalendarWidget(
    {super.key, required this.accent, required this.today});

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  late DateTime _displayed;

  @override
  void initState() {
    super.initState();
    _displayed = DateTime(widget.today.year, widget.today.month);
  }

  void _prev() => setState(() =>
    _displayed = DateTime(_displayed.year, _displayed.month - 1));

  void _next() => setState(() =>
    _displayed = DateTime(_displayed.year, _displayed.month + 1));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final daysInMonth = DateUtils.getDaysInMonth(
      _displayed.year, _displayed.month);
    final firstWeekday = DateTime(
      _displayed.year, _displayed.month, 1).weekday % 7;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: _prev,
              icon: Icon(Icons.chevron_left_rounded,
                color: onSurface.withValues(alpha: 0.6))),
            Text(
              DateFormat('MMMM yyyy').format(_displayed),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: onSurface),
            ),
            IconButton(
              onPressed: _next,
              icon: Icon(Icons.chevron_right_rounded,
                color: onSurface.withValues(alpha: 0.6))),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['S','M','T','W','T','F','S'].map((d) =>
            SizedBox(
              width: 32,
              child: Text(d,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: onSurface.withValues(alpha: 0.4))),
            )
          ).toList(),
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
            childAspectRatio: 1,
          ),
          itemCount: firstWeekday + daysInMonth,
          itemBuilder: (ctx, i) {
            if (i < firstWeekday) return const SizedBox();
            final day = i - firstWeekday + 1;
            final isToday = day == widget.today.day &&
              _displayed.month == widget.today.month &&
              _displayed.year == widget.today.year;
            return Container(
              decoration: BoxDecoration(
                color: isToday
                  ? widget.accent
                  : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isToday
                      ? FontWeight.w900 : FontWeight.normal,
                    color: isToday
                      ? Colors.white
                      : onSurface.withValues(alpha: 0.8)),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}