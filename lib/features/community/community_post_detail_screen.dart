import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/app_theme.dart';
import '../../features/photo/photo_models.dart';
import '../../features/photo/photo_service.dart';
import '../mypage/mypage_models.dart';
import '../mypage/mypage_provider.dart';
import '../photo/ddaogi_camera_screen.dart';
import '../user/follow_service.dart';
import '../user/user_service.dart';

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
  UserProfile? _author;
  bool _loading = true;
  String? _error;

  late bool _liked;
  late int _likeCount;
  bool _likePending = false;

  bool? _following;
  bool _followBusy = false;

  bool _isMe = false;
  bool _deletePending = false;

  @override
  void initState() {
    super.initState();
    _liked = false;
    _likeCount = 0;
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
      setState(() {
        _photo = photo;
        _liked = photo.liked;
        _likeCount = photo.likeCount;
      });
      _loadAuthor(photo.userId);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadAuthor(int userId) async {
    final api = context.read<ApiClient>();
    final followService = FollowService(api);
    try {
      final results = await Future.wait([
        UserService(api).getUserProfile(userId),
        followService.isFollowing(userId),
      ]);
      if (!mounted) return;
      final author = results[0] as UserProfile;
      final myUserId = context.read<MyPageProvider>().profile?.userId;
      setState(() {
        _author = author;
        _following = results[1] as bool;
        _isMe = myUserId != null && myUserId == author.userId;
      });
    } catch (_) {}
  }

  Future<void> _deletePhoto() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('사진 삭제'),
        content: const Text('이 사진을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deletePending = true);
    try {
      await context.read<PhotoService>().deletePhoto(widget.photoId);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('삭제에 실패했습니다. 다시 시도해주세요.')),
        );
        setState(() => _deletePending = false);
      }
    }
  }

  Future<void> _toggleFollow() async {
    if (_followBusy || _author == null) return;
    final wasFollowing = _following ?? false;
    setState(() {
      _followBusy = true;
      _following = !wasFollowing;
    });
    try {
      final followService = FollowService(context.read<ApiClient>());
      if (wasFollowing) {
        await followService.unfollow(_author!.userId);
      } else {
        await followService.follow(_author!.userId);
      }
    } catch (_) {
      if (mounted) setState(() => _following = wasFollowing);
    } finally {
      if (mounted) setState(() => _followBusy = false);
    }
  }

  Future<void> _toggleLike() async {
    if (_likePending) return;
    final wasLiked = _liked;
    final prevCount = _likeCount;
    setState(() {
      _likePending = true;
      _liked = !wasLiked;
      _likeCount += _liked ? 1 : -1;
    });
    try {
      final service = context.read<PhotoService>();
      final result = wasLiked
          ? await service.unlikePhoto(widget.photoId)
          : await service.likePhoto(widget.photoId);
      if (mounted) {
        setState(() {
          _liked = result.liked;
          _likeCount = result.likeCount;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _liked = wasLiked;
          _likeCount = prevCount;
        });
      }
    } finally {
      if (mounted) setState(() => _likePending = false);
    }
  }

  String _resolveImageUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    if (url.startsWith('/')) return '${ApiClient.baseUrl}$url';
    return '${ApiClient.baseUrl}/$url';
  }

  /// 표시할 촬영 장소 라벨. 호출처가 명시한 location을 우선하고,
  /// 없으면 사진 응답의 placeName·photoSpotTitle로 '장소명 · 포토존명'을 만든다.
  String? get _effectiveLocation {
    if (widget.location != null && widget.location!.isNotEmpty) {
      return widget.location;
    }
    final photo = _photo;
    if (photo == null) return null;
    final place = photo.placeName;
    final spot = photo.photoSpotTitle;
    final hasPlace = place != null && place.isNotEmpty;
    final hasSpot = spot != null && spot.isNotEmpty;
    if (hasPlace && hasSpot) return '$place · $spot';
    if (hasPlace) return place;
    if (hasSpot) return spot;
    return null;
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
        actions: [
          if (_isMe)
            IconButton(
              icon: _deletePending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textMuted,
                      ),
                    )
                  : const Icon(Icons.delete_outline, color: AppColors.textMuted),
              onPressed: _deletePending ? null : _deletePhoto,
            ),
        ],
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
    final location = _effectiveLocation;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImage(photo.photoUrl),
                _buildLikeBar(),
                _buildDivider(),
                _buildUserSection(),
                _buildDivider(),
                if (location != null) ...[
                  _buildLocationSection(location),
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

  Widget _buildLikeBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: _toggleLike,
            child: Opacity(
              opacity: _likePending ? 0.6 : 1.0,
              child: Row(
                children: [
                  Icon(
                    _liked ? Icons.favorite : Icons.favorite_border,
                    color: _liked ? const Color(0xFFFF6B9D) : AppColors.textMuted,
                    size: 26,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$_likeCount',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMain,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserSection() {
    final avatarUrl = _author?.avatarUrl;
    final name = _author?.name ?? widget.authorName;
    final followerCount = _author?.followerCount ?? widget.followerCount;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundImage: (avatarUrl?.isNotEmpty ?? false)
                ? NetworkImage(_resolveImageUrl(avatarUrl!))
                : null,
            backgroundColor: AppColors.illustrationBox,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (name != null)
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                )
              else
                Container(
                  width: 80,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.illustrationBox,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              const SizedBox(height: 2),
              if (followerCount != null)
                Text(
                  '팔로워 ${_formatCount(followerCount)}명',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                )
              else
                Container(
                  width: 60,
                  height: 11,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: AppColors.illustrationBox,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ],
          ),
          const Spacer(),
          if (!_isMe)
            _following == null
                ? const SizedBox(
                    width: 72,
                    height: 32,
                    child: Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryPink,
                        ),
                      ),
                    ),
                  )
                : FilledButton(
                    onPressed: _followBusy ? null : _toggleFollow,
                    style: FilledButton.styleFrom(
                      backgroundColor: _following!
                          ? AppColors.illustrationBox
                          : AppColors.primaryPink,
                      foregroundColor: _following!
                          ? AppColors.textMain
                          : Colors.white,
                      disabledBackgroundColor: AppColors.illustrationBox,
                      disabledForegroundColor: AppColors.textMuted,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      _following! ? '팔로잉' : '팔로우',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
        ],
      ),
    );
  }

  Widget _buildLocationSection(String location) {
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
                location,
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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DdaogiCameraScreen(
                    referencePhotoUrl: _photo != null
                        ? _resolveImageUrl(_photo!.photoUrl)
                        : null,
                    photoType: _photo?.photoType,
                  ),
                ),
              );
            },
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
