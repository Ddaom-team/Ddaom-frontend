import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../place/place_models.dart';
import 'photo_metadata_screen.dart';
import 'photo_spot_picker_screen.dart';

/// 카메라에서 여러 장을 찍은 뒤, 그중 업로드할 사진을 골라내는 화면.
/// 기본은 전체 선택. 다음 단계는 포토존 지정 여부로 갈린다
/// (홈 카메라 = 미지정 → 포토존 선택, 따오기 카메라 = 지정 → 바로 메타데이터).
class PhotoSelectionScreen extends StatefulWidget {
  final List<String> filePaths;
  final PhotoZone? photoZone;
  final int? sourcePhotoId;

  const PhotoSelectionScreen({
    super.key,
    required this.filePaths,
    this.photoZone,
    this.sourcePhotoId,
  });

  @override
  State<PhotoSelectionScreen> createState() => _PhotoSelectionScreenState();
}

class _PhotoSelectionScreenState extends State<PhotoSelectionScreen> {
  late final Set<String> _selected = {...widget.filePaths};

  void _toggle(String path) {
    setState(() {
      if (!_selected.remove(path)) _selected.add(path);
    });
  }

  Future<void> _next() async {
    final paths = widget.filePaths.where(_selected.contains).toList();
    if (paths.isEmpty) return;
    final uploaded = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => widget.photoZone != null
            ? PhotoMetadataScreen(
                filePaths: paths,
                photoSpotId: widget.photoZone!.id,
                sourcePhotoId: widget.sourcePhotoId,
              )
            : PhotoSpotPickerScreen(
                filePaths: paths,
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('사진 선택',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '업로드할 사진을 선택하세요 (${_selected.length}/${widget.filePaths.length})',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: widget.filePaths.length,
              itemBuilder: (_, i) => _tile(widget.filePaths[i]),
            ),
          ),
          _buildNextButton(),
        ],
      ),
    );
  }

  Widget _tile(String path) {
    final isSelected = _selected.contains(path);
    return GestureDetector(
      onTap: () => _toggle(path),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(File(path), fit: BoxFit.cover),
            if (!isSelected)
              Container(color: Colors.white.withValues(alpha: 0.45)),
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? AppColors.primaryPink
                      : Colors.black.withValues(alpha: 0.35),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    final count = _selected.length;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: count == 0 ? null : _next,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPink,
              disabledBackgroundColor: AppColors.secondaryPink,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              count == 0 ? '사진을 선택하세요' : '다음 ($count장)',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
