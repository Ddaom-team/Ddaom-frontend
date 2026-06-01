import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:provider/provider.dart';

import '../../../core/app_theme.dart';
import '../home_provider.dart';

class HomeMapView extends StatefulWidget {
  const HomeMapView({super.key});

  @override
  State<HomeMapView> createState() => _HomeMapViewState();
}

class _HomeMapViewState extends State<HomeMapView> {
  NaverMapController? _controller;
  final Map<String, NMarker> _markers = {};
  NInfoWindow? _activeInfoWindow;
  String? _lastSelectedId;
  bool _errorShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<HomeProvider>().addListener(_checkError);
    });
  }

  @override
  void dispose() {
    context.read<HomeProvider>().removeListener(_checkError);
    super.dispose();
  }

  void _checkError() {
    if (!mounted) return;
    final error = context.read<HomeProvider>().error;
    if (error != null && !_errorShown) {
      _errorShown = true;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
    if (error == null) _errorShown = false;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HomeProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncMarkers(provider);
    });

    return NaverMap(
      options: const NaverMapViewOptions(
        initialCameraPosition: NCameraPosition(
          target: NLatLng(37.5445, 127.0556),
          zoom: 15,
        ),
        locationButtonEnable: true,
      ),
      onMapReady: (controller) {
        _controller = controller;
        provider.registerMapController(controller);
        _syncMarkers(provider);
      },
      onMapTapped: (_, latLng) => provider.clearSelection(),
    );
  }

  Future<void> _syncMarkers(HomeProvider provider) async {
    final controller = _controller;
    if (controller == null) return;

    final places = provider.filteredPlaces;
    final selectedId = provider.selectedPlaceId;

    final prevIds = _markers.keys.toSet();
    final newIds = places.map((p) => p.id).toSet();

    // 제거: filteredPlaces에서 사라진 마커
    for (final id in prevIds.difference(newIds)) {
      await controller.deleteOverlay(
        NOverlayInfo(type: NOverlayType.marker, id: id),
      );
      _markers.remove(id);
    }

    // 추가: 새로 생긴 마커
    final toAdd = <NMarker>{};
    for (final place in places.where((p) => !prevIds.contains(p.id))) {
      final marker = NMarker(
        id: place.id,
        position: NLatLng(place.lat, place.lng),
      );
      marker.setOnTapListener((_) => provider.selectPlace(place.id));
      _markers[place.id] = marker;
      toAdd.add(marker);
    }
    if (toAdd.isNotEmpty) await controller.addOverlayAll(toAdd);

    // 색상 동기화
    for (final place in places) {
      _markers[place.id]?.setIconTintColor(
        place.id == selectedId ? AppColors.primaryPink : Colors.grey.shade400,
      );
    }

    // 선택 변경 시 말풍선 + 카메라
    if (selectedId != _lastSelectedId) {
      _activeInfoWindow?.close();
      _activeInfoWindow = null;

      if (selectedId != null) {
        final candidates = places.where((p) => p.id == selectedId);
        if (candidates.isNotEmpty) {
          final place = candidates.first;
          final marker = _markers[selectedId];
          if (marker != null) {
            _activeInfoWindow = NInfoWindow.onMarker(
              id: '${selectedId}_info',
              text: '${place.name} · 포토존 ${place.photoZoneCount}개',
            );
            await marker.openInfoWindow(_activeInfoWindow!);
            await controller.updateCamera(
              NCameraUpdate.scrollAndZoomTo(
                target: NLatLng(place.lat, place.lng),
                zoom: 16,
              ),
            );
          }
        }
      }
    }

    _lastSelectedId = selectedId;
  }
}
