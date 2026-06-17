import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/app_theme.dart';
import '../home/home_models.dart';
import '../place/place_detail_screen.dart';
import 'saved_places_provider.dart';

class SavedPlacesScreen extends StatelessWidget {
  const SavedPlacesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => SavedPlacesProvider(ctx.read<ApiClient>()),
      child: const _SavedPlacesView(),
    );
  }
}

class _SavedPlacesView extends StatelessWidget {
  const _SavedPlacesView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SavedPlacesProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '저장한 장소',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: _buildBody(context, provider),
    );
  }

  Widget _buildBody(BuildContext context, SavedPlacesProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(provider.error!, style: const TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.read<SavedPlacesProvider>().load(),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }
    if (provider.places.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bookmark_border, size: 56, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text(
              '저장한 장소가 없어요',
              style: TextStyle(fontSize: 15, color: AppColors.textMuted),
            ),
            SizedBox(height: 4),
            Text(
              '장소 상세에서 북마크를 눌러 저장해 보세요',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryPink,
      onRefresh: () => context.read<SavedPlacesProvider>().load(),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: provider.places.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
        itemBuilder: (context, index) =>
            _PlaceListItem(place: provider.places[index]),
      ),
    );
  }
}

class _PlaceListItem extends StatelessWidget {
  final Place place;
  const _PlaceListItem({required this.place});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlaceDetailScreen(placeId: place.id),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                place.thumbnailUrl ?? 'https://picsum.photos/seed/${place.id}/200/200',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 80,
                  height: 80,
                  color: AppColors.illustrationBox,
                  child: const Icon(Icons.image_not_supported_outlined,
                      color: AppColors.textMuted),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          place.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMain,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.illustrationBox,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          place.category.label,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.primaryPink),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    place.address,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.camera_alt_outlined,
                          size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 3),
                      Text(
                        '포토존 ${place.photoSpotCount}개',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
