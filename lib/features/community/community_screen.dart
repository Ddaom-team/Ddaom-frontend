import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/app_theme.dart';
import '../../features/photo/photo_models.dart';
import '../../features/photo/photo_service.dart';
import 'community_models.dart';
import 'community_post_detail_screen.dart';
import 'community_service.dart';
import 'friend_profile_screen.dart';

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

  Future<void> _openFriendProfile(CommunityUser user) async {
    if (user.me) return;
    final newFollowing = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => FriendProfileScreen(user: user)),
    );
    if (!mounted || newFollowing == null) return;
    setState(() {
      _searchResults = _searchResults
          .map((item) => item.userId == user.userId
              ? item.copyWith(following: newFollowing)
              : item)
          .toList();
    });
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
              onTapUser: _openFriendProfile,
            )
          : TabBarView(
              controller: _tabController,
              children: const [
                _FollowingFeed(),
                _PopularFeed(),
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
  final ValueChanged<CommunityUser> onTapUser;

  const _UserSearchResults({
    required this.users,
    required this.loading,
    required this.error,
    required this.pendingFollowUserId,
    required this.onRetry,
    required this.onToggleFollow,
    required this.onTapUser,
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
          onTap: () => onTapUser(user),
        );
      },
    );
  }
}

class _UserSearchTile extends StatelessWidget {
  final CommunityUser user;
  final bool busy;
  final VoidCallback onToggleFollow;
  final VoidCallback? onTap;

  const _UserSearchTile({
    required this.user,
    required this.busy,
    required this.onToggleFollow,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: user.me ? null : onTap,
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

class _FollowingFeed extends StatefulWidget {
  const _FollowingFeed();

  @override
  State<_FollowingFeed> createState() => _FollowingFeedState();
}

class _FollowingFeedState extends State<_FollowingFeed>
    with AutomaticKeepAliveClientMixin {
  List<_CommunityPost> _posts = [];
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
      final photos = await context.read<CommunityService>().getFollowingFeed();
      if (!mounted) return;
      setState(() => _posts = photos.map(_fromPhoto).toList());
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e is ApiException ? e.message : '피드를 불러오지 못했습니다.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  _CommunityPost _fromPhoto(FollowingPhoto p) => _CommunityPost(
        photoId: p.photoId,
        id: 'api_${p.photoId}',
        imageUrl: _resolveUrl(p.photoUrl),
        authorName: p.nickname,
        authorAvatarUrl: p.profileImage ?? '',
        followerCount: 0,
        location: '',
        hashtags: [p.mood.label, p.timeTag.label],
        mood: p.mood,
        timeTag: p.timeTag,
        photoType: p.photoType,
        crowdLevel: p.crowdLevel,
        likeCount: p.likeCount,
        liked: p.liked,
      );

  String _resolveUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    if (url.startsWith('/')) return '${ApiClient.baseUrl}$url';
    return '${ApiClient.baseUrl}/$url';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryPink));
    }
    if (_error != null) {
      return _SearchEmptyState(
        icon: Icons.error_outline,
        title: _error!,
        actionLabel: '다시 시도',
        onAction: _load,
      );
    }
    if (_posts.isEmpty) {
      return const _SearchEmptyState(
        icon: Icons.photo_camera_outlined,
        title: '팔로우하는 사람들의 최근 사진이 없습니다.',
      );
    }
    return _PostGrid(posts: _posts);
  }
}

class _PopularFeed extends StatefulWidget {
  const _PopularFeed();

  @override
  State<_PopularFeed> createState() => _PopularFeedState();
}

class _PopularFeedState extends State<_PopularFeed>
    with AutomaticKeepAliveClientMixin {
  List<_CommunityPost> _posts = [];
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
      final photos = await context.read<PhotoService>().getTopPhotos();
      if (!mounted) return;
      setState(() => _posts = photos.map(_fromPhoto).toList());
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e is ApiException ? e.message : '인기 사진을 불러오지 못했습니다.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  _CommunityPost _fromPhoto(PhotoInfo p) {
    final url = p.photoUrl;
    final imageUrl = (url.startsWith('http://') || url.startsWith('https://'))
        ? url
        : '${ApiClient.baseUrl}$url';
    return _CommunityPost(
      photoId: p.photoId,
      id: 'top_${p.photoId}',
      imageUrl: imageUrl,
      authorName: '',
      authorAvatarUrl: '',
      followerCount: 0,
      location: '',
      hashtags: [p.mood.label, p.timeTag.label],
      mood: p.mood,
      timeTag: p.timeTag,
      photoType: p.photoType,
      crowdLevel: p.crowdLevel,
      likeCount: 0,
      liked: p.liked,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryPink));
    }
    if (_error != null) {
      return _SearchEmptyState(
        icon: Icons.error_outline,
        title: _error!,
        actionLabel: '다시 시도',
        onAction: _load,
      );
    }
    if (_posts.isEmpty) {
      return const _SearchEmptyState(
        icon: Icons.photo_camera_outlined,
        title: '인기 사진이 없습니다.',
      );
    }
    return _PostGrid(posts: _posts);
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
  bool _pending = false;

  @override
  void initState() {
    super.initState();
    _liked = widget.post.liked;
    _likeCount = widget.post.likeCount;
  }

  Future<void> _toggleLike() async {
    if (_pending) return;
    final wasLiked = _liked;
    final prevCount = _likeCount;
    setState(() {
      _pending = true;
      _liked = !wasLiked;
      _likeCount += _liked ? 1 : -1;
    });
    try {
      final service = context.read<PhotoService>();
      final result = wasLiked
          ? await service.unlikePhoto(widget.post.photoId)
          : await service.likePhoto(widget.post.photoId);
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
      if (mounted) setState(() => _pending = false);
    }
  }

  void _openDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CommunityPostDetailScreen(
          photoId: widget.post.photoId,
          authorName: widget.post.authorName,
          authorAvatarUrl: widget.post.authorAvatarUrl,
          followerCount: widget.post.followerCount,
          location: widget.post.location,
          hashtags: widget.post.hashtags,
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
                if (widget.post.authorName.isNotEmpty)
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
                            backgroundColor: AppColors.illustrationBox,
                            backgroundImage: widget.post.authorAvatarUrl.isNotEmpty
                                ? NetworkImage(widget.post.authorAvatarUrl)
                                : null,
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
                    child: Opacity(
                      opacity: _pending ? 0.6 : 1.0,
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
                ),
              ],
            ),
          ),
          if (widget.post.location.isNotEmpty || widget.post.hashtags.isNotEmpty)
            Container(
              color: AppColors.background,
              padding: const EdgeInsets.fromLTRB(4, 3, 4, 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.post.location.isNotEmpty)
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
                  if (widget.post.location.isNotEmpty && widget.post.hashtags.isNotEmpty)
                    const SizedBox(height: 1),
                  if (widget.post.hashtags.isNotEmpty)
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
