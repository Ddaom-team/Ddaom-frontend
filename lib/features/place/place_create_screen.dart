import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/app_theme.dart';
import '../../core/naver_map_config.dart';

class PlaceCreateScreen extends StatefulWidget {
  const PlaceCreateScreen({super.key});

  @override
  State<PlaceCreateScreen> createState() => _PlaceCreateScreenState();
}

class _PlaceCreateScreenState extends State<PlaceCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  String _category = '카페';
  bool _loading = false;
  double? _lat;
  double? _lng;

  static const _categories = ['카페', '식당', '팝업', '전시', '야경'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _openAddressSearch() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _AddressSearchSheet(
        onSelected: (address, lat, lng) {
          setState(() {
            _addressCtrl.text = address;
            _lat = lat;
            _lng = lng;
          });
        },
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final api = context.read<ApiClient>();
      await api.dio.post('/api/places', data: {
        'name': _nameCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'category': _category,
        if (_lat != null) 'latitude': _lat,
        if (_lng != null) 'longitude': _lng,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('장소가 등록되었습니다.')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('장소 등록에 실패했습니다. 백엔드 API를 확인하세요.')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('새 장소 등록'),
        backgroundColor: AppColors.background,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _loading ? null : _submit,
            child: const Text('등록',
                style: TextStyle(
                    color: AppColors.primaryPink,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: _inputDeco('장소 이름'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '장소 이름을 입력해주세요' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressCtrl,
              readOnly: true,
              onTap: _openAddressSearch,
              decoration: _inputDeco('주소').copyWith(
                hintText: '탭하여 주소 검색',
                suffixIcon: const Icon(Icons.search, color: Colors.grey),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '주소를 선택해주세요' : null,
            ),
            if (_lat != null && _lng != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '좌표: ${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: _inputDeco('카테고리'),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v ?? '카페'),
            ),
            const SizedBox(height: 32),
            if (_loading)
              const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primaryPink))
            else
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('장소 등록',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primaryPink),
        ),
      );
}

// ── 주소 검색 바텀시트 ─────────────────────────────────────────────

class _AddressSearchSheet extends StatefulWidget {
  final void Function(String address, double lat, double lng) onSelected;

  const _AddressSearchSheet({required this.onSelected});

  @override
  State<_AddressSearchSheet> createState() => _AddressSearchSheetState();
}

class _AddressSearchSheetState extends State<_AddressSearchSheet> {
  final _ctrl = TextEditingController();
  final _dio = Dio();
  Timer? _timer;
  List<_GeoResult> _results = [];
  bool _loading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _timer?.cancel();
    _dio.close();
    super.dispose();
  }

  void _onChanged(String q) {
    _timer?.cancel();
    if (q.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    _timer = Timer(
        const Duration(milliseconds: 300), () => _search(q.trim()));
  }

  Future<void> _search(String q) async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final res = await _dio.get(
        'https://maps.apigw.ntruss.com/map-geocode/v2/geocode',
        queryParameters: {'query': q},
        options: Options(
          headers: {
            'x-ncp-apigw-api-key-id': naverMapClientId,
            'x-ncp-apigw-api-key': naverGeoClientSecret,
          },
          validateStatus: (_) => true,
        ),
      );
      if (!mounted) return;
      if (res.statusCode != 200) {
        debugPrint('[GeoSearch] HTTP ${res.statusCode}: ${res.data}');
        setState(() => _results = []);
        return;
      }
      final addresses = res.data['addresses'] as List<dynamic>? ?? [];
      setState(() {
        _results = addresses.map((a) {
          final m = a as Map<String, dynamic>;
          return _GeoResult(
            roadAddress: m['roadAddress'] as String? ?? '',
            jibunAddress: m['jibunAddress'] as String? ?? '',
            lat: double.tryParse(m['y'] as String? ?? '') ?? 0,
            lng: double.tryParse(m['x'] as String? ?? '') ?? 0,
          );
        }).toList();
      });
    } catch (e, st) {
      debugPrint('[GeoSearch] error: $e\n$st');
      if (!mounted) return;
      setState(() => _results = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          const Text('주소 검색',
              style:
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            autofocus: true,
            onChanged: _onChanged,
            decoration: InputDecoration(
              hintText: '주소 또는 장소명 입력',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(
                  color: AppColors.primaryPink),
            )
          else
            Flexible(
              child: _ctrl.text.isNotEmpty && _results.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('검색 결과가 없습니다',
                          style: TextStyle(color: Colors.grey)),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: _results.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final r = _results[i];
                        final display = r.roadAddress.isNotEmpty
                            ? r.roadAddress
                            : r.jibunAddress;
                        return ListTile(
                          leading: const Icon(Icons.location_on_outlined,
                              color: AppColors.primaryPink),
                          title: Text(display,
                              style: const TextStyle(fontSize: 14)),
                          subtitle: r.jibunAddress.isNotEmpty &&
                                  r.roadAddress.isNotEmpty
                              ? Text(r.jibunAddress,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey))
                              : null,
                          onTap: () {
                            widget.onSelected(display, r.lat, r.lng);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _GeoResult {
  final String roadAddress;
  final String jibunAddress;
  final double lat;
  final double lng;

  const _GeoResult({
    required this.roadAddress,
    required this.jibunAddress,
    required this.lat,
    required this.lng,
  });
}
