import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/app_theme.dart';
import '../home_provider.dart';
import 'place_card.dart';

class PopularZoneList extends StatefulWidget {
  final ScrollController scrollController;

  const PopularZoneList({super.key, required this.scrollController});

  @override
  State<PopularZoneList> createState() => _PopularZoneListState();
}

class _PopularZoneListState extends State<PopularZoneList> {
  static const double _cardWidth = 140.0;
  static const double _cardSpacing = 12.0;

  final ScrollController _horizontalController = ScrollController();
  HomeProvider? _homeProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _homeProvider = context.read<HomeProvider>();
        _homeProvider!.addListener(_onProviderChanged);
      }
    });
  }

  @override
  void dispose() {
    _homeProvider?.removeListener(_onProviderChanged);
    _horizontalController.dispose();
    super.dispose();
  }

  void _onProviderChanged() {
    if (!mounted) return;
    final provider = context.read<HomeProvider>();
    final selectedId = provider.selectedPlaceId;
    if (selectedId == null) return;

    final places = provider.popularPlaces;
    final index = places.indexWhere((p) => p.id == selectedId);
    if (index < 0) return;

    if (!_horizontalController.hasClients) return;
    final offset = index * (_cardWidth + _cardSpacing);
    final maxOffset = _horizontalController.position.maxScrollExtent;

    _horizontalController.animateTo(
      offset.clamp(0.0, maxOffset),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HomeProvider>();
    final places = provider.popularPlaces;

    return ListView(
      controller: widget.scrollController,
      children: [
        Center(
          child: Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '지금 인기 있는 포토존 🔥',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.separated(
            controller: _horizontalController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: places.length,
            separatorBuilder: (_, i) => const SizedBox(width: _cardSpacing),
            itemBuilder: (context, i) => PlaceCard(
              place: places[i],
              // 카드 클릭 시 지도에서 해당 위치로 이동(선택)만. 상세 진입은 지도 핀 클릭으로.
              onTap: () => provider.selectPlace(places[i].id),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
