import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/app_theme.dart';
import '../community/community_post_detail_screen.dart';
import 'photo_models.dart';
import 'photo_service.dart';

/// 포토존 카드를 탭하면 그 포토존(photoSpotId)에 사람들이 올린 사진을 그리드로 보여준다.
/// 사진을 탭하면 사진 상세로 이동하며, 이미 아는 장소·포토존명을 location으로 넘겨 표시한다.
class PhotospotPhotosScreen extends StatefulWidget {
  final int photoSpotId;
  final String photoZoneName;
  final String? placeName;

  const PhotospotPhotosScreen({
    super.key,
    required this.photoSpotId,
    required this.photoZoneName,
    this.placeName,
  });

  @override
  State<PhotospotPhotosScreen> createState() => _PhotospotPhotosScreenState();
}

class _PhotospotPhotosScreenState extends State<PhotospotPhotosScreen> {
  List<PhotoInfo>? _photos;
  bool _loading = true;
  String? _error;

  String get _locationLabel =>
      (widget.placeName != null && widget.placeName!.isNotEmpty)
          ? '${widget.placeName} · ${widget.photoZoneName}'
          : widget.photoZoneName;

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
      final photos = await context
          .read<PhotoService>()
          .getPhotosByPhotoSpot(widget.photoSpotId);
      if (!mounted) return;
      setState(() => _photos = photos);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _resolveImageUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    if (url.startsWith('/')) return '${ApiClient.baseUrl}$url';
    return '${ApiClient.baseUrl}/$url';
  }

  void _openDetail(PhotoInfo photo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CommunityPostDetailScreen(
          photoId: photo.photoId,
          location: _locationLabel,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(widget.photoZoneName,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryPink))
          : _error != null
              ? _buildError()
              : _buildGrid(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_error!,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
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

  Widget _buildGrid() {
    final photos = _photos ?? [];
    if (photos.isEmpty) {
      return const Center(
        child: Text('아직 이 포토존에 올라온 사진이 없습니다.',
            style: TextStyle(color: AppColors.textMuted)),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: photos.length,
      itemBuilder: (context, i) {
        final photo = photos[i];
        return GestureDetector(
          onTap: () => _openDetail(photo),
          child: Image.network(
            _resolveImageUrl(photo.photoUrl),
            fit: BoxFit.cover,
            errorBuilder: (ctx, err, stack) =>
                Container(color: AppColors.illustrationBox),
          ),
        );
      },
    );
  }
}
