import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../place_models.dart';

class PhotozoneCard extends StatelessWidget {
  final PhotoZone zone;
  const PhotozoneCard({super.key, required this.zone});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            zone.imageUrl,
            width: 80, height: 80,
            fit: BoxFit.cover,
            errorBuilder: (ctx, err, stack) => Container(
              width: 80, height: 80, color: AppColors.illustrationBox,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(zone.name,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.favorite_border, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text('${zone.likeCount}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(width: 12),
                  const Icon(Icons.bookmark_border, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text('${zone.saveCount}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
