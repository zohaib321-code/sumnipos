import 'package:flutter/material.dart';
import 'package:sunmi_pos/features/pos/widgets/global_header.dart';
import 'package:sunmi_pos/core/theme/app_theme.dart';

/// Fullscreen shell for admin modules with a consistent top header.
class AdminShell extends StatelessWidget {
  final String pageTitle;
  final String pageSubtitle;
  final Widget child;
  final bool showBackButton;

  const AdminShell({
    super.key,
    required this.pageTitle,
    required this.pageSubtitle,
    required this.child,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          GlobalHeader(
            title: 'VELOCITY ADMIN',
            subtitle: pageTitle,
            trailing: Row(
              children: [
                if (showBackButton)
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('BACK'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.onSurfaceVar,
                      textStyle: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                  icon: const Icon(Icons.point_of_sale, size: 18),
                  label: const Text('BACK TO POS'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    textStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}



