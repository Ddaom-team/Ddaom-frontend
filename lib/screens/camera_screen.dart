import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';

import '../features/photo/photo_selection_screen.dart';
import '../features/place/place_models.dart';

class CameraScreen extends StatefulWidget {
  final PhotoZone? photoZone;
  final VoidCallback? onBack;
  const CameraScreen({super.key, this.photoZone, this.onBack});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;

  // 현재 사용 중인 카메라 인덱스 (후면 광각 = 0, 전면 = 1 등)
  int _selectedCameraIndex = 0;
  bool _isInitialized = false;
  bool _isTakingPicture = false;
  bool _isSaving = false;

  double _currentZoom = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  double _baseZoomForGesture = 1.0;

  // 초광각(0.5x) 카메라 전환용
  CameraDescription? _ultraWideCamera;
  bool _isUltraWide = false;

  // 경쟁 조건 방지: 최신 startCamera 호출만 최종 반영
  int _cameraVersion = 0;

  XFile? _lastPhoto;

  // 카메라를 나갈 때 한꺼번에 등록하기 위해 촬영분을 누적한다.
  final List<XFile> _captured = [];

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  // 찍은 사진이 있으면 선택 화면으로, 없으면 그냥 카메라를 닫는다.
  Future<void> _onExit() async {
    if (_captured.isEmpty) {
      _leave();
      return;
    }
    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('업로드 하시겠습니까?'),
        content: const Text('촬영한 사진을 업로드할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'leave'),
            child: const Text('나가기'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'upload'),
            child: const Text('올리기'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (action == 'upload') {
      await _openSelection();
    } else if (action == 'leave') {
      _leave();
    }
  }

  // 업로드 없이 카메라를 닫는다(이전 화면으로).
  void _leave() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else {
      Navigator.maybePop(context);
    }
  }

  Future<void> _openSelection() async {
    final uploaded = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PhotoSelectionScreen(
          filePaths: _captured.map((e) => e.path).toList(),
          photoZone: widget.photoZone,
        ),
      ),
    );
    // 업로드까지 끝났으면 누적을 비워 같은 사진이 다시 등록되지 않게 한다.
    if (uploaded == true && mounted) {
      setState(() {
        _captured.clear();
        _lastPhoto = null;
      });
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;

      // 주 후면 카메라로 시작
      _selectedCameraIndex = _cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      if (_selectedCameraIndex == -1) _selectedCameraIndex = 0;

      await _startCamera(_cameras[_selectedCameraIndex]);

      // 초광각 카메라 탐색: 두 번째 후면 카메라 (iPhone 11+)
      final backCameras = _cameras
          .where((c) => c.lensDirection == CameraLensDirection.back)
          .toList();
      if (backCameras.length >= 2) {
        _ultraWideCamera = backCameras[1];
      }
    } catch (e) {
      debugPrint('카메라 초기화 실패: $e');
    }
  }

  Future<void> _startCamera(CameraDescription camera) async {
    // 버전 증가로 이전 실행 중인 startCamera 무효화
    _cameraVersion++;
    final myVersion = _cameraVersion;

    final oldController = _controller;

    setState(() {
      _controller = null;
      _isInitialized = false;
    });

    await oldController?.dispose();

    if (!mounted || _cameraVersion != myVersion) return;

    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await controller.initialize();

      if (!mounted || _cameraVersion != myVersion) {
        await controller.dispose();
        return;
      }

      final minZoom = await controller.getMinZoomLevel();
      final maxZoom = await controller.getMaxZoomLevel();

      if (!mounted || _cameraVersion != myVersion) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _isInitialized = true;
        _minZoom = minZoom;
        _maxZoom = maxZoom;
        _currentZoom = _isUltraWide ? 0.5 : 1.0;
      });
    } catch (e) {
      debugPrint('카메라 시작 실패: $e');
      if (_cameraVersion == myVersion) await controller.dispose();
    }
  }

  // 전면/후면 토글만 수행 (초광각/망원 포함 전체 사이클 X)
  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || !_isInitialized) return;

    _isUltraWide = false;

    final currentDirection = _cameras[_selectedCameraIndex].lensDirection;
    final targetDirection = currentDirection == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;

    final targetIndex = _cameras.indexWhere(
      (c) => c.lensDirection == targetDirection,
    );
    if (targetIndex == -1) return;

    _selectedCameraIndex = targetIndex;
    await _startCamera(_cameras[_selectedCameraIndex]);
  }

  Future<void> _setZoom(double level, {bool allowCameraSwitch = false}) async {
    if (!_isInitialized) return;

    if (level < 1.0) {
      if (_minZoom < 1.0) {
        // 네이티브 초광각 지원: API로 직접 줌
        final zoom = level.clamp(_minZoom, 1.0);
        try {
          await _controller!.setZoomLevel(zoom);
          if (mounted) setState(() => _currentZoom = zoom);
        } catch (_) {}
      } else if (allowCameraSwitch && _ultraWideCamera != null && !_isUltraWide) {
        // 초광각 카메라로 전환 (버튼 탭 시에만)
        _isUltraWide = true;
        await _startCamera(_ultraWideCamera!);
      }
      return;
    }

    // 1x 이상: 필요 시 광각 카메라로 복귀
    if (_isUltraWide && allowCameraSwitch) {
      _isUltraWide = false;
      await _startCamera(_cameras[_selectedCameraIndex]);
      // 복귀 후 요청한 줌 레벨 적용
      if (!_isInitialized || _controller == null) return;
      final zoom = level.clamp(1.0, _maxZoom);
      try {
        await _controller!.setZoomLevel(zoom);
        if (mounted) setState(() => _currentZoom = zoom);
      } catch (_) {}
      return;
    }

    if (_controller == null) return;
    final zoom = level.clamp(1.0, _maxZoom);
    try {
      await _controller!.setZoomLevel(zoom);
      if (mounted) setState(() => _currentZoom = zoom);
    } catch (_) {}
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null || !mounted) return;

    setState(() {
      _lastPhoto = image;
      _captured.add(image);
    });
  }

  Future<void> _takePicture() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isTakingPicture ||
        _isSaving) {
      return;
    }

    try {
      setState(() => _isTakingPicture = true);
      final photo = await _controller!.takePicture();
      if (!mounted) return;

      setState(() {
        _lastPhoto = photo;
        _captured.add(photo);
        _isSaving = true;
      });

      await Gal.putImage(photo.path, album: '따옴');
      // 화면을 벗어나지 않고 계속 촬영. 등록은 카메라를 나갈 때 일괄 진행한다.
    } on GalException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.type == GalExceptionType.accessDenied
                  ? '갤러리 접근 권한이 필요합니다'
                  : '저장에 실패했습니다',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('촬영/저장 실패: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isTakingPicture = false;
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildCameraPreview() {
    if (!_isInitialized || _controller == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    final previewSize = _controller!.value.previewSize;
    if (previewSize == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: previewSize.height,
          height: previewSize.width,
          child: CameraPreview(_controller!),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Row(
        children: [
          _circleIconButton(
            icon: Icons.arrow_back_ios_new,
            onTap: _onExit,
          ),
          const Spacer(),
          const Text(
            '내맘대로 카메라',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          _circleIconButton(
            icon: Icons.cameraswitch,
            onTap: _switchCamera,
          ),
        ],
      ),
    );
  }

  Widget _buildZoomControls() {
    const levels = [0.5, 1.0, 2.0, 3.0];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: levels.map((level) {
        final isSelected = (_currentZoom - level).abs() < 0.05;
        final label = level == 1.0
            ? '×1'
            : level < 1.0
                ? '×$level'
                : '×${level.toInt()}';
        return GestureDetector(
          onTap: () => _setZoom(level, allowCameraSwitch: true),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.25)
                  : Colors.transparent,
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomControls() {
    return ColoredBox(
      color: Colors.black,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildZoomControls(),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _albumPreview(),
                  _shutterButton(),
                  const SizedBox(width: 58, height: 58),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _albumPreview() {
    return GestureDetector(
      onTap: _captured.isEmpty ? _pickFromGallery : _openSelection,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white70, width: 1.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: _lastPhoto == null
                ? const Icon(Icons.photo_library_outlined, color: Colors.white)
                : Image.file(
                    File(_lastPhoto!.path),
                    fit: BoxFit.cover,
                  ),
          ),
          if (_captured.isNotEmpty)
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                padding: const EdgeInsets.all(5),
                constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                decoration: const BoxDecoration(
                  color: Color(0xFFFF5C8A),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${_captured.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _shutterButton() {
    return GestureDetector(
      onTap: _isInitialized ? _takePicture : null,
      child: Container(
        width: 82,
        height: 82,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 5),
        ),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: _isTakingPicture ? 56 : 66,
            height: _isTakingPicture ? 56 : 66,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFF5C8A),
            ),
          ),
        ),
      ),
    );
  }

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 21),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onScaleStart: (_) => _baseZoomForGesture = _currentZoom,
              onScaleUpdate: (details) {
                if (details.pointerCount >= 2) {
                  _setZoom(_baseZoomForGesture * details.scale);
                }
              },
              child: Stack(
                children: [
                  _buildCameraPreview(),
                  Container(color: Colors.black.withValues(alpha: 0.22)),
                  SafeArea(
                    bottom: false,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: _buildTopBar(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildBottomControls(),
        ],
      ),
    );
  }
}
