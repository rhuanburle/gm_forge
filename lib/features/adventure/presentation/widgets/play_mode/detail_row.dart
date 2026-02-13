import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

class DetailRow extends StatelessWidget {
  final String label;
  final String text;
  final IconData? icon;

  const DetailRow(this.label, this.text, {super.key, this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: AppTheme.secondary),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: AppTheme.secondary,
              ),
            ),
          ],
        ),
        Text(text.isEmpty ? '-' : text),
      ],
    );
  }
}
