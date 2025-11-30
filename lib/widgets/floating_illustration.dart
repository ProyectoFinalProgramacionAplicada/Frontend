import 'package:flutter/material.dart';
import '../core/constants/animation_constants.dart';

/// Widget que muestra una ilustración con animación de flotación suave
/// Usado para decorar las esquinas del login
class FloatingIllustration extends StatefulWidget {
  final IconData icon;
  final double size;
  final Color color;
  final double opacity;
  final Duration delay;
  final Alignment alignment;

  const FloatingIllustration({
    super.key,
    required this.icon,
    this.size = 100,
    required this.color,
    this.opacity = 0.12,
    this.delay = Duration.zero,
    this.alignment = Alignment.center,
  });

  @override
  State<FloatingIllustration> createState() => _FloatingIllustrationState();
}

class _FloatingIllustrationState extends State<FloatingIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AnimationConstants.durationFloat,
      vsync: this,
    );

    _floatAnimation =
        Tween<double>(
          begin: -AnimationConstants.floatDistance,
          end: AnimationConstants.floatDistance,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: AnimationConstants.curveFloat,
          ),
        );

    // Iniciar después del delay
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.repeat(reverse: true);
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
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: Opacity(
            opacity: widget.opacity,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(widget.size * 0.2),
              ),
              child: Icon(
                widget.icon,
                size: widget.size * 0.5,
                color: widget.color,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Widget compuesto que posiciona 4 ilustraciones flotantes en las esquinas
class FloatingIllustrationsBackground extends StatelessWidget {
  final Color primaryColor;

  const FloatingIllustrationsBackground({
    super.key,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Superior izquierda - Caja/Intercambio
          Positioned(
            top: 40,
            left: -30,
            child: FloatingIllustration(
              icon: Icons.inventory_2_outlined,
              size: 120,
              color: primaryColor,
              opacity: 0.15,
              delay: Duration.zero,
            ),
          ),

          // Superior derecha - Planta/Reciclaje
          Positioned(
            top: 60,
            right: -25,
            child: FloatingIllustration(
              icon: Icons.eco_outlined,
              size: 100,
              color: primaryColor,
              opacity: 0.12,
              delay: const Duration(milliseconds: 500),
            ),
          ),

          // Inferior izquierda - Manos/Trueque
          Positioned(
            bottom: 80,
            left: -35,
            child: FloatingIllustration(
              icon: Icons.handshake_outlined,
              size: 140,
              color: primaryColor,
              opacity: 0.10,
              delay: const Duration(milliseconds: 1000),
            ),
          ),

          // Inferior derecha - Ubicación
          Positioned(
            bottom: 100,
            right: -30,
            child: FloatingIllustration(
              icon: Icons.location_on_outlined,
              size: 110,
              color: primaryColor,
              opacity: 0.13,
              delay: const Duration(milliseconds: 1500),
            ),
          ),
        ],
      ),
    );
  }
}
