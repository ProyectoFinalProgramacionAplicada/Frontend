import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Animated logo widget with a "Marvel intro" style entrance animation.
/// Displays a minimalistic SVG icon of two people exchanging.
/// Uses FadeTransition + SlideTransition + ScaleTransition for a smooth,
/// one-time entry animation. After the animation completes, the logo stays static.
class AnimatedLogoWidget extends StatefulWidget {
  final double size;
  final Duration introDuration;

  const AnimatedLogoWidget({
    super.key,
    this.size = 200,
    this.introDuration = const Duration(milliseconds: 650),
  });

  @override
  State<AnimatedLogoWidget> createState() => _AnimatedLogoWidgetState();
}

class _AnimatedLogoWidgetState extends State<AnimatedLogoWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _scaleAnimation;

  // TruekApp green color
  static const Color _truekGreen = Color(0xFF2F6B3F);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.introDuration,
    );

    // Fade: 0 → 1 with easeOut curve
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Slide: from +20px below (0.1 offset) → center
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    // Scale: 0.85 → 1.0 with easeOutBack for a subtle "pop"
    _scaleAnimation = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    // Start animation after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: SvgPicture.asset(
                'assets/icons/exchange_people.svg',
                width: widget.size,
                height: widget.size,
                colorFilter: const ColorFilter.mode(
                  _truekGreen,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
