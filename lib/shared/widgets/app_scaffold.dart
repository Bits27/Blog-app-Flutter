// Shared page scaffold with consistent chrome, spacing, and background effects.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/app_theme.dart';
import '../utils/responsive.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.title,
    required this.child,
    this.maxContentWidth = 560,
    this.scrollable = true,
    super.key,
  });

  final String title;
  final Widget child;
  final double maxContentWidth;
  final bool scrollable;

  Widget _buildTopBarTitle(BuildContext context) {
    final compact = Responsive.isCompact(context);
    if (compact) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INKFRAME',
            style: GoogleFonts.bebasNeue(
              fontSize: 30,
              color: AppTheme.ink,
              letterSpacing: 1,
            ),
          ),
          Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      );
    }

    return Row(
      children: [
        Text(
          'INKFRAME',
          style: GoogleFonts.bebasNeue(
            fontSize: 36,
            color: AppTheme.ink,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = Responsive.value(
      context,
      compact: 12,
      medium: 20,
      expanded: 24,
    );
    final verticalPadding = Responsive.value(
      context,
      compact: 12,
      medium: 16,
      expanded: 20,
    );

    Widget content = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxContentWidth),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );

    if (scrollable) {
      content = SingleChildScrollView(child: content);
    }

    return Scaffold(
      appBar: AppBar(title: _buildTopBarTitle(context)),
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned(
              left: -120,
              top: -100,
              child: _GlowBlob(size: 360, color: AppTheme.peach),
            ),
            const Positioned(
              right: -100,
              top: -120,
              child: _GlowBlob(size: 320, color: Color(0x66D8FFF6)),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: content,
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, Colors.transparent]),
        ),
      ),
    );
  }
}
