// lib/screens/admin/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../dto/auth/app_role.dart';
import '../../dto/admin/admin_metrics_dto.dart';
import '../../core/constants/app_colors.dart';
import '../../routes.dart';

/// Dashboard de administración rediseñado
/// Inspirado en: https://dribbble.com/shots/26154663-Login-Screen-for-Solar-Energy-Monitoring-Platform
/// Estética: Cards con glassmorphism sutil, gradientes, animaciones suaves

/// Constantes de estilo para KPI Cards - garantiza consistencia visual
class _KPICardStyle {
  // Tamaños de gráficos circulares (TODOS usan el mismo)
  static const double circleSize = 80.0;
  static const double strokeWidth = 10.0;

  // Spacing y padding
  static const double cardPadding = 16.0;
  static const double cardBorderRadius = 16.0;
  static const double itemSpacing = 12.0;

  // Tipografía
  static const double titleFontSize = 12.0;
  static const double valueFontSize = 22.0;
  static const double subtitleFontSize = 10.0;
  static const double iconSize = 18.0;

  // Alturas de card
  static const double desktopCardHeight = 180.0;
  static const double mobileCardHeight = 160.0;
}

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadData();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  void _loadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AdminProvider>(context, listen: false);
      provider.loadAllData();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Consumer2<AuthProvider, AdminProvider>(
        builder: (context, auth, provider, child) {
          if (auth.currentUser == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (auth.currentUser!.role != AppRole.Admin) {
            return _buildAccessDenied();
          }

          return FadeTransition(
            opacity: _fadeAnimation,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Padding horizontal extra solo en desktop (>900px)
                final isDesktop = constraints.maxWidth > 900;
                final horizontalPadding = isDesktop ? 48.0 : 16.0;

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildAppBar(auth),
                    SliverPadding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: 16,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          if (provider.isLoading || provider.isLoadingMetrics)
                            _buildLoadingState()
                          else ...[
                            // Header con resumen principal
                            _buildMainHeader(provider),
                            const SizedBox(height: 20),

                            // KPIs principales en grid
                            _buildKPIGrid(provider),
                            const SizedBox(height: 24),

                            // Sección de usuarios
                            _buildSectionTitle(
                              '👥 Usuarios',
                              Icons.people_outline,
                            ),
                            const SizedBox(height: 12),
                            _buildUsersSection(provider),
                            const SizedBox(height: 24),

                            // Sección de Trades
                            _buildSectionTitle(
                              '🔄 Intercambios',
                              Icons.swap_horiz_rounded,
                            ),
                            const SizedBox(height: 12),
                            _buildTradesSection(provider),
                            const SizedBox(height: 24),

                            // Sección de Publicaciones
                            _buildSectionTitle(
                              '📦 Publicaciones',
                              Icons.inventory_2_outlined,
                            ),
                            const SizedBox(height: 12),
                            _buildListingsSection(provider),
                            const SizedBox(height: 24),

                            // Sección de TrueCoins
                            _buildSectionTitle(
                              '💰 Economía',
                              Icons.monetization_on_outlined,
                            ),
                            const SizedBox(height: 12),
                            _buildEconomySection(provider),
                            const SizedBox(height: 24),

                            // Top Usuarios
                            _buildSectionTitle(
                              '🏆 Top Usuarios',
                              Icons.emoji_events_outlined,
                            ),
                            const SizedBox(height: 12),
                            _buildTopUsersSection(provider),
                            const SizedBox(height: 40),
                          ],
                        ]),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppBar(AuthProvider auth) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: const Color(0xFFF8FAFC),
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.dashboard_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Panel Admin',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            Provider.of<AdminProvider>(context, listen: false).loadAllData();
          },
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Actualizar',
        ),
        IconButton(
          onPressed: () =>
              Navigator.pushReplacementNamed(context, AppRoutes.home),
          icon: const Icon(Icons.home_outlined),
          tooltip: 'Ir al inicio',
        ),
        IconButton(
          onPressed: () {
            auth.logout();
            Navigator.pushReplacementNamed(context, AppRoutes.login);
          },
          icon: const Icon(Icons.logout_rounded),
          tooltip: 'Cerrar sesión',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildAccessDenied() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.block, size: 64, color: Colors.redAccent),
          ),
          const SizedBox(height: 24),
          Text(
            'Acceso Denegado',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No tienes permisos para acceder a esta sección.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () =>
                Navigator.pushReplacementNamed(context, AppRoutes.home),
            icon: const Icon(Icons.home_outlined),
            label: const Text('Volver al inicio'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 400,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Cargando métricas...',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainHeader(AdminProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.85)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Text(
                'Resumen General',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildHeaderStat(
                  label: 'Usuarios Totales',
                  value: '${provider.totalUsers}',
                  icon: Icons.people_outline,
                ),
              ),
              Container(width: 1, height: 50, color: Colors.white24),
              Expanded(
                child: _buildHeaderStat(
                  label: 'Activos (7d)',
                  value: '${provider.activeUsersLast7Days}',
                  icon: Icons.trending_up_rounded,
                ),
              ),
              Container(width: 1, height: 50, color: Colors.white24),
              Expanded(
                child: _buildHeaderStat(
                  label: 'Trades (30d)',
                  value: '${provider.tradesLast30Days}',
                  icon: Icons.swap_horiz_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildKPIGrid(AdminProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isMobile = width < 600;

        // Spacing consistente
        const spacing = _KPICardStyle.itemSpacing;

        if (isMobile) {
          // Mobile: Column con cards de altura fija
          return Column(
            children: [
              SizedBox(
                height: _KPICardStyle.mobileCardHeight,
                child: _buildCircularKPICard(
                  title: 'Tasa de Éxito',
                  value: provider.formattedCompletionRate,
                  percentage: provider.completionRate / 100,
                  subtitle:
                      '${provider.completedTrades} de ${provider.totalTrades} trades',
                  icon: Icons.check_circle_outline,
                  color: AppColors.successColor,
                ),
              ),
              const SizedBox(height: spacing),
              SizedBox(
                height: _KPICardStyle.mobileCardHeight,
                child: _buildRadialKPICard(
                  title: 'Tiempo Promedio',
                  value: provider.formattedAvgCompletionTime,
                  subtitle: 'Para cerrar trade',
                  icon: Icons.timer_outlined,
                  color: const Color(0xFF6366F1),
                  maxValue: 24,
                  currentValue: provider.avgClosureTimeHours,
                ),
              ),
              const SizedBox(height: spacing),
              SizedBox(
                height: _KPICardStyle.mobileCardHeight,
                child: _buildDonutKPICard(
                  title: 'Ratio Aceptación',
                  value: provider.formattedAcceptRejectRatio,
                  subtitle: 'Completados vs Cancelados',
                  icon: Icons.thumbs_up_down_outlined,
                  color: const Color(0xFFF59E0B),
                  completed: provider.completedTrades,
                  cancelled: provider.cancelledTrades,
                ),
              ),
              const SizedBox(height: spacing),
              SizedBox(
                height: _KPICardStyle.mobileCardHeight,
                child: _buildVolumeKPICard(
                  title: 'Volumen TC',
                  value: _formatNumber(provider.totalTrueCoinVolume),
                  subtitle: 'TrueCoins en circulación',
                  icon: Icons.monetization_on_outlined,
                  color: const Color(0xFF8B5CF6),
                ),
              ),
            ],
          );
        }

        // Desktop: Grid 2x2 usando Row + Expanded para alineación perfecta
        return Column(
          children: [
            // Primera fila
            SizedBox(
              height: _KPICardStyle.desktopCardHeight,
              child: Row(
                children: [
                  Expanded(
                    child: _buildCircularKPICard(
                      title: 'Tasa de Éxito',
                      value: provider.formattedCompletionRate,
                      percentage: provider.completionRate / 100,
                      subtitle:
                          '${provider.completedTrades} de ${provider.totalTrades} trades',
                      icon: Icons.check_circle_outline,
                      color: AppColors.successColor,
                    ),
                  ),
                  const SizedBox(width: spacing),
                  Expanded(
                    child: _buildRadialKPICard(
                      title: 'Tiempo Promedio',
                      value: provider.formattedAvgCompletionTime,
                      subtitle: 'Para cerrar trade',
                      icon: Icons.timer_outlined,
                      color: const Color(0xFF6366F1),
                      maxValue: 24,
                      currentValue: provider.avgClosureTimeHours,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: spacing),
            // Segunda fila
            SizedBox(
              height: _KPICardStyle.desktopCardHeight,
              child: Row(
                children: [
                  Expanded(
                    child: _buildDonutKPICard(
                      title: 'Ratio Aceptación',
                      value: provider.formattedAcceptRejectRatio,
                      subtitle: 'Completados vs Cancelados',
                      icon: Icons.thumbs_up_down_outlined,
                      color: const Color(0xFFF59E0B),
                      completed: provider.completedTrades,
                      cancelled: provider.cancelledTrades,
                    ),
                  ),
                  const SizedBox(width: spacing),
                  Expanded(
                    child: _buildVolumeKPICard(
                      title: 'Volumen TC',
                      value: _formatNumber(provider.totalTrueCoinVolume),
                      subtitle: 'TrueCoins en circulación',
                      icon: Icons.monetization_on_outlined,
                      color: const Color(0xFF8B5CF6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// KPI Card con gráfico circular de progreso (Tasa de Éxito)
  Widget _buildCircularKPICard({
    required String title,
    required String value,
    required double percentage,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(_KPICardStyle.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_KPICardStyle.cardBorderRadius),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Gráfico circular con AspectRatio 1:1 (siempre círculo perfecto)
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Fondo del círculo
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: 1,
                    strokeWidth: _KPICardStyle.strokeWidth,
                    backgroundColor: color.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      color.withOpacity(0.15),
                    ),
                  ),
                ),
                // Progreso animado
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: percentage.clamp(0, 1)),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutCubic,
                  builder: (context, animatedValue, child) {
                    return SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: animatedValue,
                        strokeWidth: _KPICardStyle.strokeWidth,
                        strokeCap: StrokeCap.round,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    );
                  },
                ),
                // Valor centrado
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: _KPICardStyle.valueFontSize,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: _KPICardStyle.itemSpacing),
          // Información de la card
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header con icono y título
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: _KPICardStyle.iconSize,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: _KPICardStyle.titleFontSize,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Subtítulo
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: _KPICardStyle.subtitleFontSize,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF94A3B8),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// KPI Card con barra radial (Tiempo Promedio)
  Widget _buildRadialKPICard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double maxValue,
    required double currentValue,
  }) {
    final progress = (currentValue / maxValue).clamp(0.0, 1.0);

    return Container(
      padding: EdgeInsets.all(_KPICardStyle.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_KPICardStyle.cardBorderRadius),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: _KPICardStyle.iconSize),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: _KPICardStyle.titleFontSize,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          // Contenido central expandible
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ),
          ),
          // Footer con barra de progreso
          Column(
            children: [
              Container(
                height: 6,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutCubic,
                  builder: (context, animatedValue, child) {
                    return FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: animatedValue,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color, color.withOpacity(0.7)],
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: _KPICardStyle.subtitleFontSize,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF94A3B8),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// KPI Card con donut chart (Ratio Aceptación)
  Widget _buildDonutKPICard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required int completed,
    required int cancelled,
  }) {
    final total = completed + cancelled;
    final completedPct = total > 0 ? completed / total : 0.0;

    return Container(
      padding: EdgeInsets.all(_KPICardStyle.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_KPICardStyle.cardBorderRadius),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Gráfico donut con AspectRatio 1:1 (siempre círculo perfecto)
          AspectRatio(
            aspectRatio: 1,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 1000),
              builder: (context, animatedValue, child) {
                return CustomPaint(
                  painter: _DonutPainter(
                    completedPct: completedPct * animatedValue,
                    completedColor: AppColors.successColor,
                    cancelledColor: Colors.red.shade400,
                    strokeWidth: _KPICardStyle.strokeWidth,
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          value,
                          style: GoogleFonts.inter(
                            fontSize: _KPICardStyle.valueFontSize - 4,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: _KPICardStyle.itemSpacing),
          // Información y leyenda
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: _KPICardStyle.iconSize,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: _KPICardStyle.titleFontSize,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Leyenda
                _buildDonutLegend(
                  'Compl.',
                  completed,
                  AppColors.successColor,
                  true,
                ),
                const SizedBox(height: 4),
                _buildDonutLegend(
                  'Canc.',
                  cancelled,
                  Colors.red.shade400,
                  true,
                ),
                const SizedBox(height: 8),
                // Subtítulo
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: _KPICardStyle.subtitleFontSize,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF94A3B8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonutLegend(String label, int count, Color color, bool compact) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 8 : 10,
          height: compact ? 8 : 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: $count',
          style: GoogleFonts.inter(
            fontSize: compact ? 11 : 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  /// KPI Card con icono animado (Volumen TC)
  Widget _buildVolumeKPICard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(_KPICardStyle.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_KPICardStyle.cardBorderRadius),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icono grande con AspectRatio 1:1
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color, color.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.toll_rounded, color: Colors.white, size: 36),
              ),
            ),
          ),
          const SizedBox(width: _KPICardStyle.itemSpacing),
          // Información
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: _KPICardStyle.iconSize,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: _KPICardStyle.titleFontSize,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Valor principal
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$value TC',
                    style: GoogleFonts.inter(
                      fontSize: _KPICardStyle.valueFontSize + 4,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Subtítulo
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: _KPICardStyle.subtitleFontSize,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF94A3B8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildUsersSection(AdminProvider provider) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetricRow(
            'Usuarios Registrados',
            '${provider.totalUsers}',
            Icons.person_add_outlined,
          ),
          const Divider(height: 24),
          _buildMetricRow(
            'Activos Últimos 7 Días',
            '${provider.activeUsersLast7Days}',
            Icons.trending_up_rounded,
            color: AppColors.successColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Resumen de Actividad',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          _buildActivitySummary(provider),
        ],
      ),
    );
  }

  /// Widget de resumen de actividad con barras visuales
  Widget _buildActivitySummary(AdminProvider provider) {
    final total = provider.totalUsers;
    final active = provider.activeUsersCount;
    final inactive = provider.inactiveUsersCount;
    final newUsers = provider.newUsersLast7Days;

    return Column(
      children: [
        _buildActivityBar(
          label: 'Activos',
          value: active,
          maxValue: total,
          color: AppColors.successColor,
        ),
        const SizedBox(height: 8),
        _buildActivityBar(
          label: 'Inactivos',
          value: inactive,
          maxValue: total,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 8),
        _buildActivityBar(
          label: 'Nuevos (7d)',
          value: newUsers,
          maxValue: total,
          color: const Color(0xFF6366F1),
        ),
      ],
    );
  }

  Widget _buildActivityBar({
    required String label,
    required int value,
    required int maxValue,
    required Color color,
  }) {
    final pct = maxValue > 0 ? value / maxValue : 0.0;
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: pct),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, animatedValue, child) {
                  return FractionallySizedBox(
                    widthFactor: animatedValue,
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, color.withOpacity(0.7)],
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text(
            '$value',
            textAlign: TextAlign.end,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTradesSection(AdminProvider provider) {
    final total = provider.totalTrades;
    final completed = provider.completedTrades;
    final cancelled = provider.cancelledTrades;
    final pending = total - completed - cancelled;

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetricRow(
            'Total de Trades',
            '$total',
            Icons.swap_horiz_rounded,
          ),
          const Divider(height: 24),

          // Gráfico de estados de trades
          Text(
            'Estado de los Trades',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          _buildTradesStatusChart(completed, pending, cancelled, total),
          const SizedBox(height: 16),

          // Métricas de rendimiento
          Row(
            children: [
              Expanded(
                child: _buildMiniMetric(
                  'Tasa Éxito',
                  provider.formattedCompletionRate,
                  AppColors.successColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniMetric(
                  'Tiempo Prom.',
                  provider.formattedAvgCompletionTime,
                  const Color(0xFF6366F1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Gráfico de barras horizontales para estados de trades
  Widget _buildTradesStatusChart(
    int completed,
    int pending,
    int cancelled,
    int total,
  ) {
    return Column(
      children: [
        _buildTradeStatusRow(
          label: 'Completados',
          value: completed,
          total: total,
          color: AppColors.successColor,
          icon: Icons.check_circle_outline,
        ),
        const SizedBox(height: 10),
        _buildTradeStatusRow(
          label: 'Pendientes',
          value: pending,
          total: total,
          color: const Color(0xFFF59E0B),
          icon: Icons.pending_outlined,
        ),
        const SizedBox(height: 10),
        _buildTradeStatusRow(
          label: 'Cancelados',
          value: cancelled,
          total: total,
          color: Colors.red.shade400,
          icon: Icons.cancel_outlined,
        ),
      ],
    );
  }

  Widget _buildTradeStatusRow({
    required String label,
    required int value,
    required int total,
    required Color color,
    required IconData icon,
  }) {
    final pct = total > 0 ? value / total : 0.0;
    final pctStr = (pct * 100).toStringAsFixed(1);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    '$value ($pctStr%)',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Stack(
                children: [
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: pct),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, animatedValue, child) {
                      return FractionallySizedBox(
                        widthFactor: animatedValue,
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListingsSection(AdminProvider provider) {
    final dist = provider.listingTypeDistribution;

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetricRow(
            'Publicaciones Totales',
            '${provider.totalListings}',
            Icons.inventory_2_outlined,
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildMiniMetric(
                  'Activas',
                  '${provider.activeListingsCount}',
                  AppColors.successColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniMetric(
                  'Inactivas',
                  '${provider.inactiveListingsCount}',
                  Colors.red.shade400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Distribución por Tipo',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          _buildDistributionBar(dist),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem('Producto', AppColors.primary, dist.productOnly),
              _buildLegendItem(
                'TrueCoins',
                const Color(0xFF8B5CF6),
                dist.trueCoinOnly,
              ),
              _buildLegendItem('Híbrido', const Color(0xFFF59E0B), dist.hybrid),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionBar(ListingTypeDistribution dist) {
    if (dist.total == 0) {
      return Container(
        height: 16,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 16,
        child: Row(
          children: [
            if (dist.productOnlyPct > 0)
              Expanded(
                flex: (dist.productOnlyPct * 100).round(),
                child: Container(color: AppColors.primary),
              ),
            if (dist.trueCoinOnlyPct > 0)
              Expanded(
                flex: (dist.trueCoinOnlyPct * 100).round(),
                child: Container(color: const Color(0xFF8B5CF6)),
              ),
            if (dist.hybridPct > 0)
              Expanded(
                flex: (dist.hybridPct * 100).round(),
                child: Container(color: const Color(0xFFF59E0B)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label ($count)',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildEconomySection(AdminProvider provider) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF8B5CF6),
                      const Color(0xFF8B5CF6).withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Volumen Total',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    '${_formatNumber(provider.totalTrueCoinVolume)} TC',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 32),
          Row(
            children: [
              Expanded(
                child: _buildMiniMetric(
                  'TC en Activas',
                  _formatNumber(provider.totalTrueCoinsActive),
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniMetric(
                  'Promedio/Pub',
                  provider.avgTrueCoinsPerListing.toStringAsFixed(1),
                  const Color(0xFF6366F1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Histograma de TrueCoins
          Text(
            'Distribución de Valores',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          _buildTrueCoinHistogram(provider),
        ],
      ),
    );
  }

  Widget _buildTrueCoinHistogram(AdminProvider provider) {
    final hist = provider.trueCoinHistogram;
    final entries = [
      MapEntry('0-100', hist['0-100'] ?? 0),
      MapEntry('101-500', hist['101-500'] ?? 0),
      MapEntry('501-1K', hist['501-1000'] ?? 0),
      MapEntry('>1000', hist['>1000'] ?? 0),
    ];
    final maxCount = entries
        .map((e) => e.value)
        .fold<int>(0, (p, c) => c > p ? c : p);

    return Column(
      children: entries.map((e) {
        final frac = maxCount > 0 ? e.value / maxCount : 0.0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  e.key,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: frac,
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF8B5CF6),
                              const Color(0xFF8B5CF6).withOpacity(0.6),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 32,
                child: Text(
                  '${e.value}',
                  textAlign: TextAlign.end,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTopUsersSection(AdminProvider provider) {
    // Calcular top usuarios por trades desde adminTrades
    final topByTrades = _calculateTopUsersByTrades(provider);

    return Column(
      children: [
        // Top por Trades
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.swap_horiz,
                      color: Color(0xFFF59E0B),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Más Activos por Trades',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (topByTrades.isEmpty)
                _buildEmptyStateWithIcon(
                  'Aún no hay trades registrados',
                  Icons.swap_horiz_rounded,
                  const Color(0xFFF59E0B),
                )
              else
                ...topByTrades.asMap().entries.map(
                  (entry) => _buildRankedUserTile(
                    entry.value.name,
                    null,
                    '${entry.value.count} trades',
                    entry.key + 1,
                    const Color(0xFFF59E0B),
                    userId: entry.value.userId,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Top por Publicaciones
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.inventory_2_outlined,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Más Activos por Publicaciones',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (provider.topUsersByListings.isEmpty)
                _buildEmptyStateWithIcon(
                  'Aún no hay publicaciones',
                  Icons.inventory_2_outlined,
                  AppColors.primary,
                )
              else
                ...provider.topUsersByListings
                    .take(5)
                    .toList()
                    .asMap()
                    .entries
                    .map(
                      (entry) => _buildRankedUserTile(
                        entry.value.displayName,
                        entry.value.avatarUrl,
                        '${entry.value.listingCount} publicaciones',
                        entry.key + 1,
                        AppColors.primary,
                        userId: entry.value.userId,
                      ),
                    ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Mejor Valorados
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.star_rounded,
                      color: Colors.amber,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Mejor Valorados',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (provider.topUsersByRating
                  .where((u) => u.averageRating > 0)
                  .isEmpty)
                _buildEmptyStateWithIcon(
                  'Sin valoraciones aún',
                  Icons.star_outline_rounded,
                  Colors.amber,
                )
              else
                ...provider.topUsersByRating
                    .where((u) => u.averageRating > 0)
                    .take(5)
                    .toList()
                    .asMap()
                    .entries
                    .map(
                      (entry) => _buildRankedUserTile(
                        entry.value.displayName,
                        entry.value.avatarUrl,
                        '${entry.value.averageRating.toStringAsFixed(1)} ⭐',
                        entry.key + 1,
                        Colors.amber,
                        userId: entry.value.userId,
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  /// Calcula el top de usuarios por cantidad de trades
  /// Devuelve una lista de (userId, nombre, conteo)
  List<({int userId, String name, int count})> _calculateTopUsersByTrades(
    AdminProvider provider,
  ) {
    final Map<int, int> tradeCounts = {};
    final Map<int, String> userNames = {};

    for (final trade in provider.adminTrades) {
      // Contar trades por requester
      tradeCounts[trade.requesterUserId] =
          (tradeCounts[trade.requesterUserId] ?? 0) + 1;
      // Contar trades por owner
      tradeCounts[trade.ownerUserId] =
          (tradeCounts[trade.ownerUserId] ?? 0) + 1;
    }

    // Obtener nombres de adminUsers
    for (final user in provider.adminUsers) {
      userNames[user.id] = user.name;
    }

    // Convertir a lista ordenada
    final sorted = tradeCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted
        .take(5)
        .map(
          (e) => (
            userId: e.key,
            name: userNames[e.key] ?? 'Usuario ${e.key}',
            count: e.value,
          ),
        )
        .toList();
  }

  Widget _buildEmptyStateWithIcon(String message, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color.withOpacity(0.5), size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankedUserTile(
    String name,
    String? avatarUrl,
    String subtitle,
    int rank,
    Color accentColor, {
    int? userId,
  }) {
    return InkWell(
      onTap: userId != null
          ? () {
              Navigator.pushNamed(
                context,
                AppRoutes.adminUserDetail,
                arguments: userId,
              );
            }
          : null,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            // Ranking badge
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: rank <= 3
                    ? LinearGradient(
                        colors: rank == 1
                            ? [const Color(0xFFFFD700), const Color(0xFFFFA500)]
                            : rank == 2
                            ? [const Color(0xFFC0C0C0), const Color(0xFF9E9E9E)]
                            : [
                                const Color(0xFFCD7F32),
                                const Color(0xFF8B4513),
                              ],
                      )
                    : null,
                color: rank > 3 ? Colors.grey.shade200 : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: rank <= 3 ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Avatar
            CircleAvatar(
              radius: 18,
              backgroundColor: accentColor.withOpacity(0.1),
              backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                  ? NetworkImage(avatarUrl)
                  : null,
              child: avatarUrl == null || avatarUrl.isEmpty
                  ? Icon(Icons.person, color: accentColor, size: 18)
                  : null,
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: accentColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (userId != null)
              Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildMetricRow(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (color ?? AppColors.primary).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color ?? AppColors.primary, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniMetric(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toStringAsFixed(0);
  }
}

/// Custom painter para el gráfico donut del ratio de aceptación
class _DonutPainter extends CustomPainter {
  final double completedPct;
  final Color completedColor;
  final Color cancelledColor;
  final double strokeWidth;

  _DonutPainter({
    required this.completedPct,
    required this.completedColor,
    required this.cancelledColor,
    this.strokeWidth = 10.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(
      center: center,
      radius: radius - strokeWidth / 2,
    );

    // Fondo (cancelados)
    final bgPaint = Paint()
      ..color = cancelledColor.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    // Progreso (completados)
    if (completedPct > 0) {
      final progressPaint = Paint()
        ..color = completedColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * 3.14159 * completedPct;
      canvas.drawArc(rect, -3.14159 / 2, sweepAngle, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.completedPct != completedPct ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
