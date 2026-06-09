import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/app_theme.dart';
import '../../features/photo/photo_models.dart';
import 'community_models.dart';
import 'community_post_detail_screen.dart';
import 'community_service.dart';

class _CommunityPost {
  final int photoId;
  final String id;
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
  final int likeCount;
  final bool liked;

  const _CommunityPost({
    required this.photoId,
    required this.id,
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
    required this.likeCount,
    this.liked = false,
  });
}

List<_CommunityPost> _followingMock() {
  final names = ['지윤', '민서', '하린', '서아', '예린', '도현', '채원', '준호', '하아', '서영', '유나', '현우'];
  final locations = ['경복궁', '북촌한옥마을', '성수동', '홍대거리', '한강공원', '망원시장'];
  final tagSets = [
    ['포토존', '서울여행'],
    ['한옥', '데이트'],
    ['카페거리', '스냅'],
    ['감성사진', '홍대'],
    ['한강', '빈티지'],
    ['시장', '필름'],
  ];
  final moods = [PhotoMood.ROMANTIC, PhotoMood.COZY, PhotoMood.EMOTIONAL, PhotoMood.DREAMY, PhotoMood.VINTAGE, PhotoMood.FRESH];
  final times = [PhotoTimeTag.AFTERNOON, PhotoTimeTag.SUNSET, PhotoTimeTag.MORNING, PhotoTimeTag.NIGHT, PhotoTimeTag.AFTERNOON, PhotoTimeTag.SUNSET];
  final types = [PhotoType.FULL_BODY, PhotoType.SELFIE, PhotoType.UPPER_BODY, PhotoType.LANDSCAPE, PhotoType.FULL_BODY, PhotoType.SELFIE];
  final crowds = [CrowdLevel.NORMAL, CrowdLevel.RELAXED, CrowdLevel.CROWDED, CrowdLevel.NORMAL, CrowdLevel.RELAXED, CrowdLevel.NORMAL];
  final followers = [1240, 3870, 520, 9100, 280, 6430, 1100, 4200, 760, 18500, 390, 2200];

  final likeCounts = [12, 34, 7, 58, 3, 21, 9, 45, 16, 82, 5, 27];

  return List.generate(12, (i) => _CommunityPost(
    photoId: i + 1,
    id: 'f$i',
    imageUrl: 'https://picsum.photos/seed/follow$i/400/400',
    authorName: names[i % names.length],
    authorAvatarUrl: 'https://picsum.photos/seed/avatar$i/100/100',
    followerCount: followers[i % followers.length],
    location: locations[i % locations.length],
    hashtags: tagSets[i % tagSets.length],
    mood: moods[i % moods.length],
    timeTag: times[i % times.length],
    photoType: types[i % types.length],
    crowdLevel: crowds[i % crowds.length],
    likeCount: likeCounts[i % likeCounts.length],
  ));
}

