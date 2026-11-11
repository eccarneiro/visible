import 'package:flutter/material.dart';

import '../../models/mobility_profile.dart';

class ImpactChip extends StatelessWidget {
  final ImpactLevel level;
  final String? prefix;
  const ImpactChip({super.key, required this.level, this.prefix});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: level.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${prefix ?? ''}${level.label}',
        style: TextStyle(
            color: level.color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
