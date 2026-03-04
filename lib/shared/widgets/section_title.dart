// Section heading widget with accent underline and subtle glow decoration.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/app_theme.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.fontSize = 32});

  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 0,
          right: 0,
          bottom: 2,
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: AppTheme.mint.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        Text(
          text,
          style: GoogleFonts.bebasNeue(
            fontSize: fontSize,
            letterSpacing: 0.8,
            color: AppTheme.ink,
          ),
        ),
      ],
    );
  }
}
