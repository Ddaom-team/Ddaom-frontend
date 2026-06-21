import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../home/home_models.dart';
import '../naver_place_search_service.dart';

/// 네이버 장소 정보 카드(장소 검색 화면 · 홈 지도 심볼탭 공용).
/// 등록 시 사용자가 고른 태그(카테고리)와 입력/수정한 주소를 [onRegister]로 전달한다.
class NaverPlaceInfoCard extends StatefulWidget {
  final NaverPlace place;
  final void Function(PlaceCategory category, String address) onRegister;
  const NaverPlaceInfoCard({
    super.key,
    required this.place,
    required this.onRegister,
  });

  @override
  State<NaverPlaceInfoCard> createState() => _NaverPlaceInfoCardState();
}

class _NaverPlaceInfoCardState extends State<NaverPlaceInfoCard> {
  late PlaceCategory _category;
  late final TextEditingController _addressCtrl;

  // 사용자가 고를 수 있는 태그(전체 제외).
  static const _options = [
    PlaceCategory.cafe,
    PlaceCategory.restaurant,
    PlaceCategory.popup,
    PlaceCategory.exhibition,
    PlaceCategory.nightView,
    PlaceCategory.entertainment,
    PlaceCategory.bar,
    PlaceCategory.shopping,
    PlaceCategory.attraction,
  ];

  @override
  void initState() {
    super.initState();
    // 네이버 카테고리로 초기 태그를 추정(사용자가 바꿀 수 있음).
    _category =
        PlaceCategoryLabel.fromApiString(mapNaverCategory(widget.place.category));
    if (_category == PlaceCategory.all) _category = PlaceCategory.cafe;
    // 검색으로 주소가 보강됐으면 채워두고, 없으면 사용자가 직접 입력.
    _addressCtrl = TextEditingController(text: widget.place.displayAddress);
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final address = _addressCtrl.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('주소를 입력해주세요.')),
      );
      return;
    }
    widget.onRegister(_category, address);
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.place;
    final mq = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: mq.viewInsets.bottom + mq.padding.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text(place.name,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (place.category.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(place.category,
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ],
          const SizedBox(height: 16),
          const Text('주소',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _addressCtrl,
            decoration: InputDecoration(
              hintText: '주소를 입력해주세요',
              prefixIcon: const Icon(Icons.place_outlined, size: 18),
              isDense: true,
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (place.telephone != null) ...[
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.phone_outlined, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text(place.telephone!, style: const TextStyle(fontSize: 13)),
            ]),
          ],
          const SizedBox(height: 16),
          const Text('태그',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final c in _options)
                ChoiceChip(
                  label: Text(c.label),
                  selected: _category == c,
                  onSelected: (_) => setState(() => _category = c),
                  selectedColor: AppColors.primaryPink,
                  labelStyle: TextStyle(
                    color: _category == c ? Colors.white : Colors.black87,
                    fontSize: 13,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPink,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('이 장소 등록',
                style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
          ],
        ),
      ),
    );
  }
}
