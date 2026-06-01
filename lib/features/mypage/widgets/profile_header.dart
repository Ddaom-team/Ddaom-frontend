import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../mypage_models.dart';
import '../profile_edit_screen.dart';

class ProfileHeader extends StatelessWidget {
  final UserProfile profile;
  const ProfileHeader({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: profile.avatarUrl != null
                ? NetworkImage(profile.avatarUrl!)
                : null,
            backgroundColor: AppColors.illustrationBox,
            child: profile.avatarUrl == null
                ? const Icon(Icons.person, size: 40, color: AppColors.textMuted)
                : null,
          ),
          const SizedBox(height: 12),
          Text(profile.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Stat(label: '팔로우', count: profile.followerCount),
              const SizedBox(width: 8),
              Container(width: 1, height: 14, color: AppColors.divider),
              const SizedBox(width: 8),
              _Stat(label: '팔로잉', count: profile.followingCount),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.divider),
              foregroundColor: AppColors.textMain,
              minimumSize: const Size(double.infinity, 36),
            ),
            child: const Text('프로필 편집', style: TextStyle(fontSize: 13)),
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
        Text('$count',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
      ],
    );
  }
}
