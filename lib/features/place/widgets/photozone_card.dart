import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../../core/network_thumb.dart';
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
          child: NetworkThumb(
            url: zone.imageUrl,
            width: 80,
            height: 80,
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
                  const Icon(Icons.photo_camera_outlined, size: 13, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text('사진 ${zone.photoCount}장',
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