List<_CommunityPost> _popularMock() {
  final names = ['인기작가1', '스냅유저', '트렌드세터', '베스트컷', '핫픽커'];
  final locations = ['남산타워', '광화문', '동대문DDP', '서울숲', '인사동', '창덕궁'];
  final tagSets = [
    ['남산', '서울야경'],
    ['광화문', '야간'],
    ['DDP', '건축'],
    ['서울숲', '벚꽃'],
    ['인사동', '전통'],
    ['창덕궁', '궁궐'],
  ];
  final moods = [PhotoMood.CINEMATIC, PhotoMood.MODERN, PhotoMood.NIGHT, PhotoMood.BRIGHT, PhotoMood.NOSTALGIC, PhotoMood.QUIET];
  final times = [PhotoTimeTag.NIGHT, PhotoTimeTag.AFTERNOON, PhotoTimeTag.SUNSET, PhotoTimeTag.MORNING, PhotoTimeTag.AFTERNOON, PhotoTimeTag.SUNSET];
  final types = [PhotoType.LANDSCAPE, PhotoType.FULL_BODY, PhotoType.LANDSCAPE, PhotoType.SELFIE, PhotoType.UPPER_BODY, PhotoType.LANDSCAPE];
  final crowds = [CrowdLevel.CROWDED, CrowdLevel.NORMAL, CrowdLevel.HARD_TO_SHOOT, CrowdLevel.RELAXED, CrowdLevel.NORMAL, CrowdLevel.CROWDED];
  final followers = [52000, 13400, 87000, 29000, 6700, 41000];

  final likeCounts = [143, 89, 312, 57, 204, 76, 445, 33, 167, 520, 91, 238];

  return List.generate(12, (i) => _CommunityPost(
    photoId: i + 101,
    id: 'p$i',
    imageUrl: 'https://picsum.photos/seed/popular$i/400/400',
    authorName: names[i % names.length],
    authorAvatarUrl: 'https://picsum.photos/seed/pavatar$i/100/100',
    followerCount: followers[i % followers.length],
    location: locations[i % locations.length],
    hashtags: tagSets[i % tagSets.length],
    mood: moods[i % moods.length],
    timeTag: times[i % times.length],
    photoType: types[i % types.length],
    crowdLevel: crowds[i % crowds.length],
    likeCount: likeCounts[i % likeCounts.length],
  ));
}

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _query = '';
  List<CommunityUser> _searchResults = [];
  bool _searching = false;
  String? _searchError;
  int? _pendingFollowUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    final query = value.trim();
    setState(() {
      _query = query;
      _searchError = null;
    });
    _searchDebounce?.cancel();

    if (query.isEmpty) {
      setState(() {
        _searching = false;
        _searchResults = [];
      });
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _searchUsers(query);
    });
  }

  Future<void> _searchUsers(String query) async {
    setState(() {
      _searching = true;
      _searchError = null;
    });
    try {
      final users = await context.read<CommunityService>().searchUsers(query);
      if (!mounted || _query != query) return;
      setState(() => _searchResults = users);
    } catch (e) {
      if (!mounted || _query != query) return;
      setState(() => _searchError = _messageFromError(e));
    } finally {
      if (!mounted || _query != query) return;
      setState(() => _searching = false);
    }
  }

  Future<void> _toggleFollow(CommunityUser user) async {
    if (user.me || _pendingFollowUserId != null) return;
    final previous = user.following;
    setState(() {
      _pendingFollowUserId = user.userId;
      _searchResults = _searchResults
          .map((item) => item.userId == user.userId
              ? item.copyWith(following: !previous)
              : item)
          .toList();
    });

    try {
      final service = context.read<CommunityService>();
      if (previous) {
        await service.unfollow(user.userId);
      } else {
        await service.follow(user.userId);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searchResults = _searchResults
            .map((item) => item.userId == user.userId
                ? item.copyWith(following: previous)
                : item)
            .toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_messageFromError(e))),
      );
    } finally {
      if (!mounted) return;
      setState(() => _pendingFollowUserId = null);
    }
  }

  String _messageFromError(Object error) {
    if (error is ApiException) return error.message;
    return '요청을 처리하지 못했습니다.';
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() {
      _query = '';
      _searching = false;
      _searchError = null;
      _searchResults = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSearchingUsers = _query.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navBar,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          '커뮤니티',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textMain,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(isSearchingUsers ? 62 : 104),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: '친구를 검색하세요',
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppColors.textMuted),
                            onPressed: _clearSearch,
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFE8E8E8),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              if (!isSearchingUsers)
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primaryPink,
                  unselectedLabelColor: AppColors.textMuted,
                  indicatorColor: AppColors.primaryPink,
                  indicatorWeight: 2,
                  labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  unselectedLabelStyle: const TextStyle(fontSize: 14),
                  tabs: const [
                    Tab(text: '팔로잉'),
                    Tab(text: '인기'),
                  ],
                ),
            ],
          ),
        ),
      ),
      body: isSearchingUsers
          ? _UserSearchResults(
              users: _searchResults,
              loading: _searching,
              error: _searchError,
              pendingFollowUserId: _pendingFollowUserId,
              onRetry: () => _searchUsers(_query),
              onToggleFollow: _toggleFollow,
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _PostGrid(posts: _followingMock()),
                _PostGrid(posts: _popularMock()),
              ],
            ),
    );
  }
}

class _UserSearchResults extends StatelessWidget {
  final List<CommunityUser> users;
  final bool loading;
  final String? error;
  final int? pendingFollowUserId;
  final VoidCallback onRetry;
  final ValueChanged<CommunityUser> onToggleFollow;

  const _UserSearchResults({
    required this.users,
    required this.loading,
    required this.error,
    required this.pendingFollowUserId,
    required this.onRetry,
    required this.onToggleFollow,
  });

  @override
  Widget build(BuildContext context) {
    if (loading && users.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryPink),
      );
    }
    if (error != null && users.isEmpty) {
      return _SearchEmptyState(
        icon: Icons.error_outline,
        title: error!,
        actionLabel: '다시 시도',
        onAction: onRetry,
      );
    }
    if (users.isEmpty) {
      return const _SearchEmptyState(
        icon: Icons.person_search,
        title: '검색 결과가 없습니다.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: users.length + (loading ? 1 : 0),
      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
      itemBuilder: (context, index) {
        if (index == users.length) {
          return const LinearProgressIndicator(
            minHeight: 2,
            color: AppColors.primaryPink,
            backgroundColor: AppColors.illustrationBox,
          );
        }
        final user = users[index];
        return _UserSearchTile(
          user: user,
          busy: pendingFollowUserId == user.userId,
          onToggleFollow: () => onToggleFollow(user),
        );
      },
    );
  }
}

