import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/app_theme.dart';
import '../../core/network_thumb.dart';
import '../photo/ddaogi_camera_screen.dart';
import 'place_models.dart';
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

  // "이렇게 찍어요": 이 장소의 포토존 중 하나를 고른 뒤 그 포토존을 지정해
  // 가이드 카메라(촬영→선택→메타데이터→등록)로 진입한다.
  void _startDdaoggi(BuildContext context, List<PhotoZone> zones) {
    if (zones.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('등록된 포토존이 없습니다. 먼저 포토존을 등록해주세요.')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('어느 포토존에서 찍을까요?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 8),
                itemCount: zones.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: AppColors.divider),
                itemBuilder: (_, i) {
                  final zone = zones[i];
                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: NetworkThumb(
                        url: zone.imageUrl,
                        width: 44,
                        height: 44,
                        placeholderIcon: Icons.photo_camera_outlined,
                      ),
                    ),
                    title: Text(zone.name),
                    trailing: const Icon(Icons.chevron_right,
                        color: AppColors.textMuted),
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DdaogiCameraScreen(
                            photoZone: zone,
                            referencePhotoUrl: zone.imageUrl,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlaceProvider>();
    if (provider.error != null) {
      return Scaffold(
        body: Center(
          child: Text(provider.error!, style: const TextStyle(color: Colors.grey)),
        ),
      );
    }
    if (provider.detail == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final detail = provider.detail!;

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
                background: NetworkThumb(
                  url: detail.heroImageUrl,
                  fit: BoxFit.cover,
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    provider.isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: Colors.white,
                  ),
                  onPressed: () => context.read<PlaceProvider>().toggleSave(),
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
            child: ElevatedButton(
              onPressed: () => _startDdaoggi(context, detail.photoZones),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: AppColors.primaryPink,
                foregroundColor: Colors.white,
              ),
              child: const Text('이렇게 찍어요'),
            ),
          ),
        ),
      ),
    );
  }
}
