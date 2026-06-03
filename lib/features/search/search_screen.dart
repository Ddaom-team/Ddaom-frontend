import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/app_theme.dart';
import '../../core/place_repository.dart';
import '../home/home_models.dart';
import '../place/place_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  List<Place> _allPlaces = [];
  List<Place> _results = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchAll() async {
    setState(() => _loading = true);
    try {
      final api = context.read<ApiClient>();
      final repo = ApiPlaceRepository(api);
      _allPlaces = await repo.fetchPlaces();
    } catch (_) {
      _allPlaces = [];
    } finally {
      setState(() => _loading = false);
    }
  }

  void _onQueryChanged(String query) {
    final q = query.trim();
    setState(() {
      _results = q.isEmpty
          ? []
          : _allPlaces
              .where((p) => p.name.contains(q) || p.address.contains(q))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '장소 이름이나 주소로 검색',
            border: InputBorder.none,
            hintStyle: TextStyle(color: AppColors.textMuted),
          ),
          onChanged: _onQueryChanged,
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryPink))
          : _results.isEmpty
              ? Center(
                  child: Text(
                    _controller.text.isEmpty ? '장소를 검색해보세요' : '검색 결과가 없습니다',
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                )
              : ListView.separated(
                  itemCount: _results.length,
                  separatorBuilder: (ctx, i) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final place = _results[i];
                    return ListTile(
                      leading: place.thumbnailUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                place.thumbnailUrl!,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) =>
                                    const Icon(Icons.place),
                              ),
                            )
                          : const Icon(Icons.place_outlined,
                              color: AppColors.primaryPink),
                      title: Text(place.name,
                          style:
                              const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text(place.address,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textMuted)),
                      trailing: Text('포토존 ${place.photoSpotCount}개',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.primaryPink)),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PlaceDetailScreen(placeId: place.id),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
