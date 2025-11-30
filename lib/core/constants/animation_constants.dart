import 'package:flutter/material.dart';

/// Constantes de animación para TruekApp
/// Centralizadas para mantener consistencia en toda la app
class AnimationConstants {
  // ═══════════════════════════════════════════════════════════
  // DURACIONES
  // ═══════════════════════════════════════════════════════════

  /// Animación muy rápida (microinteracciones)
  static const Duration durationFast = Duration(milliseconds: 150);

  /// Animación normal
  static const Duration durationNormal = Duration(milliseconds: 200);

  /// Animación media
  static const Duration durationMedium = Duration(milliseconds: 300);

  /// Animación lenta (entradas de pantalla)
  static const Duration durationSlow = Duration(milliseconds: 500);

  /// Animación muy lenta (efectos dramáticos)
  static const Duration durationVerySlow = Duration(milliseconds: 800);

  /// Animación de logo
  static const Duration durationLogo = Duration(milliseconds: 650);

  /// Animación de flotación
  static const Duration durationFloat = Duration(milliseconds: 3500);

  // ═══════════════════════════════════════════════════════════
  // DELAYS
  // ═══════════════════════════════════════════════════════════

  /// Sin delay
  static const Duration delayNone = Duration.zero;

  /// Delay mínimo
  static const Duration delayShort = Duration(milliseconds: 100);

  /// Delay medio
  static const Duration delayMedium = Duration(milliseconds: 200);

  /// Delay para secuencia
  static const Duration delaySequence = Duration(milliseconds: 150);

  /// Delay para ilustraciones flotantes
  static const Duration delayFloatOffset = Duration(milliseconds: 500);

  // ═══════════════════════════════════════════════════════════
  // CURVAS
  // ═══════════════════════════════════════════════════════════

  /// Curva suave de salida (para entradas)
  static const Curve curveEaseOut = Curves.easeOutCubic;

  /// Curva suave de entrada/salida
  static const Curve curveEaseInOut = Curves.easeInOutCubic;

  /// Curva con rebote sutil
  static const Curve curveEaseOutBack = Curves.easeOutBack;

  /// Curva para flotación
  static const Curve curveFloat = Curves.easeInOutSine;

  /// Curva elástica (para shake)
  static const Curve curveElastic = Curves.elasticOut;

  // ═══════════════════════════════════════════════════════════
  // VALORES DE ANIMACIÓN
  // ═══════════════════════════════════════════════════════════

  /// Offset inicial para slide-in desde abajo
  static const Offset slideFromBottom = Offset(0, 0.15);

  /// Offset inicial para slide-in desde arriba
  static const Offset slideFromTop = Offset(0, -0.15);

  /// Escala inicial para scale-in
  static const double scaleStart = 0.95;

  /// Escala final
  static const double scaleEnd = 1.0;

  /// Escala para hover/tap
  static const double scaleHover = 1.05;

  /// Escala para presionado
  static const double scalePressed = 0.98;

  /// Distancia de flotación (píxeles)
  static const double floatDistance = 12.0;

  /// Distancia de shake (píxeles)
  static const double shakeDistance = 5.0;

  // ═══════════════════════════════════════════════════════════
  // OPACIDADES DE ILUSTRACIONES
  // ═══════════════════════════════════════════════════════════

  static const double illustrationOpacity1 = 0.15;
  static const double illustrationOpacity2 = 0.12;
  static const double illustrationOpacity3 = 0.10;
  static const double illustrationOpacity4 = 0.13;
}
