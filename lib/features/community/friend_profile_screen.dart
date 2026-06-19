import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/app_theme.dart';
import '../mypage/mypage_models.dart';
import '../mypage/mypage_provider.dart';
import '../mypage/widgets/photo_grid_tile.dart';
import '../photo/photo_models.dart';
import '../photo/photo_service.dart';
import '../user/follow_service.dart';
import 'community_models.dart';

class FriendProfileScreen extends StatefulWidget {
  final CommunityUser user;

  const FriendProfileScreen({super.key, required this.user});

  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen> {
  late final FollowService _followService;
  late bool _following;
  bool _followBusy = false;
  FollowCounts? _counts;

  @override
  void initState() {
    super.initState();
    _following = widget.user.following;
    _followService = FollowService(context.read<ApiClient>());
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    try {
      final counts = await _followService.getCounts(widget.user.userId);
      if (mounted) setState(() => _counts = counts);
    } catch (_) {}
  }

  Future<void> _toggleFollow() async {
    if (_followBusy) return;
    final previous = _following;
    final myPage = context.read<MyPageProvider>();

    setState(() {
      _followBusy = true;
      _following = !previous;
    });
    try {
      if (previous) {
        await _followService.unfollow(widget.user.userId);
      } else {
        await _followService.follow(widget.user.userId);
      }
      // 팔로워/팔로잉 카운트 갱신
      await Future.wait([_loadCounts(), myPage.loadProfile()]);
    } catch (e) {
      if (!mounted) return;
      setState(() => _following = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e is ApiException ? e.message : '요청을 처리하지 못했습니다.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _followBusy = false);
    }
  }

  void _pop() => Navigator.pop(context, _following);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 1,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _pop();
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textMain),
              onPressed: _pop,
            ),
            title: Text(
              widget.user.nickname,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain,
              ),
            ),
            centerTitle: true,
          ),
          body: NestedScrollView(
            headerSliverBuilder: (context, _) => [
              SliverToBoxAdapter(
                child: _FriendProfileHeader(
                  user: widget.user,
                  counts: _counts,
                  following: _following,
                  busy: _followBusy,
                  onToggleFollow: _toggleFollow,
                ),
              ),
              const SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(),
              ),
            ],
            body: _FriendPhotosTab(user: widget.user),
          ),
        ),
      ),
    );
  }
}

class _FriendProfileHeader extends StatelessWidget {
  final CommunityUser user;
  final FollowCounts? counts;
  final bool following;
  final bool busy;
  final VoidCallback onToggleFollow;

  const _FriendProfileHeader({
    required this.user,
    required this.counts,
    required this.following,
    required this.busy,
    required this.onToggleFollow,
  });

  String _resolveUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    if (url.startsWith('/')) return '${ApiClient.baseUrl}$url';
    return '${ApiClient.baseUrl}/$url';
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = user.profileImage;
    final initial = user.nickname.isNotEmpty ? user.nickname[0] : '?';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.illustrationBox,
            backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                ? NetworkImage(_resolveUrl(imageUrl))
                : null,
            child: imageUrl == null || imageUrl.isEmpty
                ? Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 30,
                      color: AppColors.primaryPink,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            user.nickname,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          counts == null
              ? const SizedBox(
                  height: 36,
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
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Stat(label: '팔로워', count: counts!.followerCount),
                    const SizedBox(width: 8),
                    Container(width: 1, height: 14, color: AppColors.divider),
                    const SizedBox(width: 8),
                    _Stat(label: '팔로잉', count: counts!.followingCount),
                  ],
                ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: FilledButton(
              onPressed: busy ? null : onToggleFollow,
              style: FilledButton.styleFrom(
                backgroundColor:
                    following ? AppColors.navBar : AppColors.primaryPink,
                foregroundColor:
                    following ? AppColors.textMain : Colors.white,
                disabledBackgroundColor: AppColors.navBar,
                disabledForegroundColor: AppColors.textMuted,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textMuted,
                      ),
                    )
                  : Text(
                      following ? '팔로잉' : '팔로우',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final int count;

  const _Stat({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$count',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  const _TabBarDelegate();

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      child: const TabBar(
        labelColor: AppColors.primaryPink,
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor: AppColors.primaryPink,
        tabs: [Tab(text: '올린 사진')],
      ),
    );
  }

  @override
  double get maxExtent => 48;

  @override
  double get minExtent => 48;

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}

class _FriendPhotosTab extends StatefulWidget {
  final CommunityUser user;

  const _FriendPhotosTab({required this.user});

  @override
  State<_FriendPhotosTab> createState() => _FriendPhotosTabState();
}

class _FriendPhotosTabState extends State<_FriendPhotosTab> {
  List<GridPhoto>? _photos;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  GridPhoto _toGridPhoto(PhotoInfo photo) {
    final url = photo.photoUrl;
    final imageUrl = (url.startsWith('http://') || url.startsWith('https://'))
        ? url
        : '${ApiClient.baseUrl}$url';
    return GridPhoto(
      photoId: photo.photoId,
      id: 'photo_${photo.photoId}',
      imageUrl: imageUrl,
      authorName: widget.user.nickname,
      authorAvatarUrl: widget.user.profileImage ?? '',
      location: (photo.placeName != null && photo.photoSpotTitle != null)
          ? '${photo.placeName} · ${photo.photoSpotTitle}'
          : photo.placeName ?? photo.photoSpotTitle ?? '',
      hashtags: [photo.mood.label, photo.timeTag.label],
      likeCount: photo.likeCount,
      liked: photo.liked,
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final photos =
          await context.read<PhotoService>().getUserPhotos(widget.user.userId);
      if (!mounted) return;
      setState(() => _photos = photos.map((p) => _toGridPhoto(p)).toList());
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '사진을 불러오지 못했습니다.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryPink),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPink),
              child:
                  const Text('다시 시도', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
    final photos = _photos ?? [];
    if (photos.isEmpty) {
      return const Center(
        child: Text(
          '아직 올린 사진이 없습니다.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 14),
        ),
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
      itemBuilder: (context, i) =>
          PhotoGridTile(photo: photos[i], showAuthor: false),
    );
  }
}