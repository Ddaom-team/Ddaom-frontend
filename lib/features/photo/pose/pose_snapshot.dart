import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PosePoint {
  const PosePoint({
    required this.position,
    required this.likelihood,
    this.inFrame = true,
  });

  final Offset position;
  final double likelihood;

  /// 정규화 좌표가 이미지 안(0~1)에 있어 실제로 화면에 보이는 부위인지.
  /// 상반신만 있는 사진의 추정된 하반신처럼 이미지 밖 좌표는 false.
  final bool inFrame;
}

class PoseSnapshot {
  const PoseSnapshot({
    required this.points,
    required this.imageSize,
  });

  final Map<PoseLandmarkType, PosePoint> points;
  final Size imageSize;

  static PoseSnapshot fromPose({
    required Pose pose,
    required Size rawImageSize,
    required InputImageRotation rotation,
    required CameraLensDirection lensDirection,
  }) {
    final isQuarterTurn =
        rotation == InputImageRotation.rotation90deg ||
        rotation == InputImageRotation.rotation270deg;
    final orientedSize = isQuarterTurn && !Platform.isIOS
        ? Size(rawImageSize.height, rawImageSize.width)
        : rawImageSize;

    const inFrameTolerance = 0.05;
    final points = <PoseLandmarkType, PosePoint>{};
    for (final entry in pose.landmarks.entries) {
      final landmark = entry.value;
      final x = _normalizedX(
        landmark.x,
        rawImageSize,
        rotation,
        lensDirection,
      );
      final y = _normalizedY(landmark.y, rawImageSize, rotation);
      // 정규화 좌표가 이미지 밖이면(상반신 사진에서 추정된 하반신 등) 화면에
      // 보이지 않는 부위이므로 가이드에서 제외할 수 있도록 표시한다.
      final inFrame = x >= -inFrameTolerance &&
          x <= 1 + inFrameTolerance &&
          y >= -inFrameTolerance &&
          y <= 1 + inFrameTolerance;
      points[entry.key] = PosePoint(
        position: Offset(x.clamp(0.0, 1.0), y.clamp(0.0, 1.0)),
        likelihood: landmark.likelihood,
        inFrame: inFrame,
      );
    }

    return PoseSnapshot(points: points, imageSize: orientedSize);
  }

  static double _normalizedX(
    double x,
    Size imageSize,
    InputImageRotation rotation,
    CameraLensDirection lensDirection,
  ) {
    switch (rotation) {
      case InputImageRotation.rotation90deg:
        return x / (Platform.isIOS ? imageSize.width : imageSize.height);
      case InputImageRotation.rotation270deg:
        return 1 -
            x / (Platform.isIOS ? imageSize.width : imageSize.height);
      case InputImageRotation.rotation0deg:
      case InputImageRotation.rotation180deg:
        final normalized = x / imageSize.width;
        return lensDirection == CameraLensDirection.back
            ? normalized
            : 1 - normalized;
    }
  }

  static double _normalizedY(
    double y,
    Size imageSize,
    InputImageRotation rotation,
  ) {
    switch (rotation) {
      case InputImageRotation.rotation90deg:
      case InputImageRotation.rotation270deg:
        return y / (Platform.isIOS ? imageSize.height : imageSize.width);
      case InputImageRotation.rotation0deg:
      case InputImageRotation.rotation180deg:
        return y / imageSize.height;
    }
  }
}
