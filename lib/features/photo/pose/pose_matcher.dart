import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'pose_snapshot.dart';

class PoseGuideResult {
  const PoseGuideResult({
    required this.message,
    required this.score,
    required this.color,
    required this.ready,
  });

  final String message;
  final double score;
  final Color color;
  final bool ready;
}

class PoseMatcher {
  static const _minimumLikelihood = 0.45;

  PoseGuideResult compare(PoseSnapshot reference, PoseSnapshot current) {
    final referenceBounds = _bounds(reference);
    final currentBounds = _bounds(current);
    if (referenceBounds == null || currentBounds == null) {
      return const PoseGuideResult(
        message: '전신이 보이도록 카메라를 맞춰주세요',
        score: 0,
        color: Colors.orange,
        ready: false,
      );
    }

    final dx = currentBounds.center.dx - referenceBounds.center.dx;
    final dy = currentBounds.center.dy - referenceBounds.center.dy;
    final referenceHeight = math.max(referenceBounds.height, 0.01);
    final scaleRatio = currentBounds.height / referenceHeight;
    final poseError = _normalizedPoseError(
      reference,
      current,
      referenceBounds,
      currentBounds,
    );

    final positionScore =
        (1 - math.min(1.0, math.sqrt(dx * dx + dy * dy) / 0.25));
    final scaleScore =
        (1 - math.min(1.0, (math.log(scaleRatio).abs() / math.log(1.8))));
    final shapeScore = 1 - math.min(1.0, poseError / 0.34);
    final score =
        (positionScore * 0.25 + scaleScore * 0.2 + shapeScore * 0.55)
            .clamp(0.0, 1.0);

    if (scaleRatio > 1.22) {
      return _result('조금 뒤로 이동해주세요', score);
    }
    if (scaleRatio < 0.80) {
      return _result('조금 앞으로 이동해주세요', score);
    }
    if (dx < -0.07) {
      return _result('오른쪽으로 이동해주세요', score);
    }
    if (dx > 0.07) {
      return _result('왼쪽으로 이동해주세요', score);
    }
    if (dy < -0.07) {
      return _result('조금 아래로 이동해주세요', score);
    }
    if (dy > 0.07) {
      return _result('조금 위로 이동해주세요', score);
    }
    if (poseError > 0.18) {
      return _result(_jointInstruction(reference, current), score);
    }

    return PoseGuideResult(
      message: '좋아요! 이 구도로 촬영해보세요',
      score: score,
      color: const Color(0xFF51D88A),
      ready: true,
    );
  }

  PoseGuideResult _result(String message, double score) {
    return PoseGuideResult(
      message: message,
      score: score,
      color: score >= 0.68 ? Colors.amber : const Color(0xFFFF8A65),
      ready: false,
    );
  }

  Rect? _bounds(PoseSnapshot snapshot) {
    final visible = snapshot.points.values
        .where((point) => point.likelihood >= _minimumLikelihood)
        .map((point) => point.position)
        .toList();
    if (visible.length < 8) return null;

    var left = 1.0;
    var top = 1.0;
    var right = 0.0;
    var bottom = 0.0;
    for (final point in visible) {
      left = math.min(left, point.dx);
      top = math.min(top, point.dy);
      right = math.max(right, point.dx);
      bottom = math.max(bottom, point.dy);
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }

  double _normalizedPoseError(
    PoseSnapshot reference,
    PoseSnapshot current,
    Rect referenceBounds,
    Rect currentBounds,
  ) {
    const important = {
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.rightElbow,
      PoseLandmarkType.leftWrist,
      PoseLandmarkType.rightWrist,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.rightKnee,
      PoseLandmarkType.leftAnkle,
      PoseLandmarkType.rightAnkle,
    };

    var total = 0.0;
    var count = 0;
    for (final type in important) {
      final target = reference.points[type];
      final live = current.points[type];
      if (target == null ||
          live == null ||
          target.likelihood < _minimumLikelihood ||
          live.likelihood < _minimumLikelihood) {
        continue;
      }
      final targetPoint = _withinBounds(target.position, referenceBounds);
      final livePoint = _withinBounds(live.position, currentBounds);
      total += (targetPoint - livePoint).distance;
      count++;
    }
    return count == 0 ? 1 : total / count;
  }

  Offset _withinBounds(Offset point, Rect bounds) {
    return Offset(
      (point.dx - bounds.left) / math.max(bounds.width, 0.01),
      (point.dy - bounds.top) / math.max(bounds.height, 0.01),
    );
  }

  String _jointInstruction(
    PoseSnapshot reference,
    PoseSnapshot current,
  ) {
    final armError = _groupError(reference, current, const {
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.rightElbow,
      PoseLandmarkType.leftWrist,
      PoseLandmarkType.rightWrist,
    });
    final legError = _groupError(reference, current, const {
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.rightKnee,
      PoseLandmarkType.leftAnkle,
      PoseLandmarkType.rightAnkle,
    });
    return armError >= legError ? '팔 자세를 사진처럼 맞춰보세요' : '다리 자세를 사진처럼 맞춰보세요';
  }

  double _groupError(
    PoseSnapshot reference,
    PoseSnapshot current,
    Set<PoseLandmarkType> types,
  ) {
    var total = 0.0;
    var count = 0;
    for (final type in types) {
      final target = reference.points[type];
      final live = current.points[type];
      if (target == null || live == null) continue;
      total += (target.position - live.position).distance;
      count++;
    }
    return count == 0 ? 0 : total / count;
  }
}
