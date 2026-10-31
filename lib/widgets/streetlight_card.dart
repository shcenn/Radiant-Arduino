import 'package:flutter/material.dart';

import '../models/streetlight.dart';
import '../theme/app_theme.dart';
import 'status_badge.dart';
import 'unit_indicators.dart';

class StreetlightCard extends StatelessWidget {
  final Streetlight light;
  final VoidCallback onTap;

  const StreetlightCard({super.key, required this.light, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: light.status.color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.lightbulb, color: light.status.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    light.id,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    light.statusReason.isEmpty
                        ? light.location
                        : light.statusReason,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  UnitIndicators(light: light),
                ],
              ),
            ),
            StatusBadge(status: light.status),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
