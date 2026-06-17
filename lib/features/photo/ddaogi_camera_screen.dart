import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';

import 'photo_metadata_screen.dart';
import '../place/place_models.dart';

class DdaogiCameraScreen extends StatefulWidget {
  final PhotoZone? photoZone;
  final String? referencePhotoUrl;
  const DdaogiCameraScreen({super.key, this.photoZone, this.referencePhotoUrl});

  @override
  State<DdaogiCameraScreen> createState() => _DdaogiCameraScreenState();
}

class _DdaogiCameraScreenState extends State<DdaogiCameraScreen> {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;

  int _selectedCameraIndex = 0;
  bool _isInitialized = false;
  bool _isGuideOn = true;
  bool _isTakingPicture = false;
  bool _isSaving = false;

  double _currentZoom = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  double _baseZoomForGesture = 1.0;

  CameraDescription? _ultraWideCamera;
  bool _isUltraWide = false;

  int _cameraVersion = 0;

  XFile? _lastPhoto;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;

      _selectedCameraIndex = _cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      if (_selectedCameraIndex == -1) _selectedCameraIndex = 0;

      await _startCamera(_cameras[_selectedCameraIndex]);

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
        final zoom = level.clamp(_minZoom, 1.0);
        try {
          await _controller!.setZoomLevel(zoom);
          if (mounted) setState(() => _currentZoom = zoom);
        } catch (_) {}
      } else if (allowCameraSwitch && _ultraWideCamera != null && !_isUltraWide) {
        _isUltraWide = true;
        await _startCamera(_ultraWideCamera!);
      }
      return;
    }

    if (_isUltraWide && allowCameraSwitch) {
      _isUltraWide = false;
      await _startCamera(_cameras[_selectedCameraIndex]);
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
        _isSaving = true;
      });

      await Gal.putImage(photo.path, album: '따옴');

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PhotoMetadataScreen(
            filePath: photo.path,
            photoSpotId: widget.photoZone?.id,
          ),
        ),
      );
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
            onTap: () => Navigator.maybePop(context),
          ),
          const Spacer(),
          const Text(
            '가이드 카메라',
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

  Widget _buildGuideCard() {
    if (!_isGuideOn) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '선택한 포토존',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.photoZone?.name ?? '포토존을 선택해주세요',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'TIP  창문을 오른쪽에 두고\n인물은 화면의 왼쪽에 세워보세요!',
                    style: TextStyle(
                      color: Colors.white,
                      height: 1.35,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 70,
              height: 88,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              clipBehavior: Clip.antiAlias,
              child: (widget.referencePhotoUrl != null &&
                      widget.referencePhotoUrl!.isNotEmpty)
                  ? Image.network(
                      widget.referencePhotoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.image_outlined,
                        color: Colors.white70,
                        size: 32,
                      ),
                    )
                  : const Icon(
                      Icons.image_outlined,
                      color: Colors.white70,
                      size: 32,
                    ),
            ),
          ],
        ),
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
                  _guideToggleButton(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _albumPreview() {
    return Container(
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

  Widget _guideToggleButton() {
    return GestureDetector(
      onTap: () => setState(() => _isGuideOn = !_isGuideOn),
      child: Container(
        width: 70,
        height: 58,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white70, width: 1.3),
        ),
        alignment: Alignment.center,
        child: Text(
          _isGuideOn ? '가이드\nON' : '가이드\nOFF',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            height: 1.25,
            fontSize: 13,
            fontWeight: FontWeight.w700,
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
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.topCenter,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildTopBar(),
                              _buildGuideCard(),
                            ],
                          ),
                        ),
                      ],
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

