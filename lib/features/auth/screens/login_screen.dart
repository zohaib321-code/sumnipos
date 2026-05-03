import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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
    final success = await context.read<AuthProvider>().login(_pin);
    if (!success) {
      setState(() {
        _pin = '';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('INVALID PIN', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            width: 300,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Row(
        children: [
          // Left Side: Branding/Logo
          Expanded(
            flex: 4,
            child: Container(
              color: AppTheme.primary,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bolt, size: 80, color: Colors.white),
                  const SizedBox(height: 24),
                  const Text(
                    'VELOCITY POS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Smart Sales. Efficient Workflow.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Right Side: PIN Pad
          Expanded(
            flex: 6,
            child: Container(
              color: AppTheme.surface,
              child: Center(
                child: SizedBox(
                  width: 340,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'TERMINAL LOGIN',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Enter your personal 4-digit PIN',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                      ),
                      const SizedBox(height: 48),
                      
                      // PIN Indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (index) {
                          final filled = index < _pin.length;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: filled ? AppTheme.primary : Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: filled ? AppTheme.primary : AppTheme.outline, 
                                width: 2
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 48),
                      
                      // Keypad
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 3,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.4,
                        children: [
                          for (var i = 1; i <= 9; i++) _buildKey('$i'),
                          const SizedBox.shrink(),
                          _buildKey('0'),
                          _buildBackspace(),
                        ],
                      ),
                      
                      const SizedBox(height: 64),
                      Text(
                        'Powered by Sunmi T2 Mini',
                        style: TextStyle(
                          color: AppTheme.textMuted.withOpacity(0.5),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
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
