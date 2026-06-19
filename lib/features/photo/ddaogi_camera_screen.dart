import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'photo_selection_screen.dart';
import 'photo_models.dart';
import 'pose/pose_matcher.dart';
import 'pose/pose_overlay_painter.dart';
import 'pose/pose_snapshot.dart';
import '../place/place_models.dart';

class DdaogiCameraScreen extends StatefulWidget {
  final PhotoZone? photoZone;
  final String? referencePhotoUrl;
  final PhotoType? photoType;

  const DdaogiCameraScreen({
    super.key,
    this.photoZone,
    this.referencePhotoUrl,
    this.photoType,
  });

  @override
  State<DdaogiCameraScreen> createState() => _DdaogiCameraScreenState();
}

class _DdaogiCameraScreenState extends State<DdaogiCameraScreen> {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  CameraDescription? _activeCamera;

  int _selectedCameraIndex = 0;
  bool _isInitialized = false;
  bool _isGuideOn = true;
  bool _isTakingPicture = false;
  bool _isSaving = false;
  bool _isProcessingFrame = false;
  bool _isReferenceLoading = false;
  bool _isReferencePreviewExpanded = false;

  double _currentZoom = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  double _baseZoomForGesture = 1.0;

  CameraDescription? _ultraWideCamera;
  bool _isUltraWide = false;

  int _cameraVersion = 0;

  XFile? _lastPhoto;
  File? _referenceFile;
  PoseSnapshot? _referencePose;
  PoseSnapshot? _currentPose;
  String? _referenceError;

  final PoseDetector _referenceDetector = PoseDetector(
    options: PoseDetectorOptions(
      model: PoseDetectionModel.accurate,
      mode: PoseDetectionMode.single,
    ),
  );
  final PoseDetector _liveDetector = PoseDetector(
    options: PoseDetectorOptions(
      model: PoseDetectionModel.base,
      mode: PoseDetectionMode.stream,
    ),
  );
  final PoseMatcher _poseMatcher = PoseMatcher();

  PoseGuideResult _guideResult = const PoseGuideResult(
    message: '카메라 앞에 서주세요',
    score: 0,
    color: Colors.orange,
    ready: false,
  );

