import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/app_theme.dart';
import 'user_profile_screen.dart';

class UserSearchSheet extends StatefulWidget {
  final ApiClient api;

  const UserSearchSheet({super.key, required this.api});

  @override
  State<UserSearchSheet> createState() => _UserSearchSheetState();
}

class _UserSearchSheetState extends State<UserSearchSheet> {
  final _ctrl = TextEditingController();
  Timer? _timer;
  List<_UserResult> _results = [];
  bool _loading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _onChanged(String q) {
    _timer?.cancel();
    if (q.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    _timer = Timer(const Duration(milliseconds: 300), () => _search(q.trim()));
  }

  Future<void> _search(String q) async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final res = await widget.api.dio.get(
        '/api/users/search',
        queryParameters: {'query': q},
      );
      if (!mounted) return;
      final list = res.data as List<dynamic>;
      setState(() {
        _results = list
            .map((e) => _UserResult.fromJson(e as Map<String, dynamic>))
            .where((u) => !u.me)
            .toList();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _results = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onTap(_UserResult user) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(
          userId: user.userId,
          nickname: user.nickname,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          const Text('유저 검색', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            autofocus: true,
            onChanged: _onChanged,
            decoration: InputDecoration(
              hintText: '닉네임 또는 이메일 검색',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: AppColors.primaryPink),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: _results.isEmpty && _ctrl.text.isNotEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('검색 결과가 없습니다', style: TextStyle(color: Colors.grey)),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: _results.length,
                      separatorBuilder: (context, i) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final u = _results[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryPink.withValues(alpha: 0.15),
                            child: Text(
                              u.nickname.isNotEmpty ? u.nickname[0] : '?',
                              style: const TextStyle(color: AppColors.primaryPink),
                            ),
                          ),
                          title: Text(u.nickname),
                          subtitle: Text(u.email, style: const TextStyle(fontSize: 12)),
                          onTap: () => _onTap(u),
                        );
                      },
                    ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _UserResult {
  final int userId;
  final String nickname;
  final String email;
  final bool me;

  const _UserResult({
    required this.userId,
    required this.nickname,
    required this.email,
    required this.me,
  });

  factory _UserResult.fromJson(Map<String, dynamic> json) => _UserResult(
        userId: (json['userId'] as num).toInt(),
        nickname: json['nickname'] as String? ?? '',
        email: json['email'] as String? ?? '',
        me: json['me'] as bool? ?? false,
      );
}
