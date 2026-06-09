import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import 'mypage_provider.dart';
import '../../core/api_client.dart';
import '../user/user_search_sheet.dart';
import 'widgets/liked_zones_tab.dart';
import 'widgets/my_photos_tab.dart';
import 'widgets/profile_header.dart';
import 'widgets/saved_places_tab.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MyPageProvider>().loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MyPageProvider>();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          actions: [
            // TODO(test): remove – 유저 프로필 진입점 확정 후 제거
            IconButton(
              icon: const Icon(Icons.person_search_outlined),
              onPressed: () {
                final api = context.read<ApiClient>();
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  builder: (_) => UserSearchSheet(api: api),
                );
              },
            ),
            IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () {}),
            IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}),
          ],
        ),
        body: provider.loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryPink))
            : provider.profile == null
                ? _ErrorView(error: provider.error, onRetry: provider.loadProfile)
                : NestedScrollView(
                    headerSliverBuilder: (context, _) => [
                      SliverToBoxAdapter(child: ProfileHeader(profile: provider.profile!)),
                      const SliverPersistentHeader(
                        pinned: true,
                        delegate: _TabBarDelegate(),
                      ),
                    ],
                    body: const TabBarView(
                      children: [SavedPlacesTab(), MyPhotosTab(), LikedZonesTab()],
                    ),
                  ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String? error;
  final VoidCallback onRetry;
  const _ErrorView({this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(error ?? '불러오기 실패', style: const TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPink),
            child: const Text('다시 시도', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  const _TabBarDelegate();

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      child: const TabBar(
        labelColor: AppColors.primaryPink,
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor: AppColors.primaryPink,
        tabs: [
          Tab(text: '저장한 포토존'),
          Tab(text: '내가 올린 사진'),
          Tab(text: '좋아요'),
        ],
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
