import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/app_theme.dart';
import '../../core/network_thumb.dart';
import '../home/home_models.dart';
import '../home/home_provider.dart';
import '../place/place_models.dart';
import 'photo_metadata_screen.dart';

/// 홈 카메라로 찍은 사진을 어떤 포토존에 등록할지 고르는 화면.
/// 현재 GPS 위치 기준으로 가장 가까운(포토존 보유) 장소를 추천으로 자동 펼치고,
/// 사용자가 직접 다른 장소·포토존을 선택할 수도 있다. 건너뛰기도 가능.
class PhotoSpotPickerScreen extends StatefulWidget {
  final List<String> filePaths;
  final int? sourcePhotoId;

  const PhotoSpotPickerScreen({
    super.key,
    required this.filePaths,
    this.sourcePhotoId,
  });

  @override
  State<PhotoSpotPickerScreen> createState() => _PhotoSpotPickerScreenState();
}

class _PhotoSpotPickerScreenState extends State<PhotoSpotPickerScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  Position? _pos;
  bool _locating = true;
  List<Place> _places = [];

  // placeId -> 포토존 목록 (펼칠 때 지연 로드)
  final Map<String, List<PhotoZone>> _spotsCache = {};
  final Set<String> _loadingSpots = {};

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    _places = List.of(context.read<HomeProvider>().allPlaces);
    await _locate();
    _sortByDistance();
    if (mounted) setState(() => _locating = false);
    // 가장 가까운 포토존 보유 장소를 추천으로 미리 로드(자동 펼침과 맞춤).
    final withSpots = _placesWithSpots;
    if (withSpots.isNotEmpty) _loadSpots(withSpots.first.id);
  }

  Future<void> _locate() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      _pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (_) {
      // 위치 못 받으면 거리 정렬 없이 등록 순서 그대로 노출.
    }
  }

  void _sortByDistance() {
    if (_pos == null) return;
    _places.sort((a, b) => _distance(a).compareTo(_distance(b)));
  }

  double _distance(Place p) {
    final pos = _pos;
    if (pos == null) return double.maxFinite;
    return Geolocator.distanceBetween(
      pos.latitude,
      pos.longitude,
      p.lat,
      p.lng,
    );
  }

  String _distanceLabel(Place p) {
    final d = _distance(p);
    if (d == double.maxFinite) return '';
    if (d < 1000) return '${d.round()}m';
    return '${(d / 1000).toStringAsFixed(1)}km';
  }

  List<Place> get _filtered {
    final q = _query.trim();
    if (q.isEmpty) return _places;
    return _places.where((p) => p.name.contains(q)).toList();
  }

  List<Place> get _placesWithSpots =>
      _places.where((p) => p.photoSpotCount > 0).toList();

  Future<void> _loadSpots(String placeId) async {
    if (_spotsCache.containsKey(placeId) || _loadingSpots.contains(placeId)) {
      return;
    }
    setState(() => _loadingSpots.add(placeId));
    try {
      final res = await context.read<ApiClient>().dio.get(
        '/api/places/$placeId',
      );
      final detail = PlaceDetail.fromJson(res.data as Map<String, dynamic>);
      _spotsCache[placeId] = detail.photoZones;
    } catch (_) {
      _spotsCache[placeId] = [];
    } finally {
      if (mounted) setState(() => _loadingSpots.remove(placeId));
    }
  }

  Future<void> _select(String? photoSpotId) async {
    final uploaded = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PhotoMetadataScreen(
          filePaths: widget.filePaths,
          photoSpotId: photoSpotId,
          sourcePhotoId: widget.sourcePhotoId,
        ),
      ),
    );
    // 업로드 완료면 카메라까지 전파해 누적 사진을 비우게 한다.
    if (uploaded == true && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          '포토존 선택',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => _select(null),
            child: const Text(
              '건너뛰기',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: '장소 이름으로 찾기',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (_locating)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primaryPink),
              ),
            )
          else
            Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildList() {
    final list = _filtered;
    if (list.isEmpty) {
      return const Center(
        child: Text(
          '등록된 장소가 없습니다',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }
    // 검색 중이 아니고 포토존 보유 장소가 있으면 가장 가까운 곳을 추천 처리.
    final recommendedId = (_query.trim().isEmpty && _placesWithSpots.isNotEmpty)
        ? _placesWithSpots.first.id
        : null;
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: list.length,
      itemBuilder: (_, i) => _placeTile(list[i], list[i].id == recommendedId),
    );
  }

  Widget _placeTile(Place place, bool recommended) {
    final hasSpots = place.photoSpotCount > 0;
    final dist = _distanceLabel(place);
    final subtitle = [
      if (dist.isNotEmpty) dist,
      '포토존 ${place.photoSpotCount}개',
    ].join(' · ');

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: recommended,
        onExpansionChanged: (open) {
          if (open && hasSpots) _loadSpots(place.id);
        },
        title: Row(
          children: [
            Flexible(
              child: Text(
                place.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (recommended) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryPink,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '추천',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        children: hasSpots
            ? _spotChildren(place.id)
            : const [
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '등록된 포토존이 없습니다',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ],
      ),
    );
  }

  List<Widget> _spotChildren(String placeId) {
    if (_loadingSpots.contains(placeId)) {
      return const [
        Padding(
          padding: EdgeInsets.all(12),
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primaryPink,
              ),
            ),
          ),
        ),
      ];
    }
    final spots = _spotsCache[placeId];
    if (spots == null) return const [SizedBox.shrink()];
    if (spots.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '등록된 포토존이 없습니다',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ),
        ),
      ];
    }
    return spots
        .map(
          (z) => ListTile(
            contentPadding: const EdgeInsets.only(left: 32, right: 20),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: NetworkThumb(
                url: z.imageUrl,
                width: 44,
                height: 44,
                placeholderIcon: Icons.photo_camera_outlined,
              ),
            ),
            title: Text(z.name, style: const TextStyle(fontSize: 14)),
            trailing: const Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.textMuted,
            ),
            onTap: () => _select(z.id),
          ),
        )
        .toList();
  }
}
