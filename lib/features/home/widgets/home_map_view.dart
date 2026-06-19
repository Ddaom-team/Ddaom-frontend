import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../../core/api_client.dart';
import '../../../core/app_theme.dart';
import '../../place/naver_place_search_service.dart';
import '../../place/place_detail_screen.dart';
import '../../place/place_registration.dart';
import '../../place/widgets/naver_place_info_card.dart';
import '../home_models.dart';
import '../home_provider.dart';

class HomeMapView extends StatefulWidget {
  const HomeMapView({super.key});

  @override
  State<HomeMapView> createState() => _HomeMapViewState();
}

class _HomeMapViewState extends State<HomeMapView> {
  NaverMapController? _controller;
  late final _searchService = NaverPlaceSearchService(context.read<ApiClient>());
  final Map<String, NMarker> _markers = {};
  final Map<String, NOverlayImage> _iconCache = {};
  NInfoWindow? _activeInfoWindow;
  String? _lastSelectedId;
  bool _errorShown = false;
  bool _syncing = false;
  bool _needsSync = false;
  HomeProvider? _homeProvider;

  static const _normalSize = Size(36, 36);
  static const _selectedSize = Size(44, 44);

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
    super.dispose();
  }

  void _onProviderChanged() {
    if (!mounted) return;
    final provider = context.read<HomeProvider>();
    final error = provider.error;
    if (error != null && !_errorShown) {
      _errorShown = true;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
    if (error == null) _errorShown = false;

    if (_syncing) {
      _needsSync = true;
    } else {
      _syncMarkers(provider);
    }
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
        final provider = context.read<HomeProvider>();
        provider.registerMapController(controller);
        _syncMarkers(provider);
        _enableLocationOverlay(controller);
      },
      onMapTapped: (_, latLng) => context.read<HomeProvider>().clearSelection(),
      onSymbolTapped: _onSymbolTapped,
    );
  }

  /// 네이버 지도 기본 POI 심볼(아직 등록 안 된 실제 장소)을 탭했을 때.
  /// 이미 등록된 장소면 선택만(중복 등록 차단), 아니면 정보 카드 → 등록.
  Future<void> _onSymbolTapped(NSymbolInfo symbol) async {
    final provider = context.read<HomeProvider>();
    final lat = symbol.position.latitude;
    final lng = symbol.position.longitude;

    final existing =
        findRegisteredNearby(provider.allPlaces, lat, lng, name: symbol.caption);
    if (existing != null) {
      provider.selectPlace(existing.id);
      return;
    }

    // 네이버 검색으로 카테고리·주소·전화 보강(좌표는 탭 위치를 권위값으로 사용).
    // 검색이 실패해도 이름+좌표만으로 카드를 띄워 등록할 수 있게 한다.
    List<NaverPlace> results = [];
    try {
      results = await _searchService.search(symbol.caption);
    } catch (_) {}
    final match = _nearestMatch(results, lat, lng);
    final place = NaverPlace(
      name: (match != null && match.name.isNotEmpty) ? match.name : symbol.caption,
      category: match?.category ?? '',
      roadAddress: match?.roadAddress ?? '',
      address: match?.address ?? '',
      telephone: match?.telephone,
      lat: lat,
      lng: lng,
    );

    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => NaverPlaceInfoCard(
        place: place,
        onRegister: (category, address) {
          Navigator.pop(context);
          _registerFromMap(place, category, address);
        },
      ),
    );
  }

  /// 탭한 위치에서 가장 가까운(약 200m 이내) 검색 결과. 없으면 null.
  NaverPlace? _nearestMatch(List<NaverPlace> results, double lat, double lng) {
    NaverPlace? best;
    var bestDist = 0.003;
    for (final r in results) {
      final d = (r.lat - lat).abs() + (r.lng - lng).abs();
      if (d < bestDist) {
        bestDist = d;
        best = r;
      }
    }
    return best;
  }

  Future<void> _registerFromMap(
      NaverPlace place, PlaceCategory category, String address) async {
    final api = context.read<ApiClient>();
    final provider = context.read<HomeProvider>();
    final outcome = await registerNaverPlace(
        api: api,
        home: provider,
        place: place,
        category: category,
        address: address);
    if (!mounted) return;
    final msg = switch (outcome) {
      RegisterOutcome.success => '장소가 등록되었습니다.',
      RegisterOutcome.duplicate => '이미 등록된 장소입니다.',
      RegisterOutcome.failure => '장소 등록에 실패했습니다.',
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _syncMarkers(HomeProvider provider) async {
    if (_syncing) {
      _needsSync = true;
      return;
    }
    _syncing = true;
    _needsSync = false;
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
      if (_needsSync && mounted) {
        _needsSync = false;
        _syncMarkers(context.read<HomeProvider>());
      }
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
      case PlaceCategory.entertainment:
        return Icons.sports_esports;
      case PlaceCategory.bar:
        return Icons.local_bar;
      case PlaceCategory.shopping:
        return Icons.storefront;
      case PlaceCategory.attraction:
        return Icons.landscape;
      case PlaceCategory.all:
        return Icons.place_outlined;
    }
  }
}
