import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  // ============================================================
  //                       BUILD PRINCIPAL
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final isMobile = screenWidth < 600;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF166534),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 24 : 48,
              vertical: isMobile ? 20 : 40,
            ),
            child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
          ),
        ),
      ),
    );
  }

  // ============================================================
  //                     MOBILE LAYOUT
  // ============================================================
  Widget _buildMobileLayout() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 36),
            _buildInfoCard(),
            const SizedBox(height: 32),
            _buildTeamSection(),
            const SizedBox(height: 32),
            _buildRulesSection(),
            const SizedBox(height: 32),
            _buildFooter(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ============================================================
  //                     DESKTOP LAYOUT (Grid)
  // ============================================================
  Widget _buildDesktopLayout() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: Column(
          children: [
            // Header centrado
            _buildHeader(),
            const SizedBox(height: 48),

            // Primera fila: Info Card + Team
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 1, child: _buildInfoCard()),
                const SizedBox(width: 32),
                Expanded(flex: 1, child: _buildTeamSection()),
              ],
            ),
            const SizedBox(height: 32),

            // Segunda fila: Rules (full width pero en grid interno)
            _buildRulesSection(),
            const SizedBox(height: 32),

            // Footer centrado
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: _buildFooter(),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ============================================================
  //                         HEADER
  // ============================================================
  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF166534).withOpacity(0.15),
                blurRadius: 30,
                spreadRadius: 5,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF166534).withOpacity(0.08),
                  const Color(0xFF166534).withOpacity(0.15),
                ],
              ),
            ),
            child: const Icon(
              Icons.swap_horiz_rounded,
              size: 60,
              color: Color(0xFF166534),
            ),
          ),
        ),
        const SizedBox(height: 24),

        Text(
          'Acerca de TruekApp',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
            letterSpacing: -0.5,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),

        Text(
          'Reglas de uso y equipo de desarrollo',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF64748B),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // ============================================================
  //                         INFO CARD
  // ============================================================
  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0).withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF166534).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF166534), const Color(0xFF10B981)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF166534).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),

          Text(
            '© 2025 TruekApp',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF3B82F6).withOpacity(0.1),
                  const Color(0xFF8B5CF6).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF3B82F6).withOpacity(0.2),
              ),
            ),
            child: Text(
              'Versión 1.0.0',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3B82F6),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF166534).withOpacity(0.05),
                  const Color(0xFF10B981).withOpacity(0.10),
                ],
              ),
              border: Border.all(
                color: const Color(0xFF166534).withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.favorite_rounded,
                  color: Color(0xFF166534),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'De Santa Cruz pal mundo 💚',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF166534),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  //                       TEAM SECTION
  // ============================================================
  Widget _buildTeamSection() {
    final List<Map<String, String>> team = [
      {
        'name': 'Matías Castellanos Bedregal',
        'career': 'Ingeniería Mecatrónica y Robótica — UPSA',
        'color': '0xFF8B5CF6', // Violeta
      },
      {
        'name': 'Diego Sebastián Orellana',
        'career': 'Ingeniería Industrial y de Sistemas — UPSA',
        'color': '0xFF3B82F6', // Azul
      },
      {
        'name': 'Victoria Frias H. Muñoz',
        'career': 'Ingeniería Mecatrónica y Robótica — UPSA',
        'color': '0xFFEC4899', // Rosa
      },
      {
        'name': 'Samuel Zárate Gamarra',
        'career': 'Ingeniería Industrial y de Sistemas — UPSA',
        'color': '0xFF10B981', // Verde claro
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF166534).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.groups_rounded,
                color: Color(0xFF166534),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Equipo de Desarrollo',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        ...team.map(
          (member) => _buildTeamMemberCard(
            member['name']!,
            member['career']!,
            Color(int.parse(member['color']!)),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamMemberCard(String name, String career, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [accentColor, accentColor.withOpacity(0.7)],
              ),
            ),
            child: Center(
              child: Text(
                name[0],
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  career,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

          Icon(Icons.person_rounded, color: accentColor, size: 20),
        ],
      ),
    );
  }

  // ============================================================
  //                       RULES SECTION
  // ============================================================
  Widget _buildRulesSection() {
    final List<Map<String, dynamic>> rules = [
      {
        'icon': Icons.verified_user_rounded,
        'title': 'Uso responsable',
        'description':
            'Cada usuario debe actuar de forma ética y transparente.',
        'color': const Color(0xFF166534), // Verde principal
      },
      {
        'icon': Icons.gavel_rounded,
        'title': 'Prohibido contenido ilegal',
        'description':
            'No se permiten artículos prohibidos, peligrosos o falsificados.',
        'color': const Color(0xFFDC2626), // Rojo
      },
      {
        'icon': Icons.lightbulb_outline_rounded,
        'title': 'Transparencia',
        'description':
            'Todo producto publicado debe incluir un valor real verificable.',
        'color': const Color(0xFFF59E0B), // Amarillo/Naranja
      },
      {
        'icon': Icons.handshake_rounded,
        'title': 'Interacciones entre usuarios',
        'description':
            'TruekApp es un intermediario tecnológico sin responsabilidad directa.',
        'color': const Color(0xFF3B82F6), // Azul
      },
      {
        'icon': Icons.account_balance_wallet_rounded,
        'title': 'TrueCoins informativas',
        'description':
            'Los TrueCoins no tienen valor monetario, solo informativo.',
        'color': const Color(0xFF8B5CF6), // Violeta
      },
      {
        'icon': Icons.privacy_tip_rounded,
        'title': 'Privacidad protegida',
        'description':
            'Se utiliza únicamente la información esencial para el funcionamiento de la app.',
        'color': const Color(0xFF10B981), // Verde claro
      },
      {
        'icon': Icons.favorite_border_rounded,
        'title': 'Comportamiento respetuoso',
        'description':
            'No se toleran faltas de respeto, acoso, suplantación de identidad o fraude.',
        'color': const Color(0xFFEC4899), // Rosa
      },
      {
        'icon': Icons.block_rounded,
        'title': 'Suspensión por fraude',
        'description':
            'El incumplimiento de las reglas puede derivar en suspensión inmediata.',
        'color': const Color(0xFFEF4444), // Rojo intenso
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1024;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF166534).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.rule_rounded,
                    color: Color(0xFF166534),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Reglas de Uso',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Grid en desktop, lista en móvil
            if (isDesktop)
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: rules
                    .map(
                      (r) => SizedBox(
                        width: (constraints.maxWidth - 16) / 2,
                        child: _buildRuleCard(
                          r['icon'] as IconData,
                          r['title']!,
                          r['description']!,
                          r['color'] as Color,
                        ),
                      ),
                    )
                    .toList(),
              )
            else
              ...rules
                  .map(
                    (r) => _buildRuleCard(
                      r['icon'] as IconData,
                      r['title']!,
                      r['description']!,
                      r['color'] as Color,
                    ),
                  )
                  .toList(),
          ],
        );
      },
    );
  }

  Widget _buildRuleCard(
    IconData icon,
    String title,
    String description,
    Color accentColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor, size: 24),
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  //                         FOOTER
  // ============================================================
  Widget _buildFooter() {
    final List<Map<String, dynamic>> contacts = [
      {
        'icon': Icons.language_rounded,
        'text': 'app-250928235242.azurewebsites.net',
      },
      {'icon': Icons.email_rounded, 'text': 'victoria.frias@upsa.edu.bo'},
      {'icon': Icons.email_rounded, 'text': 'matias.cb@upsa.edu.bo'},
      {'icon': Icons.email_rounded, 'text': 'diegoseb.orellana@upsa.edu.bo'},
      {'icon': Icons.email_rounded, 'text': 'samuel.zarateg@upsa.edu.bo'},
      {'icon': Icons.phone_rounded, 'text': 'WhatsApp: +591 700-00000'},
    ];

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF166534).withOpacity(0.05),
            const Color(0xFF166534).withOpacity(0.09),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            color: Color(0xFF166534),
            size: 28,
          ),
          const SizedBox(height: 12),

          Text(
            '¿Tenés dudas?',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),

          Text(
            'Contactanos en cualquier momento, estamos para ayudarte.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),

          ...contacts.map(
            (c) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    c['icon'] as IconData,
                    color: const Color(0xFF166534),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      c['text']!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
