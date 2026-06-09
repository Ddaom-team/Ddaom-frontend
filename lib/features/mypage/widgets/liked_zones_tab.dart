import 'package:flutter/material.dart';

import '../mypage_models.dart';
import 'photo_grid_tile.dart';

class LikedZonesTab extends StatelessWidget {
  const LikedZonesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final photos = GridPhoto.mockLikedPhotos();
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 0.72,
      ),
      itemCount: photos.length,
      itemBuilder: (context, i) => PhotoGridTile(photo: photos[i]),
    );
  }
}