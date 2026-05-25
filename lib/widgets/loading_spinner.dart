import 'package:flutter/material.dart';

class LoadingSpinner extends StatefulWidget {
  final double size;

  const LoadingSpinner({super.key, this.size = 100.0});

  @override
  State<LoadingSpinner> createState() => _LoadingSpinnerState();
}

class _LoadingSpinnerState extends State<LoadingSpinner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _move1;
  late Animation<Offset> _move2;
  late Animation<Offset> _move3;
  late Animation<Offset> _move4;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat();

    // Custom cubic-bezier curve matches CSS: cubic-bezier(.6, .01, .4, 1)
    const curve = Cubic(0.6, 0.01, 0.4, 1.0);

    // Item 1 Animation Sequence (Top-Left)
    _move1 = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween<Offset>(begin: const Offset(0, 0), end: const Offset(0, 1))
            .chain(CurveTween(curve: curve)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(begin: const Offset(0, 1), end: const Offset(1, 1))
            .chain(CurveTween(curve: curve)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(begin: const Offset(1, 1), end: const Offset(1, 0))
            .chain(CurveTween(curve: curve)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(begin: const Offset(1, 0), end: const Offset(0, 0))
            .chain(CurveTween(curve: curve)),
        weight: 25,
      ),
    ]).animate(_controller);

    // Item 2 Animation Sequence (Top-Right)
    _move2 = TweenSequence<Offset>([
      TweenSequenceItem(
        tween:
            Tween<Offset>(begin: const Offset(0, 0), end: const Offset(-1, 0))
                .chain(CurveTween(curve: curve)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween:
            Tween<Offset>(begin: const Offset(-1, 0), end: const Offset(-1, 1))
                .chain(CurveTween(curve: curve)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween:
            Tween<Offset>(begin: const Offset(-1, 1), end: const Offset(0, 1))
                .chain(CurveTween(curve: curve)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(begin: const Offset(0, 1), end: const Offset(0, 0))
            .chain(CurveTween(curve: curve)),
        weight: 25,
      ),
    ]).animate(_controller);

    // Item 3 Animation Sequence (Bottom-Right)
    _move3 = TweenSequence<Offset>([
      TweenSequenceItem(
        tween:
            Tween<Offset>(begin: const Offset(0, 0), end: const Offset(0, -1))
                .chain(CurveTween(curve: curve)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween:
            Tween<Offset>(begin: const Offset(0, -1), end: const Offset(-1, -1))
                .chain(CurveTween(curve: curve)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween:
            Tween<Offset>(begin: const Offset(-1, -1), end: const Offset(-1, 0))
                .chain(CurveTween(curve: curve)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween:
            Tween<Offset>(begin: const Offset(-1, 0), end: const Offset(0, 0))
                .chain(CurveTween(curve: curve)),
        weight: 25,
      ),
    ]).animate(_controller);

    // Item 4 Animation Sequence (Bottom-Left)
    _move4 = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween<Offset>(begin: const Offset(0, 0), end: const Offset(1, 0))
            .chain(CurveTween(curve: curve)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween:
            Tween<Offset>(begin: const Offset(1, 0), end: const Offset(1, -1))
                .chain(CurveTween(curve: curve)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween:
            Tween<Offset>(begin: const Offset(1, -1), end: const Offset(0, -1))
                .chain(CurveTween(curve: curve)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween:
            Tween<Offset>(begin: const Offset(0, -1), end: const Offset(0, 0))
                .chain(CurveTween(curve: curve)),
        weight: 25,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final boxSize = widget.size / 2;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        children: [
          // Item 1: Salmon Red (Top-Left Origin)
          Positioned(
            top: 0,
            left: 0,
            child: AnimatedBuilder(
              animation: _move1,
              builder: (context, child) {
                return Transform.translate(
                  offset: _move1.value * boxSize,
                  child: child,
                );
              },
              child: Container(
                width: boxSize,
                height: boxSize,
                color: const Color(0xFFFA5767),
              ),
            ),
          ),
          // Item 2: Purple (Top-Right Origin)
          Positioned(
            top: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _move2,
              builder: (context, child) {
                return Transform.translate(
                  offset: _move2.value * boxSize,
                  child: child,
                );
              },
              child: Container(
                width: boxSize,
                height: boxSize,
                color: const Color(0xFF7944E4),
              ),
            ),
          ),
          // Item 3: Blue (Bottom-Right Origin)
          Positioned(
            bottom: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _move3,
              builder: (context, child) {
                return Transform.translate(
                  offset: _move3.value * boxSize,
                  child: child,
                );
              },
              child: Container(
                width: boxSize,
                height: boxSize,
                color: const Color(0xFF1B91F7),
              ),
            ),
          ),
          // Item 4: Amber Gold (Bottom-Left Origin)
          Positioned(
            bottom: 0,
            left: 0,
            child: AnimatedBuilder(
              animation: _move4,
              builder: (context, child) {
                return Transform.translate(
                  offset: _move4.value * boxSize,
                  child: child,
                );
              },
              child: Container(
                width: boxSize,
                height: boxSize,
                color: const Color(0xFFFAC24C),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
