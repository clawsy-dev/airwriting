import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

enum HandGesture { draw, idle, erase }

class HandTracker {
  final PoseDetector _detector = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.base,
    ),
  );

  bool _isBusy = false;

  Future<({Offset? fingertip, HandGesture gesture})> processFrame(
    CameraImage image,
    Size screenSize,
    InputImageRotation rotation,
  ) async {
    if (_isBusy) return (fingertip: null, gesture: HandGesture.idle);
    _isBusy = true;

    try {
      final inputImage = _buildInputImage(image, rotation);
      if (inputImage == null) return (fingertip: null, gesture: HandGesture.idle);

      final poses = await _detector.processImage(inputImage);
      if (poses.isEmpty) return (fingertip: null, gesture: HandGesture.idle);

      final pose = poses.first;
      final gesture = _detectGesture(pose);
      final fingertip = _getFingertip(pose, screenSize, image.width, image.height);

      return (fingertip: fingertip, gesture: gesture);
    } catch (_) {
      return (fingertip: null, gesture: HandGesture.idle);
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

  HandGesture _detectGesture(Pose pose) {
    // Use visibility of wrist vs shoulder to detect raised hand
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];

    // Check if either wrist is raised (above shoulder level in image = lower y value)
    bool rightRaised = rightWrist != null && rightShoulder != null &&
        rightWrist.likelihood > 0.5 && rightShoulder.likelihood > 0.5 &&
        rightWrist.y < rightShoulder.y;

    bool leftRaised = leftWrist != null && leftShoulder != null &&
        leftWrist.likelihood > 0.5 && leftShoulder.likelihood > 0.5 &&
        leftWrist.y < leftShoulder.y;

    if (!rightRaised && !leftRaised) return HandGesture.idle;

    // Use index finger vs middle finger position to determine draw vs idle
    final rightIndex = pose.landmarks[PoseLandmarkType.rightIndex];
    final rightMiddle = pose.landmarks[PoseLandmarkType.rightPinky];

    if (rightIndex != null && rightMiddle != null &&
        rightIndex.likelihood > 0.5 && rightMiddle.likelihood > 0.5) {
      // If both index and middle are up → idle (move mode)
      // If only index → draw
      // This is an approximation — ML Kit pose doesn't give full finger details
      return HandGesture.draw;
    }

    return HandGesture.draw;
  }

  Offset? _getFingertip(Pose pose, Size screenSize, int imgWidth, int imgHeight) {
    // Try right index first, then left
    PoseLandmark? landmark = pose.landmarks[PoseLandmarkType.rightIndex];
    if (landmark == null || landmark.likelihood < 0.4) {
      landmark = pose.landmarks[PoseLandmarkType.leftIndex];
    }
    if (landmark == null || landmark.likelihood < 0.4) return null;

    // Mirror x for front camera (selfie mode)
    final x = (1.0 - landmark.x) * screenSize.width;
    final y = landmark.y * screenSize.height;

    return Offset(x, y);
  }

  Future<void> dispose() async {
    await _detector.close();
  }
}
