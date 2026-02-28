import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class HandTracker {
  final PoseDetector _detector = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.base,
    ),
  );

  bool _isBusy = false;

  /// Returns the wrist position on screen (null if not detected).
  /// Uses the wrist landmark — far more reliable than finger landmarks.
  Future<Offset?> processFrame(
    CameraImage image,
    Size screenSize,
    InputImageRotation rotation,
  ) async {
    if (_isBusy) return null;
    _isBusy = true;

    try {
      final inputImage = _buildInputImage(image, rotation);
      if (inputImage == null) return null;

      final poses = await _detector.processImage(inputImage);
      if (poses.isEmpty) return null;

      final pose = poses.first;

      // Try right wrist first, then left — whichever has higher confidence
      final rWrist = pose.landmarks[PoseLandmarkType.rightWrist];
      final lWrist = pose.landmarks[PoseLandmarkType.leftWrist];

      PoseLandmark? best;
      if (rWrist != null && lWrist != null) {
        best = rWrist.likelihood >= lWrist.likelihood ? rWrist : lWrist;
      } else {
        best = rWrist ?? lWrist;
      }

      if (best == null || best.likelihood < 0.3) return null;

      // Map normalized coordinates to screen coordinates
      // x is mirrored for front camera (landmark.x is 0=left in image, but front cam is flipped)
      final x = best.x * screenSize.width;
      final y = best.y * screenSize.height;

      return Offset(x, y);
    } catch (_) {
      return null;
    } finally {
      _isBusy = false;
    }
  }

  InputImage? _buildInputImage(CameraImage image, InputImageRotation rotation) {
    try {
      final bytes = image.planes.fold<List<int>>(
        [],
        (acc, plane) => acc..addAll(plane.bytes),
      );
      return InputImage.fromBytes(
        bytes: Uint8List.fromList(bytes),
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> dispose() async {
    await _detector.close();
  }
}
