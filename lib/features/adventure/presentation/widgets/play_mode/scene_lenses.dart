import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

enum SceneLens {
  narrative,
  combat,
  investigation;

  String get label {
    switch (this) {
      case SceneLens.narrative:
        return 'Narrativa';
      case SceneLens.combat:
        return 'Combate';
      case SceneLens.investigation:
        return 'Investigação';
    }
  }

  IconData get icon {
    switch (this) {
      case SceneLens.narrative:
        return Icons.menu_book;
      case SceneLens.combat:
        return Icons.flash_on;
      case SceneLens.investigation:
        return Icons.search;
    }
  }
}

class LensSelector extends StatelessWidget {
  final SceneLens currentLens;
  final ValueChanged<SceneLens> onLensChanged;

  const LensSelector({
    super.key,
    required this.currentLens,
    required this.onLensChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: SceneLens.values.map((lens) {
          final isSelected = lens == currentLens;
          return Expanded(
            child: InkWell(
              onTap: () => onLensChanged(lens),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primary.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected
                      ? Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.5),
                        )
                      : null,
                ),
                child: Column(
                  children: [
                    Icon(
                      lens.icon,
                      size: 20,
                      color: isSelected ? AppTheme.primary : Colors.grey,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lens.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected ? AppTheme.primary : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
