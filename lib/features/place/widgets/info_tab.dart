import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/app_theme.dart';
import '../place_provider.dart';

class InfoTab extends StatelessWidget {
  const InfoTab({super.key});

  @override
  Widget build(BuildContext context) {
    final info = context.watch<PlaceProvider>().detail?.info;
    if (info == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoRow(icon: Icons.location_on_outlined, text: info.address),
        const SizedBox(height: 12),
        _InfoRow(icon: Icons.access_time, text: info.hours),
        if (info.phone != null) ...[
          const SizedBox(height: 12),
          _InfoRow(icon: Icons.phone_outlined, text: info.phone!),
        ],
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 14, color: AppColors.textMain)),
        ),
      ],
    );
  }
}
