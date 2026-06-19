import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'pose_snapshot.dart';

class PoseOverlayPainter extends CustomPainter {
  const PoseOverlayPainter({
    required this.reference,
    required this.current,
  });

  final PoseSnapshot? reference;
  final PoseSnapshot? current;

  static const _connections = <(PoseLandmarkType, PoseLandmarkType)>[
    (PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder),
    (PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow),
    (PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist),
    (PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow),
    (PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist),
    (PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip),
    (PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip),
    (PoseLandmarkType.leftHip, PoseLandmarkType.rightHip),
    (PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee),
    (PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle),
    (PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee),
    (PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (reference != null) {
      _drawPose(
        canvas,
        size,
        reference!,
        const Color(0x55FFFFFF),
        2.5,
      );
    }
    if (current != null) {
      _drawPose(
        canvas,
        size,
        current!,
        const Color(0xCCFF5C8A),
        3.5,
      );
    }
  }

  void _drawPose(
    Canvas canvas,
    Size canvasSize,
    PoseSnapshot snapshot,
    Color color,
    double strokeWidth,
  ) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final connection in _connections) {
      final start = snapshot.points[connection.$1];
      final end = snapshot.points[connection.$2];
      if (start == null ||
          end == null ||
          start.likelihood < 0.45 ||
          end.likelihood < 0.45) {
        continue;
      }
      canvas.drawLine(
        _toCanvas(start.position, snapshot.imageSize, canvasSize),
        _toCanvas(end.position, snapshot.imageSize, canvasSize),
        paint,
      );
    }

    paint.style = PaintingStyle.fill;
    for (final point in snapshot.points.values) {
      if (point.likelihood < 0.45) continue;
      canvas.drawCircle(
        _toCanvas(point.position, snapshot.imageSize, canvasSize),
        math.max(2.5, strokeWidth),
        paint,
      );
    }
  }

  Offset _toCanvas(Offset point, Size source, Size canvas) {
    final scale = math.max(
      canvas.width / source.width,
      canvas.height / source.height,
    );
    final renderedWidth = source.width * scale;
    final renderedHeight = source.height * scale;
    final left = (canvas.width - renderedWidth) / 2;
    final top = (canvas.height - renderedHeight) / 2;
    return Offset(
      left + point.dx * renderedWidth,
      top + point.dy * renderedHeight,
    );
  }

  @override
  bool shouldRepaint(covariant PoseOverlayPainter oldDelegate) {
    return oldDelegate.reference != reference || oldDelegate.current != current;
  }
}
