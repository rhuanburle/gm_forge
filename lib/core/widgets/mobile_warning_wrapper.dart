import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'responsive_layout.dart';

class MobileWarningWrapper extends StatelessWidget {
  final Widget child;

  const MobileWarningWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < Breakpoints.compact) {
          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.heroGradient,
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/logo_quest_script.png',
                        height: 100,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.auto_stories,
                          size: 80,
                          color: AppTheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Quest Script',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondary,
                          fontFamily: 'Cinzel',
                        ),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(AppTheme.r16),
                          border: Border.all(color: AppTheme.primaryDark),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.desktop_windows,
                              size: 48,
                              color: AppTheme.textMuted,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Experiência Desktop',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'O Quest Script foi projetado para telas maiores, ideais para mestres durante a preparação e condução de sessões.\n\nAcesse pelo computador ou tablet em modo paisagem para a melhor experiência.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
        return child;
      },
    );
  }
}
