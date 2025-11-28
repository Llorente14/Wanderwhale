import 'package:flutter/material.dart';

/// A small reusable widget that applies a gentle pulsing (scale) animation
/// to its child. The animation runs when [enabled] is true and is paused
/// when [enabled] is false (for example while a button is loading).
class Pulse extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final Duration duration;
  final double beginScale;
  final double endScale;

  const Pulse({
    Key? key,
    required this.child,
    this.enabled = true,
    this.duration = const Duration(milliseconds: 1000),
    this.beginScale = 1.0,
    this.endScale = 1.04,
  }) : super(key: key);

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(
      begin: widget.beginScale,
      end: widget.endScale,
    ).chain(CurveTween(curve: Curves.easeInOut)).animate(_controller);

    if (widget.enabled) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant Pulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.value = 0.0; // reset to base scale
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(scale: _animation.value, child: child);
      },
      child: widget.child,
    );
  }
}
