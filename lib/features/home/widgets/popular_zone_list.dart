import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/app_theme.dart';
import '../home_provider.dart';
import 'place_card.dart';

// TODO: PlaceDetailScreen 구현 후 import 추가
// import '../place_detail/place_detail_screen.dart';

class PopularZoneList extends StatelessWidget {
  final ScrollController scrollController;

  const PopularZoneList({super.key, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    final places = context.watch<HomeProvider>().filteredPlaces;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
            controller: scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: places.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, i) => PlaceCard(
              place: places[i],
              onTap: () {
                // TODO: PlaceDetailScreen 구현 후 Navigator.push로 교체
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(places[i].name)),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
