import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../features/photo/photo_models.dart';

class CommunityPostDetailScreen extends StatelessWidget {
  final String imageUrl;
  final String authorName;
  final String authorAvatarUrl;
  final int followerCount;
  final String location;
  final List<String> hashtags;
  final PhotoMood mood;
  final PhotoTimeTag timeTag;
  final PhotoType photoType;
  final CrowdLevel crowdLevel;

  const CommunityPostDetailScreen({
    super.key,
    required this.imageUrl,
    required this.authorName,
    required this.authorAvatarUrl,
    required this.followerCount,
    required this.location,
    required this.hashtags,
    required this.mood,
    required this.timeTag,
    required this.photoType,
    required this.crowdLevel,
  });

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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImage(),
                  _buildUserSection(),
                  _buildDivider(),
                  _buildLocationSection(),
                  _buildDivider(),
                  _buildTagsSection(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          _buildDdaoggiButton(context),
        ],
      ),
    );
  }

  Widget _buildImage() {
    return AspectRatio(
      aspectRatio: 1,
      child: Image.network(
        imageUrl,
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
            backgroundImage: NetworkImage(authorAvatarUrl),
            backgroundColor: AppColors.illustrationBox,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                authorName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '팔로워 ${_formatCount(followerCount)}명',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const Spacer(),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryPink,
              side: const BorderSide(color: AppColors.primaryPink),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              '팔로우',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
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
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: AppColors.primaryPink),
              const SizedBox(width: 4),
              Text(
                location,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain,
                ),
              ),
            ],
          ),
          if (hashtags.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              hashtags.map((t) => '#$t').join('  '),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.primaryPink,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTagsSection() {
    final categories = [
      ('분위기', mood.label),
      ('시간대', timeTag.label),
      ('사진 유형', photoType.label),
      ('혼잡도', crowdLevel.label),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '사진 정보',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories.map((entry) {
              final label = entry.$1;
              final value = entry.$2;
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
                        text: '$label  ',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                      TextSpan(
                        text: value,
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: const Text(
              '따오기',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
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