import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/app_theme.dart';
import 'place_provider.dart';
import 'widgets/info_tab.dart';
import 'widgets/photozone_tab.dart';
import 'widgets/review_tab.dart';

class PlaceDetailScreen extends StatelessWidget {
  final String placeId;
  const PlaceDetailScreen({super.key, required this.placeId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => PlaceProvider(placeId, ctx.read<ApiClient>()),
      child: const _PlaceDetailView(),
    );
  }
}

class _PlaceDetailView extends StatelessWidget {
  const _PlaceDetailView();

  @override
  Widget build(BuildContext context) {
    final detail = context.watch<PlaceProvider>().detail;
    if (detail == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverAppBar(
              expandedHeight: 260,
              pinned: true,
              foregroundColor: Colors.white,
              backgroundColor: AppColors.primaryPink,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Image.network(
                  detail.heroImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) =>
                      Container(color: AppColors.illustrationBox),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.favorite_border, color: Colors.white),
                  onPressed: () {},
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(detail.name,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    const Icon(Icons.star, size: 16, color: AppColors.primaryPink),
                    const SizedBox(width: 4),
                    Text(
                      '${detail.rating} (${detail.reviewCount})',
                      style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: TabBar(
                labelColor: AppColors.primaryPink,
                unselectedLabelColor: AppColors.textMuted,
                indicatorColor: AppColors.primaryPink,
                tabs: [
                  Tab(text: '포토존'),
                  Tab(text: '정보'),
                  Tab(text: '리뷰'),
                ],
              ),
            ),
          ],
          body: const TabBarView(
            children: [PhotozoneTab(), InfoTab(), ReviewTab()],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primaryPink),
                      foregroundColor: AppColors.primaryPink,
                    ),
                    child: const Text('저장'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPink,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('이렇게 찍어요'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
