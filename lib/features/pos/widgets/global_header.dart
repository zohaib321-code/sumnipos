import 'package:flutter/material.dart';
import 'package:sunmi_pos/core/theme/app_theme.dart';

class GlobalHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool showLogo;
  final VoidCallback? onLogoTap;

  const GlobalHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.showLogo = true,
    this.onLogoTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      color: AppTheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          if (showLogo) ...[
            GestureDetector(
              onTap: onLogoTap,
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'V',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppTheme.primary,
                  letterSpacing: 0.5,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    color: AppTheme.textMuted,
                    letterSpacing: 1.0,
                  ),
                ),
            ],
          ),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
