import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/app_theme.dart';
import '../../features/photo/photo_models.dart';
import '../../features/photo/photo_service.dart';

class CommunityPostDetailScreen extends StatefulWidget {
  final int photoId;
  final String? authorName;
  final String? authorAvatarUrl;
  final int? followerCount;
  final String? location;
  final List<String> hashtags;

  const CommunityPostDetailScreen({
    super.key,
    required this.photoId,
    this.authorName,
    this.authorAvatarUrl,
    this.followerCount,
    this.location,
    this.hashtags = const [],
  });

  @override
  State<CommunityPostDetailScreen> createState() => _CommunityPostDetailScreenState();
}

class _CommunityPostDetailScreenState extends State<CommunityPostDetailScreen> {
  PhotoInfo? _photo;
  bool _loading = true;
  String? _error;

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
      final photo = await context.read<PhotoService>().getPhoto(widget.photoId);
      if (!mounted) return;
      setState(() => _photo = photo);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryPink))
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
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

  Widget _buildContent() {
    final photo = _photo!;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImage(photo.photoUrl),
                if (widget.authorName != null) ...[
                  _buildUserSection(),
                  _buildDivider(),
                ],
                if (widget.location != null) ...[
                  _buildLocationSection(),
                  _buildDivider(),
                ],
                if (photo.tip != null && photo.tip!.isNotEmpty) ...[
                  _buildTipSection(photo.tip!),
                  _buildDivider(),
                ],
                _buildTagsSection(photo),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        _buildDdaoggiButton(context),
      ],
    );
  }

  Widget _buildImage(String photoUrl) {
    return AspectRatio(
      aspectRatio: 1,
      child: Image.network(
        _resolveImageUrl(photoUrl),
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) =>
            Container(color: AppColors.illustrationBox),
      ),
    );
  }

  Widget _buildUserSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundImage: NetworkImage(widget.authorAvatarUrl!),
            backgroundColor: AppColors.illustrationBox,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.authorName!,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain,
                ),
              ),
              if (widget.followerCount != null) ...[
                const SizedBox(height: 2),
                Text(
                  '팔로워 ${_formatCount(widget.followerCount!)}명',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ],
          ),
          const Spacer(),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryPink,
              side: const BorderSide(color: AppColors.primaryPink),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('팔로우', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '촬영 장소',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: AppColors.primaryPink),
              const SizedBox(width: 4),
              Text(
                widget.location!,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textMain),
              ),
            ],
          ),
          if (widget.hashtags.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              widget.hashtags.map((t) => '#$t').join('  '),
              style: const TextStyle(fontSize: 13, color: AppColors.primaryPink),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTipSection(String tip) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '촬영 팁',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          Text(
            tip,
            style: const TextStyle(fontSize: 14, color: AppColors.textMain, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection(PhotoInfo photo) {
    final categories = [
      ('분위기', photo.mood.label),
      ('시간대', photo.timeTag.label),
      ('사진 유형', photo.photoType.label),
      ('혼잡도', photo.crowdLevel.label),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '사진 정보',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories.map((entry) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.illustrationBox,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${entry.$1}  ',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                      TextSpan(
                        text: entry.$2,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMain,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0));
  }

  Widget _buildDdaoggiButton(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPink,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: const Text(
              '따오기',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 10000) return '${(count / 10000).toStringAsFixed(1)}만';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}천';
    return count.toString();
  }
}