import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_service.dart';
import '../../../../core/theme/app_theme.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  bool _isLoading = false;
  String? _error;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final result = await authService.signInWithGoogle();

      if (result != null && mounted) {
        context.go('/');
      }
    } catch (e) {
      setState(() => _error = 'Erro ao fazer login: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _continueAsGuest() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(isGuestModeProvider.notifier).setGuestMode(true);

      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      setState(() => _error = 'Erro ao continuar como convidado: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.heroGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logo_quest_script.png',
                    height: 180,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Quest Script',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppTheme.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Criador de Locais de Aventura',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 48),

                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.error),
                      ),
                      child: Text(
                        _error!,
                        style: TextStyle(color: AppTheme.error),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  if (_isLoading)
                    CircularProgressIndicator(color: AppTheme.secondary)
                  else ...[
                    SizedBox(
                      width: 280,
                      child: ElevatedButton.icon(
                        onPressed: _signInWithGoogle,
                        icon: const Icon(Icons.login),
                        label: const Text('Entrar com Google'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: _continueAsGuest,
                      child: Text(
                        'Continuar como Convidado',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '(Dados salvos apenas localmente)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
