import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/app_theme.dart';
import '../home/home_models.dart';
import '../home/home_provider.dart';
import 'naver_place_search_service.dart';
import 'place_create_screen.dart';
import 'place_registration.dart';
import 'widgets/naver_place_info_card.dart';

class PlaceSearchScreen extends StatefulWidget {
  const PlaceSearchScreen({super.key});

  @override
  State<PlaceSearchScreen> createState() => _PlaceSearchScreenState();
}

class _PlaceSearchScreenState extends State<PlaceSearchScreen> {
  final _searchCtrl = TextEditingController();
  final _service = NaverPlaceSearchService();
  Timer? _debounce;
  NaverMapController? _mapController;
  List<NaverPlace> _results = [];
  bool _loading = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onQueryChanged(String q) {
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    _debounce =
        Timer(const Duration(milliseconds: 300), () => _search(q.trim()));
  }

  Future<void> _search(String q) async {
    setState(() => _loading = true);
    try {
      final results = await _service.search(q);
      if (!mounted) return;
      setState(() => _results = results);
      await _syncMarkers();
      if (results.isNotEmpty) {
        await _mapController?.updateCamera(
          NCameraUpdate.scrollAndZoomTo(
            target: NLatLng(results.first.lat, results.first.lng),
            zoom: 15,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _syncMarkers() async {
    final controller = _mapController;
    if (controller == null) return;
    await controller.clearOverlays(type: NOverlayType.marker);
    final markers = <NMarker>{};
    for (var i = 0; i < _results.length; i++) {
      final p = _results[i];
      final marker = NMarker(id: 'result_$i', position: NLatLng(p.lat, p.lng));
      marker.setOnTapListener((_) => _selectPlace(p));
      markers.add(marker);
    }
    if (markers.isNotEmpty) await controller.addOverlayAll(markers);
  }

  void _selectPlace(NaverPlace p) {
    _mapController?.updateCamera(
      NCameraUpdate.scrollAndZoomTo(target: NLatLng(p.lat, p.lng), zoom: 16),
    );
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => NaverPlaceInfoCard(
        place: p,
        onRegister: (category, address) {
          Navigator.pop(context);
          _register(p, category, address);
        },
      ),
    );
  }

  Future<void> _register(
      NaverPlace p, PlaceCategory category, String address) async {
    setState(() => _loading = true);
    try {
      final outcome = await registerNaverPlace(
        api: context.read<ApiClient>(),
        home: context.read<HomeProvider>(),
        place: p,
        category: category,
        address: address,
      );
      if (!mounted) return;
      if (outcome == RegisterOutcome.success) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('장소가 등록되었습니다.')));
        Navigator.pop(context);
      } else if (outcome == RegisterOutcome.duplicate) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('이미 등록된 장소입니다.')));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('장소 등록에 실패했습니다.')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('장소 검색'),
        backgroundColor: AppColors.background,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PlaceCreateScreen()),
            ),
            child: const Text('직접 입력',
                style: TextStyle(color: AppColors.primaryPink)),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              onChanged: _onQueryChanged,
              decoration: InputDecoration(
                hintText: '장소명 검색 (예: 어니언 성수)',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                NaverMap(
                  options: const NaverMapViewOptions(
                    initialCameraPosition: NCameraPosition(
                      target: NLatLng(37.5445, 127.0556),
                      zoom: 14,
                    ),
                  ),
                  onMapReady: (c) => _mapController = c,
                ),
                if (_loading)
                  const Align(
                    alignment: Alignment.topCenter,
                    child:
                        LinearProgressIndicator(color: AppColors.primaryPink),
                  ),
              ],
            ),
          ),
          if (_results.isNotEmpty)
            SizedBox(
              height: 180,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _results.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final p = _results[i];
                  return ListTile(
                    leading: const Icon(Icons.location_on_outlined,
                        color: AppColors.primaryPink),
                    title: Text(p.name,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text(p.displayAddress,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey)),
                    onTap: () => _selectPlace(p),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
