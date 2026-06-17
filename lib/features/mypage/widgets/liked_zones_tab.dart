import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/app_theme.dart';
import '../../photo/photo_service.dart';
import '../mypage_models.dart';
import 'photo_grid_tile.dart';

class LikedZonesTab extends StatefulWidget {
  const LikedZonesTab({super.key});

  @override
  State<LikedZonesTab> createState() => _LikedZonesTabState();
}

class _LikedZonesTabState extends State<LikedZonesTab>
    with AutomaticKeepAliveClientMixin {
  List<GridPhoto>? _photos;
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final photos = await context.read<PhotoService>().getLikedPhotos();
      if (!mounted) return;
      setState(() => _photos = photos.map(GridPhoto.fromPhotoInfo).toList());
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryPink));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPink),
              child: const Text('다시 시도', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
    final photos = _photos ?? [];
    if (photos.isEmpty) {
      return const Center(
        child: Text('좋아요한 사진이 없습니다.', style: TextStyle(color: AppColors.textMuted)),
      );
    }
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
