import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api_client.dart';
import '../../../core/app_theme.dart';
import '../../place/naver_place_search_service.dart';
import '../home_provider.dart';

class RegionPickerSheet extends StatefulWidget {
  const RegionPickerSheet({super.key});

  @override
  State<RegionPickerSheet> createState() => _RegionPickerSheetState();
}

class _RegionPickerSheetState extends State<RegionPickerSheet> {
  late final NaverPlaceSearchService _searchService =
      NaverPlaceSearchService(context.read<ApiClient>());

  String _query = '';
  List<NaverPlace> _results = [];
  bool _loading = false;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() => _query = value);
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _results = [];
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    _debounce =
        Timer(const Duration(milliseconds: 350), () => _search(value.trim()));
  }

  Future<void> _search(String query) async {
    final results = await _searchService.search(query);
    if (!mounted || query != _query.trim()) return;
    setState(() {
      _results = results;
      _loading = false;
    });
  }

  void _moveTo(double lat, double lng) {
    context.read<HomeProvider>().moveToLatLng(lat, lng);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDDDDD),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text('지역 선택',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '지역 검색 (예: 성수동, 간석역, 해운대)',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: _onQueryChanged,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(child: _buildBody()),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    // 검색어가 없으면 인기 지역 추천을 보여준다.
    if (_query.trim().isEmpty) {
      return ListView(
        shrinkWrap: true,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Text('인기 지역',
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600)),
          ),
          for (final region in Region.presets)
            ListTile(
              leading: const Icon(Icons.local_fire_department_outlined,
                  color: AppColors.primaryPink, size: 20),
              title: Text(region.name),
              onTap: () => _moveTo(region.lat, region.lng),
            ),
        ],
      );
    }

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_results.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text('검색 결과가 없습니다.',
              style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: _results.length,
      itemBuilder: (context, i) {
        final r = _results[i];
        return ListTile(
          leading: const Icon(Icons.location_on_outlined, size: 20),
          title: Text(r.name),
          subtitle: r.displayAddress.isNotEmpty
              ? Text(r.displayAddress,
                  maxLines: 1, overflow: TextOverflow.ellipsis)
              : null,
          onTap: () => _moveTo(r.lat, r.lng),
        );
      },
    );
  }
}
