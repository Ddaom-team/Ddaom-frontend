import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/app_theme.dart';
import 'photo_models.dart';
import 'photo_service.dart';

class PhotoMetadataScreen extends StatefulWidget {
  final List<String> filePaths;
  final String? photoSpotId;
  final int? sourcePhotoId;

  const PhotoMetadataScreen({
    super.key,
    required this.filePaths,
    this.photoSpotId,
    this.sourcePhotoId,
  });

  @override
  State<PhotoMetadataScreen> createState() => _PhotoMetadataScreenState();
}

class _PhotoMetadataScreenState extends State<PhotoMetadataScreen> {
  final _tipController = TextEditingController();

  PhotoMood _mood = PhotoMood.CALM;
  PhotoTimeTag _timeTag = PhotoTimeTag.AFTERNOON;
  PhotoType _photoType = PhotoType.LANDSCAPE;
  CrowdLevel _crowdLevel = CrowdLevel.NORMAL;
  PhotoVisibility _visibility = PhotoVisibility.PUBLIC;

  bool _isUploading = false;
  int _uploadedCount = 0;

  @override
  void dispose() {
    _tipController.dispose();
    super.dispose();
  }

  Future<void> _upload() async {
    setState(() {
      _isUploading = true;
      _uploadedCount = 0;
    });
    final service = PhotoService(context.read<ApiClient>());
    final request = PhotoUploadRequest(
      photoSpotId: widget.photoSpotId,
      sourcePhotoId: widget.sourcePhotoId,
      tip: _tipController.text.trim().isEmpty
          ? null
          : _tipController.text.trim(),
      mood: _mood,
      timeTag: _timeTag,
      photoType: _photoType,
      crowdLevel: _crowdLevel,
      photoVisibility: _visibility,
    );
    try {
      // 선택한 사진을 같은 포토존·메타데이터로 한 장씩 순차 업로드.
      for (final path in widget.filePaths) {
        await service.uploadPhoto(filePath: path, request: request);
        if (!mounted) return;
        setState(() => _uploadedCount++);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('사진 ${widget.filePaths.length}장이 업로드됐어요!')),
      );
      // 업로드 완료를 호출 체인(선택→포토존→카메라)에 전파해 누적 사진을 비우게 한다.
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '업로드 실패: ${e.message}'
            '${_uploadedCount > 0 ? ' ($_uploadedCount장 업로드됨)' : ''}',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '업로드에 실패했습니다'
            '${_uploadedCount > 0 ? ' ($_uploadedCount장 업로드됨)' : ''}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
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
        title: const Text(
          '사진 정보 설정',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPhotoPreview(),
                  const SizedBox(height: 24),
                  _buildTipField(),
                  const SizedBox(height: 24),
                  _buildSection<PhotoMood>(
                    label: '분위기',
                    values: PhotoMood.values,
                    selected: _mood,
                    labelOf: (v) => v.label,
                    onSelect: (v) => setState(() => _mood = v),
                    scrollable: true,
                  ),
                  const SizedBox(height: 20),
                  _buildSection<PhotoTimeTag>(
                    label: '시간대',
                    values: PhotoTimeTag.values,
                    selected: _timeTag,
                    labelOf: (v) => v.label,
                    onSelect: (v) => setState(() => _timeTag = v),
                  ),
                  const SizedBox(height: 20),
                  _buildSection<PhotoType>(
                    label: '사진 유형',
                    values: PhotoType.values,
                    selected: _photoType,
                    labelOf: (v) => v.label,
                    onSelect: (v) => setState(() => _photoType = v),
                  ),
                  const SizedBox(height: 20),
                  _buildSection<CrowdLevel>(
                    label: '혼잡도',
                    values: CrowdLevel.values,
                    selected: _crowdLevel,
                    labelOf: (v) => v.label,
                    onSelect: (v) => setState(() => _crowdLevel = v),
                  ),
                  const SizedBox(height: 20),
                  _buildSection<PhotoVisibility>(
                    label: '공개 범위',
                    values: PhotoVisibility.values,
                    selected: _visibility,
                    labelOf: (v) => v.label,
                    onSelect: (v) => setState(() => _visibility = v),
                  ),
                ],
              ),
            ),
          ),
          _buildUploadButton(),
        ],
      ),
    );
  }

  Widget _buildPhotoPreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(File(widget.filePaths.first), fit: BoxFit.cover),
            if (widget.filePaths.length > 1)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.collections,
                        color: Colors.white,
                        size: 15,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${widget.filePaths.length}장',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('촬영 팁 (선택)'),
        const SizedBox(height: 10),
        TextField(
          controller: _tipController,
          maxLines: 2,
          maxLength: 100,
          decoration: InputDecoration(
            hintText: '이 포토존에서의 촬영 팁을 남겨보세요',
            hintStyle: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryPink),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection<T>({
    required String label,
    required List<T> values,
    required T selected,
    required String Function(T) labelOf,
    required void Function(T) onSelect,
    bool scrollable = false,
  }) {
    final chips = values.map((v) {
      final isSelected = v == selected;
      return GestureDetector(
        onTap: () => onSelect(v),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryPink : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primaryPink : AppColors.divider,
            ),
          ),
          child: Text(
            labelOf(v),
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? Colors.white : AppColors.textMain,
            ),
          ),
        ),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label),
        const SizedBox(height: 10),
        if (scrollable)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: chips
                  .map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: c,
                    ),
                  )
                  .toList(),
            ),
          )
        else
          Wrap(spacing: 8, runSpacing: 8, children: chips),
      ],
    );
  }

  Widget _buildUploadButton() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isUploading ? null : _upload,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPink,
              disabledBackgroundColor: AppColors.secondaryPink,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isUploading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      ),
                      if (widget.filePaths.length > 1) ...[
                        const SizedBox(width: 12),
                        Text(
                          '$_uploadedCount/${widget.filePaths.length}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  )
                : Text(
                    widget.filePaths.length > 1
                        ? '${widget.filePaths.length}장 업로드'
                        : '업로드',
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

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textMain,
      ),
    );
  }
}
