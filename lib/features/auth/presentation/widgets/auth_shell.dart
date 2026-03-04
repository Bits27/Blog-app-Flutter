// Shared visual shell used by login and register screens.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/app_theme.dart';
import '../../../../shared/utils/responsive.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({
    required this.title,
    required this.gradientCenter,
    required this.gradientRadius,
    required this.gradientColor,
    required this.child,
    super.key,
  });

  final String title;
  final Alignment gradientCenter;
  final double gradientRadius;
  final Color gradientColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isCompact = Responsive.isCompact(context);
    final outerPadding = isCompact ? 12.0 : 16.0;
    final cardPadding = isCompact ? 16.0 : 22.0;
    final brandFontSize = isCompact ? 34.0 : 42.0;
    final titleFontSize = isCompact ? 26.0 : 30.0;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: gradientCenter,
            radius: gradientRadius,
            colors: [gradientColor, Colors.transparent],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(outerPadding),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: EdgeInsets.all(cardPadding),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFDF8),
                  border: Border.all(color: AppTheme.softBorder, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 18,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'INKFRAME',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.bebasNeue(
                        fontSize: brandFontSize,
                        letterSpacing: 1,
                        color: AppTheme.ink,
                      ),
                    ),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.bebasNeue(
                        fontSize: titleFontSize,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 16),
                    child,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
