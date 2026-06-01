import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import 'widgets/filter_chip_bar.dart';
import 'widgets/home_map_view.dart';
import 'widgets/popular_zone_list.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '지금, 성수동은?',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        actions: [
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
            initialChildSize: 0.12,
            minChildSize: 0.08,
            maxChildSize: 0.55,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
