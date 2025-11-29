import '../core/app_export.dart';

/// Modern loading indicator with pulsing arrows animation.
/// Matches the logo style for visual coherence.
class LoadingIndicatorWidget extends StatefulWidget {
  final double size;
  final String? message;

  const LoadingIndicatorWidget({super.key, this.size = 48, this.message});

  @override
  State<LoadingIndicatorWidget> createState() => _LoadingIndicatorWidgetState();
}

class _LoadingIndicatorWidgetState extends State<LoadingIndicatorWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  late Animation<double> _leftSlide;
  late Animation<double> _rightSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _leftSlide = Tween<double>(
      begin: 0,
      end: -4,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _rightSlide = Tween<double>(
      begin: 0,
      end: 4,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final arrowSize = widget.size * 0.5;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.translate(
                    offset: Offset(_leftSlide.value, 0),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      size: arrowSize,
                      color: AppColors.primary.withOpacity(0.8),
                    ),
                  ),
                  SizedBox(width: widget.size * 0.1),
                  Transform.translate(
                    offset: Offset(_rightSlide.value, 0),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: arrowSize,
                      color: AppColors.primary.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        if (widget.message != null) ...[
          const SizedBox(height: 16),
          Text(
            widget.message!,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.neutralDark,
            ),
          ),
        ],
      ],
    );
  }
}