class _UserSearchTile extends StatelessWidget {
  final CommunityUser user;
  final bool busy;
  final VoidCallback onToggleFollow;

  const _UserSearchTile({
    required this.user,
    required this.busy,
    required this.onToggleFollow,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minVerticalPadding: 12,
      leading: _UserAvatar(imageUrl: user.profileImage, name: user.nickname),
      title: Row(
        children: [
          Expanded(
            child: Text(
              user.nickname,
              style: const TextStyle(
                color: AppColors.textMain,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (user.me)
            const Padding(
              padding: EdgeInsets.only(left: 6),
              child: Text(
                '나',
                style: TextStyle(
                  color: AppColors.primaryPink,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(
        user.email,
        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: user.me
          ? null
          : SizedBox(
              width: 84,
              height: 36,
              child: FilledButton(
                onPressed: busy ? null : onToggleFollow,
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: user.following
                      ? AppColors.navBar
                      : AppColors.primaryPink,
                  foregroundColor: user.following
                      ? AppColors.textMain
                      : Colors.white,
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
                    : Text(user.following ? '팔로잉' : '팔로우'),
              ),
            ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;

  const _UserAvatar({required this.imageUrl, required this.name});

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url == null || url.isEmpty) {
      return _InitialAvatar(name: name);
    }
    return CircleAvatar(
      radius: 24,
      backgroundColor: AppColors.illustrationBox,
      backgroundImage: NetworkImage(_resolveImageUrl(url)),
      onBackgroundImageError: (_, __) {},
    );
  }

  String _resolveImageUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    if (url.startsWith('/')) return '${ApiClient.baseUrl}$url';
    return '${ApiClient.baseUrl}/$url';
  }
}

class _InitialAvatar extends StatelessWidget {
  final String name;

  const _InitialAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim().characters.first;
    return CircleAvatar(
      radius: 24,
      backgroundColor: AppColors.illustrationBox,
      child: Text(
        initial,
        style: const TextStyle(
          color: AppColors.primaryPink,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SearchEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SearchEmptyState({
    required this.icon,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PostGrid extends StatelessWidget {
  final List<_CommunityPost> posts;

  const _PostGrid({required this.posts});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 0.72,
      ),
      itemCount: posts.length,
      itemBuilder: (context, i) => _PostTile(post: posts[i]),
    );
  }
}

class _PostTile extends StatefulWidget {
  final _CommunityPost post;

  const _PostTile({required this.post});

  @override
  State<_PostTile> createState() => _PostTileState();
}

class _PostTileState extends State<_PostTile> {
  late bool _liked;
  late int _likeCount;
  bool _likeLoading = false;

  @override
  void initState() {
    super.initState();
    _liked = widget.post.liked;
    _likeCount = widget.post.likeCount;
  }

  Future<void> _toggleLike() async {
    if (_likeLoading) return;
    final wasLiked = _liked;
    setState(() {
      _liked = !wasLiked;
      _likeCount += wasLiked ? -1 : 1;
      _likeLoading = true;
    });

    try {
      final service = context.read<CommunityService>();
      final result = wasLiked
          ? await service.unlikePhoto(widget.post.photoId)
          : await service.likePhoto(widget.post.photoId);
      if (mounted) {
        setState(() {
          _liked = result['liked'] as bool;
          _likeCount = (result['likeCount'] as num).toInt();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _liked = wasLiked;
          _likeCount += wasLiked ? 1 : -1;
        });
      }
    } finally {
      if (mounted) setState(() => _likeLoading = false);
    }
  }

  void _openDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CommunityPostDetailScreen(
          imageUrl: widget.post.imageUrl,
          authorName: widget.post.authorName,
          authorAvatarUrl: widget.post.authorAvatarUrl,
          followerCount: widget.post.followerCount,
          location: widget.post.location,
          hashtags: widget.post.hashtags,
          mood: widget.post.mood,
          timeTag: widget.post.timeTag,
          photoType: widget.post.photoType,
          crowdLevel: widget.post.crowdLevel,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  widget.post.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) =>
                      Container(color: AppColors.illustrationBox),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Color(0xBB000000), Colors.transparent],
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 7,
                          backgroundImage: NetworkImage(widget.post.authorAvatarUrl),
                          backgroundColor: AppColors.illustrationBox,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            widget.post.authorName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: _toggleLike,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _liked ? Icons.favorite : Icons.favorite_border,
                            color: _liked ? const Color(0xFFFF6B9D) : Colors.white,
                            size: 11,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '$_likeCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: AppColors.background,
            padding: const EdgeInsets.fromLTRB(4, 3, 4, 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 9, color: AppColors.primaryPink),
                    const SizedBox(width: 1),
                    Expanded(
                      child: Text(
                        widget.post.location,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMain,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  widget.post.hashtags.map((t) => '#$t').join(' '),
                  style: const TextStyle(
                    fontSize: 8,
                    color: AppColors.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
