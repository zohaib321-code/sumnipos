import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

class PinDialog extends StatefulWidget {
  final VoidCallback? onSuccess;

  const PinDialog({super.key, this.onSuccess});

  @override
  State<PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<PinDialog> {
  String _pin = '';

  void _onKeyPress(String value) {
    if (_pin.length < 4) {
      setState(() {
        _pin += value;
      });
      if (_pin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  Future<void> _verifyPin() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.login(_pin);
    if (success) {
      if (mounted) {
        Navigator.of(context).pop(true);
        if (widget.onSuccess != null) {
          widget.onSuccess!();
        }
      }
    } else {
      setState(() {
        _pin = '';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('INVALID PIN', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 320,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'AUTHORIZATION',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.0),
            ),
            const SizedBox(height: 20),
            // PIN Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final filled = index < _pin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: filled ? AppTheme.primary : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: filled ? AppTheme.primary : AppTheme.outline, 
                      width: 1.5
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 28),
            // Keypad
            SizedBox(
              width: 220,
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.4,
                children: [
                  for (var i = 1; i <= 9; i++) _buildKey('$i'),
                  const SizedBox.shrink(),
                  _buildKey('0'),
                  _buildBackspace(),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 220,
              height: 44,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.outline),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  foregroundColor: AppTheme.onSurfaceVar,
                ),
                child: const Text('CANCEL', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800, fontSize: 11)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKey(String value) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _onKeyPress(value),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 24, 
              fontWeight: FontWeight.w900, 
              fontFamily: 'Inter',
              color: AppTheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspace() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _onBackspace,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.backspace_outlined, size: 24, color: AppTheme.textMuted),
        ),
      ),
    );
  }
}
