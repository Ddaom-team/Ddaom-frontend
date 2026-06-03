// lib/features/user/user_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/app_theme.dart';
import 'follow_service.dart';

class UserProfileScreen extends StatefulWidget {
  final int userId;
  final String nickname;
  final String? profileImageUrl;

  const UserProfileScreen({
    super.key,
    required this.userId,
    required this.nickname,
    this.profileImageUrl,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late final FollowService _followService;
  FollowCounts? _counts;
  bool? _isFollowing;
  bool _actionLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _followService = FollowService(context.read<ApiClient>());
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _error = null);
    try {
      final counts = await _followService.getCounts(widget.userId);
      final following = await _followService.isFollowing(widget.userId);
      if (!mounted) return;
      setState(() {
        _counts = counts;
        _isFollowing = following;
      });
    } catch (_) {
      if (mounted) setState(() => _error = '정보를 불러오지 못했습니다.');
    }
  }

  Future<void> _onFollowTap() async {
    if (_isFollowing == null || _actionLoading) return;

    if (_isFollowing!) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('언팔로우'),
          content: Text('${widget.nickname}님을 언팔로우할까요?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('언팔로우', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() => _actionLoading = true);
    try {
      if (_isFollowing!) {
        await _followService.unfollow(widget.userId);
      } else {
        await _followService.follow(widget.userId);
      }
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('요청에 실패했습니다.')),
        );
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.nickname),
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          const SizedBox(height: 24),
          CircleAvatar(
            radius: 40,
            backgroundImage: widget.profileImageUrl != null
                ? NetworkImage(widget.profileImageUrl!)
                : null,
            child: widget.profileImageUrl == null
                ? const Icon(Icons.person, size: 40)
                : null,
          ),
          const SizedBox(height: 12),
          Text(widget.nickname,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                children: [
                  Text(_error!, style: const TextStyle(color: AppColors.textMuted)),
                  TextButton(onPressed: _load, child: const Text('다시 시도')),
                ],
              ),
            ),
          const SizedBox(height: 16),
          if (_counts != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CountCell(label: '팔로워', count: _counts!.followerCount),
                const SizedBox(width: 32),
                _CountCell(label: '팔로잉', count: _counts!.followingCount),
              ],
            ),
          const SizedBox(height: 20),
          if (_isFollowing != null)
            _actionLoading
                ? const SizedBox(
                    width: 140,
                    height: 40,
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
                : SizedBox(
                    width: 140,
                    height: 40,
                    child: _isFollowing!
                        ? OutlinedButton(
                            onPressed: _onFollowTap,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFCCCCCC)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('팔로잉',
                              style: TextStyle(color: Colors.black87)),
                          )
                        : ElevatedButton(
                            onPressed: _onFollowTap,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryPink,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('팔로우',
                              style: TextStyle(color: Colors.white)),
                          ),
                  ),
        ],
      ),
    );
  }
}

class _CountCell extends StatelessWidget {
  final String label;
  final int count;
  const _CountCell({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$count',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
      ],
    );
  }
}
