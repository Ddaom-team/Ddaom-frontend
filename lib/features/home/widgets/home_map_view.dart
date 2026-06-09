import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../../core/app_theme.dart';
import '../../place/place_detail_screen.dart';
import '../home_models.dart';
import '../home_provider.dart';

class HomeMapView extends StatefulWidget {
  const HomeMapView({super.key});

  @override
  State<HomeMapView> createState() => _HomeMapViewState();
}

class _HomeMapViewState extends State<HomeMapView> {
  NaverMapController? _controller;
  final Map<String, NMarker> _markers = {};
  final Map<String, NOverlayImage> _iconCache = {};
  NInfoWindow? _activeInfoWindow;
  String? _lastSelectedId;
  bool _errorShown = false;
  bool _syncing = false;
  HomeProvider? _homeProvider;

  static const _normalSize = Size(36, 36);
  static const _selectedSize = Size(44, 44);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _homeProvider = context.read<HomeProvider>();
        _homeProvider!.addListener(_checkError);
      }
    });
  }

  @override
  void dispose() {
    _homeProvider?.removeListener(_checkError);
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

  Future<NOverlayImage> _getMarkerIcon(PlaceCategory category, bool selected) async {
    final key = '${category.name}_$selected';
    if (_iconCache.containsKey(key)) return _iconCache[key]!;
    final icon = await NOverlayImage.fromWidget(
      widget: _MarkerIcon(category: category, selected: selected),
      size: selected ? _selectedSize : _normalSize,
      context: context,
    );
    _iconCache[key] = icon;
    return icon;
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
        _enableLocationOverlay(controller);
      },
      onMapTapped: (_, latLng) => provider.clearSelection(),
    );
  }

  Future<void> _syncMarkers(HomeProvider provider) async {
    if (_syncing) return;
    _syncing = true;
    try {
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
        final icon = await _getMarkerIcon(place.category, false);
        final marker = NMarker(
          id: place.id,
          position: NLatLng(place.lat, place.lng),
          icon: icon,
          size: _normalSize,
        );
        marker.setOnTapListener((_) {
          // 이미 선택된 핀을 다시 탭하면 상세 진입, 아니면 선택(카메라 이동 + 말풍선)만.
          if (provider.selectedPlaceId == place.id) {
            if (!mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PlaceDetailScreen(placeId: place.id),
              ),
            );
          } else {
            provider.selectPlace(place.id);
          }
        });
        _markers[place.id] = marker;
        toAdd.add(marker);
      }
      if (toAdd.isNotEmpty) await controller.addOverlayAll(toAdd);

      // 선택 변경 시 아이콘/크기 업데이트
      if (selectedId != _lastSelectedId) {
        // 이전 선택 해제
        if (_lastSelectedId != null) {
          final prevIdx = places.indexWhere((p) => p.id == _lastSelectedId);
          if (prevIdx >= 0) {
            final icon = await _getMarkerIcon(places[prevIdx].category, false);
            _markers[_lastSelectedId!]?.setIcon(icon);
            _markers[_lastSelectedId!]?.setSize(_normalSize);
          }
        }
        // 새 선택 강조
        if (selectedId != null) {
          final currIdx = places.indexWhere((p) => p.id == selectedId);
          if (currIdx >= 0) {
            final icon = await _getMarkerIcon(places[currIdx].category, true);
            _markers[selectedId]?.setIcon(icon);
            _markers[selectedId]?.setSize(_selectedSize);
          }
        }

        // 말풍선 + 카메라
        try {
          _activeInfoWindow?.close();
        } catch (_) {}
        _activeInfoWindow = null;

        if (selectedId != null) {
          final currIdx = places.indexWhere((p) => p.id == selectedId);
          if (currIdx >= 0) {
            final place = places[currIdx];
            final marker = _markers[selectedId];
            if (marker != null) {
              _activeInfoWindow = NInfoWindow.onMarker(
                id: '${selectedId}_info',
                text: '${place.name} · 포토존 ${place.photoSpotCount}개',
              );
              try {
                await marker.openInfoWindow(_activeInfoWindow!);
              } catch (_) {
                _activeInfoWindow = null;
              }
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
    } finally {
      _syncing = false;
    }
  }

  Future<void> _enableLocationOverlay(NaverMapController controller) async {
    // 1. 위치 서비스(기기 GPS) 켜져 있는지 확인
    if (!await Geolocator.isLocationServiceEnabled()) {
      debugPrint('[GPS] 위치 서비스가 꺼져 있음');
      return;
    }

    // 2. 권한 요청 (다이얼로그 표시)
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      debugPrint('[GPS] 위치 권한 거부됨: $permission');
      return;
    }
    if (!mounted) return;

    // 3. 현재 위치 받아서 파란 점 표시 + 카메라 이동
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    if (!mounted) return;

    final overlay = controller.getLocationOverlay();
    overlay.setIsVisible(true);
    overlay.setPosition(NLatLng(pos.latitude, pos.longitude));
    controller.setLocationTrackingMode(NLocationTrackingMode.follow);
    await controller.updateCamera(
      NCameraUpdate.scrollAndZoomTo(
        target: NLatLng(pos.latitude, pos.longitude),
        zoom: 15,
      ),
    );
  }
}

class _MarkerIcon extends StatelessWidget {
  final PlaceCategory category;
  final bool selected;

  const _MarkerIcon({required this.category, required this.selected});

  @override
  Widget build(BuildContext context) {
    final size = selected ? 44.0 : 36.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryPink : const Color(0xFFFF8FAB),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0x44000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Icon(_iconData, color: Colors.white, size: selected ? 22 : 18),
    );
  }

  IconData get _iconData {
    switch (category) {
      case PlaceCategory.cafe:
        return Icons.coffee;
      case PlaceCategory.restaurant:
        return Icons.restaurant;
      case PlaceCategory.popup:
        return Icons.shopping_bag_outlined;
      case PlaceCategory.exhibition:
        return Icons.palette_outlined;
      case PlaceCategory.nightView:
        return Icons.nightlight_round;
      case PlaceCategory.all:
        return Icons.place_outlined;
    }
  }
}
