import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../mypage_models.dart';

class LikedZonesTab extends StatelessWidget {
  const LikedZonesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final photos = GridPhoto.mockList();
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2,
      ),
      itemCount: photos.length,
      itemBuilder: (context, i) => Image.network(
        photos[i].imageUrl, fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) =>
            Container(color: AppColors.illustrationBox),
      ),
    );
  }
}
