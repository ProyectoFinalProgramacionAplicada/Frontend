import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Constantes de estilo para About Screen - consistencia visual con Login/Register
class _AboutScreenStyle {
  // Colores
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color cardColor = Colors.white;
  static const Color primaryColor = Color(0xFF166534);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color borderColor = Color(0xFFE2E8F0);

  // Bordes y sombras
  static const double borderRadius = 16.0;
  static const double smallBorderRadius = 12.0;

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  // Tipografía
  static TextStyle get headingStyle => GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.5,
  );

  static TextStyle get subtitleStyle => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    height: 1.5,
  );

  static TextStyle get sectionTitleStyle => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static TextStyle get bodyStyle => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: const Color(0xFF475569),
    height: 1.5,
  );

  static TextStyle get labelStyle => GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: textSecondary,
  );
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  // Integrantes del equipo (orden alfabético)
  static const List<Map<String, String>> _teamMembers = [
    {'name': 'Matías Castellanos Bedregal', 'role': 'Desarrollador'},
    {'name': 'Victoria Frias H. Muñoz', 'role': 'Desarrolladora'},
    {'name': 'Diego Sebastián Orellana', 'role': 'Desarrollador'},
    {'name': 'Samuel Zárate Gamarra', 'role': 'Desarrollador'},
  ];

  // Reglas de uso completas
  static const List<Map<String, dynamic>> _rules = [
    {
      'icon': Icons.verified_user_outlined,
      'title': 'Uso responsable',
      'description':
          'TruekApp es una plataforma de intercambio; cada usuario es responsable de los productos que publica y de verificar los intercambios que realiza.',
    },
    {
      'icon': Icons.block_outlined,
      'title': 'Prohibiciones',
      'description':
          'No se permite publicar objetos peligrosos, ilegales, falsificados o que infrinjan derechos de terceros.',
    },
    {
      'icon': Icons.price_check_outlined,
      'title': 'Transparencia y precios',
      'description':
          'Los productos deben incluir un valor referencial real, respaldado por precio o factura, para equilibrar el uso de truecoins.',
    },
    {
      'icon': Icons.people_outline_rounded,
      'title': 'Interacciones entre usuarios',
      'description':
          'Los acuerdos de intercambio se realizan directamente entre las partes. TruekApp funciona como intermediario tecnológico, no como vendedor.',
    },
    {
      'icon': Icons.monetization_on_outlined,
      'title': 'Moneda virtual (TrueCoins)',
      'description':
          'No representa dinero real. Su propósito es facilitar equivalencias de valor para permitir intercambios justos.',
    },
    {
      'icon': Icons.lock_outline_rounded,
      'title': 'Privacidad',
      'description':
          'TruekApp solo usa datos básicos necesarios para operar la cuenta del usuario. No se comparten datos con terceros.',
    },
    {
      'icon': Icons.security_outlined,
      'title': 'Seguridad y comportamiento',
      'description':
          'Está prohibido el acoso, fraude, suplantación o cualquier comportamiento que comprometa la experiencia de otros usuarios.',
    },
    {
      'icon': Icons.gavel_outlined,
      'title': 'Sanciones',
      'description':
          'TruekApp puede suspender o eliminar cuentas que incumplan estas normas.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AboutScreenStyle.backgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;
          final isTablet =
              constraints.maxWidth >= 600 && constraints.maxWidth < 900;

          return CustomScrollView(
            slivers: [
              // AppBar moderno
              _buildSliverAppBar(context),

              // Contenido
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 64 : (isTablet ? 32 : 20),
                    vertical: 24,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: isDesktop
                          ? _buildDesktopLayout()
                          : _buildMobileLayout(),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      backgroundColor: _AboutScreenStyle.primaryColor,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: const EdgeInsets.only(bottom: 16),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Acerca de TruekApp',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Reglas de uso y equipo',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _AboutScreenStyle.primaryColor,
                _AboutScreenStyle.primaryColor.withOpacity(0.85),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -50,
                top: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                left: -30,
                bottom: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Column(
      children: [
        // Sección de Propósito (ancho completo arriba)
        _buildPurposeSection(),
        const SizedBox(height: 24),
        // Dos columnas
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Columna izquierda: Info App + Equipo
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  _buildAppInfoCard(),
                  const SizedBox(height: 24),
                  _buildTeamSection(),
                ],
              ),
            ),
            const SizedBox(width: 24),
            // Columna derecha: Reglas de uso
            Expanded(flex: 1, child: _buildRulesSection()),
          ],
        ),
        const SizedBox(height: 32),
        _buildFooter(),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildPurposeSection(),
        const SizedBox(height: 24),
        _buildAppInfoCard(),
        const SizedBox(height: 24),
        _buildTeamSection(),
        const SizedBox(height: 24),
        _buildRulesSection(),
        const SizedBox(height: 32),
        _buildFooter(),
      ],
    );
  }

  Widget _buildPurposeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _AboutScreenStyle.primaryColor.withOpacity(0.08),
            _AboutScreenStyle.primaryColor.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(_AboutScreenStyle.borderRadius),
        border: Border.all(
          color: _AboutScreenStyle.primaryColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          // Icono
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _AboutScreenStyle.primaryColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.favorite_rounded,
              size: 32,
              color: _AboutScreenStyle.primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Nuestro Propósito',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _AboutScreenStyle.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Crear una economía colaborativa que ayude a las personas a obtener lo que necesitan sin perder dinero, especialmente en tiempos de crisis.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: _AboutScreenStyle.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _AboutScreenStyle.cardColor,
        borderRadius: BorderRadius.circular(_AboutScreenStyle.borderRadius),
        boxShadow: _AboutScreenStyle.softShadow,
        border: Border.all(
          color: _AboutScreenStyle.borderColor.withOpacity(0.5),
        ),
      ),
      child: Column(
        children: [
          // Logo
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _AboutScreenStyle.primaryColor.withOpacity(0.1),
                  _AboutScreenStyle.primaryColor.withOpacity(0.05),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.swap_horiz_rounded,
              size: 48,
              color: _AboutScreenStyle.primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '© 2025 TruekApp',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _AboutScreenStyle.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _AboutScreenStyle.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Versión 1.0.0',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _AboutScreenStyle.primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'De Santa Cruz pal mundo 💚',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: _AboutScreenStyle.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _AboutScreenStyle.cardColor,
        borderRadius: BorderRadius.circular(_AboutScreenStyle.borderRadius),
        boxShadow: _AboutScreenStyle.softShadow,
        border: Border.all(
          color: _AboutScreenStyle.borderColor.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _AboutScreenStyle.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.groups_rounded,
                  color: _AboutScreenStyle.primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'Equipo de Desarrollo',
                style: _AboutScreenStyle.sectionTitleStyle,
              ),
            ],
          ),
          const SizedBox(height: 20),
          ..._teamMembers.map((member) => _buildTeamMemberTile(member)),
        ],
      ),
    );
  }

  Widget _buildTeamMemberTile(Map<String, String> member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _AboutScreenStyle.backgroundColor,
        borderRadius: BorderRadius.circular(
          _AboutScreenStyle.smallBorderRadius,
        ),
        border: Border.all(
          color: _AboutScreenStyle.borderColor.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _AboutScreenStyle.primaryColor,
                  _AboutScreenStyle.primaryColor.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                member['name']!.substring(0, 1).toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member['name']!,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _AboutScreenStyle.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  member['role']!,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: _AboutScreenStyle.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRulesSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _AboutScreenStyle.cardColor,
        borderRadius: BorderRadius.circular(_AboutScreenStyle.borderRadius),
        boxShadow: _AboutScreenStyle.softShadow,
        border: Border.all(
          color: _AboutScreenStyle.borderColor.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.rule_rounded,
                  color: Color(0xFF3B82F6),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Text('Reglas de Uso', style: _AboutScreenStyle.sectionTitleStyle),
            ],
          ),
          const SizedBox(height: 20),
          ..._rules.map((rule) => _buildRuleTile(rule)),
        ],
      ),
    );
  }

  Widget _buildRuleTile(Map<String, dynamic> rule) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _AboutScreenStyle.backgroundColor,
        borderRadius: BorderRadius.circular(
          _AboutScreenStyle.smallBorderRadius,
        ),
        border: Border.all(
          color: _AboutScreenStyle.borderColor.withOpacity(0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _AboutScreenStyle.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              rule['icon'] as IconData,
              color: _AboutScreenStyle.primaryColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rule['title'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _AboutScreenStyle.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rule['description'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: _AboutScreenStyle.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const Divider(color: Color(0xFFE2E8F0)),
        const SizedBox(height: 16),
        Text(
          'Hecho con 💚 en Santa Cruz, Bolivia',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: _AboutScreenStyle.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Universidad Privada de Santa Cruz de la Sierra',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: const Color(0xFFB0B8C4),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
