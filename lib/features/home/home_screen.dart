import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import 'home_provider.dart';
import '../search/search_screen.dart';
import '../place/place_search_screen.dart';
import 'widgets/filter_chip_bar.dart';
import 'widgets/home_map_view.dart';
import 'widgets/popular_zone_list.dart';
import 'widgets/region_picker_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showRegionPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<HomeProvider>(),
        child: const RegionPickerSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final regionLabel = context.select<HomeProvider, String>(
      (p) => p.selectedRegion.titleLabel,
    );

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => _showRegionPicker(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                regionLabel,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down, size: 20),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PlaceSearchScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Column(
            children: const [
              FilterChipBar(),
              Expanded(child: HomeMapView()),
            ],
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.32,
            minChildSize: 0.10,
            maxChildSize: 0.55,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromRGBO(0, 0, 0, 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: PopularZoneList(scrollController: scrollController),
              );
            },
          ),
        ],
      ),
    );
  }
}