  static const _orientations = <DeviceOrientation, int>{
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  bool get _usesPoseGuide =>
      widget.photoType == PhotoType.FULL_BODY ||
      widget.photoType == PhotoType.UPPER_BODY;

  bool get _usesCompositionGuide =>
      widget.referencePhotoUrl != null &&
      widget.referencePhotoUrl!.isNotEmpty &&
      !_usesPoseGuide;

  bool get _isUpperBodyGuide => widget.photoType == PhotoType.UPPER_BODY;

  String get _compositionGuideMessage {
    switch (widget.photoType) {
      case PhotoType.SELFIE:
        return '얼굴 위치와 기울기를 원본에 맞춰보세요';
      case PhotoType.FOOD:
        return '접시 위치와 촬영 각도를 원본에 맞춰보세요';
      case PhotoType.LANDSCAPE:
        return '수평선과 주요 배경 위치를 원본에 맞춰보세요';
      case PhotoType.ETC:
      case null:
        return '반투명 원본에 구도를 맞춰보세요';
      case PhotoType.FULL_BODY:
      case PhotoType.UPPER_BODY:
        return _guideResult.message;
    }
  }

  // 카메라를 나갈 때 한꺼번에 등록하기 위해 촬영분을 누적한다.
  final List<XFile> _captured = [];

  @override
  void initState() {
    super.initState();
    if (_usesPoseGuide) {
      _loadReferencePose();
    }
    _initCamera();
  }

  Future<void> _loadReferencePose() async {
    final url = widget.referencePhotoUrl;
    if (url == null || url.isEmpty) {
      setState(() => _referenceError = '참조 사진이 없어 기본 가이드로 촬영합니다');
      return;
    }

    setState(() {
      _isReferenceLoading = true;
      _referenceError = null;
    });

    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('사진 다운로드 실패 (${response.statusCode})');
      }
      final bytes = await response.fold<List<int>>(
        <int>[],
        (buffer, chunk) => buffer..addAll(chunk),
      );
      client.close(force: true);

      final file = File(
        '${Directory.systemTemp.path}${Platform.pathSeparator}'
        'ddaom_reference_${DateTime.now().microsecondsSinceEpoch}.jpg',
      );
      await file.writeAsBytes(bytes, flush: true);

      final codec = await ui.instantiateImageCodec(Uint8List.fromList(bytes));
      final frame = await codec.getNextFrame();
      final imageSize = Size(
        frame.image.width.toDouble(),
        frame.image.height.toDouble(),
      );
      frame.image.dispose();
      codec.dispose();

      final poses = await _referenceDetector.processImage(
        InputImage.fromFilePath(file.path),
      );
      if (poses.isEmpty) {
        await file.delete();
        if (!mounted) return;
        setState(() {
          _referenceError = '참조 사진에서 사람의 포즈를 찾지 못했어요';
          _isReferenceLoading = false;
        });
        return;
      }

      final snapshot = PoseSnapshot.fromPose(
        pose: poses.first,
        rawImageSize: imageSize,
        rotation: InputImageRotation.rotation0deg,
        lensDirection: CameraLensDirection.back,
      );
      if (!mounted) {
        await file.delete();
        return;
      }
      setState(() {
        _referenceFile = file;
        _referencePose = snapshot;
        _isReferenceLoading = false;
      });
    } catch (e) {
      debugPrint('참조 포즈 분석 실패: $e');
      if (!mounted) return;
      setState(() {
        _referenceError = '참조 사진 분석에 실패했어요';
        _isReferenceLoading = false;
      });
    }
  }

  // 찍은 사진이 있으면 선택 화면으로, 없으면 그냥 카메라를 닫는다.
  Future<void> _onExit() async {
    if (_captured.isEmpty) {
      Navigator.maybePop(context);
      return;
    }
    await _openSelection();
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

    if (oldController?.value.isStreamingImages == true) {
      try {
        await oldController?.stopImageStream();
      } catch (_) {}
    }
    await oldController?.dispose();

    if (!mounted || _cameraVersion != myVersion) return;

    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
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
        _activeCamera = camera;
        _isInitialized = true;
        _minZoom = minZoom;
        _maxZoom = maxZoom;
        _currentZoom = _isUltraWide ? 0.5 : 1.0;
      });
      await _startPoseStream(controller, camera);
    } catch (e) {
      debugPrint('카메라 시작 실패: $e');
      if (_cameraVersion == myVersion) await controller.dispose();
    }
  }

  Future<void> _startPoseStream(
    CameraController controller,
    CameraDescription camera,
  ) async {
    if (!_usesPoseGuide ||
        !_isGuideOn ||
        !controller.value.isInitialized ||
        controller.value.isStreamingImages) {
      return;
    }
    try {
      await controller.startImageStream(
        (image) => _processCameraImage(image, controller, camera),
      );
    } catch (e) {
      debugPrint('포즈 이미지 스트림 시작 실패: $e');
    }
  }

  Future<void> _stopPoseStream() async {
    final controller = _controller;
    if (controller == null || !controller.value.isStreamingImages) return;
    try {
      await controller.stopImageStream();
    } catch (e) {
      debugPrint('포즈 이미지 스트림 중지 실패: $e');
    }
  }

  Future<void> _setGuideEnabled(bool enabled) async {
    if (_isGuideOn == enabled) return;
    setState(() {
      _isGuideOn = enabled;
      if (!enabled) {
        _currentPose = null;
      }
    });

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (enabled) {
      final camera = _activeCamera;
      if (_usesPoseGuide && camera != null) {
        await _startPoseStream(controller, camera);
      }
    } else {
      await _stopPoseStream();
    }
  }

  Future<void> _processCameraImage(
    CameraImage image,
    CameraController controller,
    CameraDescription camera,
  ) async {
    if (!_isGuideOn ||
        !_usesPoseGuide ||
        _isProcessingFrame ||
        controller != _controller ||
        !mounted) {
      return;
    }

    final input = _inputImageFromCameraImage(image, controller, camera);
    if (input == null) return;

    _isProcessingFrame = true;
    try {
      final poses = await _liveDetector.processImage(input);
      if (!mounted || controller != _controller || !_isGuideOn) return;

      if (poses.isEmpty) {
        setState(() {
          _currentPose = null;
          _guideResult = const PoseGuideResult(
            message: '카메라 앞에 전신이 보이도록 서주세요',
            score: 0,
            color: Colors.orange,
            ready: false,
          );
        });
        return;
      }

      final metadata = input.metadata!;
      final snapshot = PoseSnapshot.fromPose(
        pose: poses.first,
        rawImageSize: metadata.size,
        rotation: metadata.rotation,
        lensDirection: camera.lensDirection,
      );
      final reference = _referencePose;
      final result = reference == null
          ? const PoseGuideResult(
              message: '포즈를 인식했어요. 원하는 구도로 촬영하세요',
              score: 0,
              color: Color(0xFF51D88A),
              ready: true,
            )
          : _poseMatcher.compare(
              reference,
              snapshot,
              upperBodyOnly: _isUpperBodyGuide,
            );

      setState(() {
        _currentPose = snapshot;
        _guideResult = result;
      });
    } catch (e) {
      debugPrint('실시간 포즈 분석 실패: $e');
    } finally {
      _isProcessingFrame = false;
    }
  }

  InputImage? _inputImageFromCameraImage(
    CameraImage image,
    CameraController controller,
    CameraDescription camera,
  ) {
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;

    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else {
      var compensation = _orientations[controller.value.deviceOrientation];
      if (compensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        compensation = (sensorOrientation + compensation) % 360;
      } else {
        compensation = (sensorOrientation - compensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(compensation);
    }
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    final isSupported = Platform.isAndroid
        ? format == InputImageFormat.nv21
        : format == InputImageFormat.bgra8888;
    if (!isSupported || image.planes.length != 1) return null;

    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format!,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
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

    final shouldRestartStream = _isGuideOn;
    try {
      setState(() => _isTakingPicture = true);
      await _stopPoseStream();
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
      final controller = _controller;
      final camera = _activeCamera;
      if (shouldRestartStream &&
          controller != null &&
          camera != null &&
          controller.value.isInitialized &&
          !controller.value.isStreamingImages) {
        await _startPoseStream(controller, camera);
      }
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

  Widget _buildGuideHud() {
    if (!_isGuideOn) return const SizedBox.shrink();

    final message = _isReferenceLoading
        ? '참조 사진을 분석하고 있어요'
        : (_referenceError ??
              (_usesCompositionGuide
                  ? _compositionGuideMessage
                  : _guideResult.message));
    final statusColor = _referenceError == null
        ? (_usesCompositionGuide ? Colors.white : _guideResult.color)
        : Colors.orangeAccent;

    return Container(
      constraints: const BoxConstraints(maxWidth: 360),
      padding: const EdgeInsets.fromLTRB(12, 9, 10, 9),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _usesCompositionGuide
                  ? Icons.filter_center_focus
                  : (_guideResult.ready
                        ? Icons.check_rounded
                        : Icons.directions_run),
              color: statusColor,
              size: 17,
            ),
          ),
          const SizedBox(width: 9),
          Flexible(
            child: Text(
              message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (_usesPoseGuide && _referencePose != null) ...[
            const SizedBox(width: 10),
            Text(
              '${(_guideResult.score * 100).round()}%',
              style: TextStyle(
                color: statusColor,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReferencePreview() {
    final url = widget.referencePhotoUrl;
    if (!_isGuideOn || url == null || url.isEmpty) {
      return const SizedBox.shrink();
    }

    final expanded = _isReferencePreviewExpanded;
    return GestureDetector(
      onTap: () => setState(
        () => _isReferencePreviewExpanded = !expanded,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: expanded ? 132 : 54,
        height: expanded ? 176 : 72,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(expanded ? 16 : 12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const ColoredBox(
                color: Colors.black38,
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: Colors.white70,
                ),
              ),
            ),
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.58),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  expanded ? Icons.close_fullscreen : Icons.open_in_full,
                  color: Colors.white,
                  size: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraShade() {
    return IgnorePointer(
      child: Column(
        children: [
          Container(
            height: 92,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const Spacer(),
          Container(
            height: 92,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompositionOverlay() {
    final url = widget.referencePhotoUrl;
    if (!_isGuideOn || !_usesCompositionGuide || url == null || url.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: 0.18,
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
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
    return GestureDetector(
      onTap: _captured.isEmpty ? null : _openSelection,
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

  Widget _guideToggleButton() {
    return GestureDetector(
      onTap: () => _setGuideEnabled(!_isGuideOn),
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
    unawaited(_referenceDetector.close());
    unawaited(_liveDetector.close());
    final referenceFile = _referenceFile;
    if (referenceFile != null) {
      unawaited(
        referenceFile.delete().then<void>((_) {}).catchError((_) {}),
      );
    }
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
                  _buildCompositionOverlay(),
                  _buildCameraShade(),
                  if (_isGuideOn && _usesPoseGuide)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: PoseOverlayPainter(
                            reference: _referencePose,
                            current: _currentPose,
                          ),
                        ),
                      ),
                    ),
                  SafeArea(
                    bottom: false,
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.topCenter,
                          child: _buildTopBar(),
                        ),
                        Positioned(
                          top: 68,
                          right: 16,
                          child: _buildReferencePreview(),
                        ),
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 14,
                          child: Center(child: _buildGuideHud()),
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

