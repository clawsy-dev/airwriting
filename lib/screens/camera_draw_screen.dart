import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../services/drawing_service.dart';
import '../services/hand_tracker.dart';
import '../widgets/drawing_canvas.dart';

class CameraDrawScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const CameraDrawScreen({super.key, required this.cameras});

  @override
  State<CameraDrawScreen> createState() => _CameraDrawScreenState();
}

class _CameraDrawScreenState extends State<CameraDrawScreen> {
  CameraController? _cameraController;
  final DrawingService _drawingService = DrawingService();
  final HandTracker _handTracker = HandTracker();
  final GlobalKey _repaintKey = GlobalKey();

  Offset? _fingerPosition;
  Offset? _smoothedPosition; // EMA-smoothed finger position
  HandGesture _gesture = HandGesture.idle;
  bool _isInitialized = false;
  int _cameraIndex = 1; // front camera

  // Stability buffer — prevents flickering between draw/idle
  int _drawFrameCount = 0;
  int _idleFrameCount = 0;
  int _graceFramesLeft = 0;
  static const int _kStableFrames = 8;   // frames needed to switch TO draw
  static const int _kGraceFrames = 15;   // frames to stay in draw after losing detection
  static const double _kSmoothing = 0.35; // EMA alpha for position (lower = smoother)

  static const _colors = [
    Colors.cyanAccent,
    Colors.redAccent,
    Colors.greenAccent,
    Colors.yellowAccent,
    Colors.purpleAccent,
    Colors.white,
  ];

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    if (widget.cameras.isEmpty) return;
    final idx = _cameraIndex < widget.cameras.length ? _cameraIndex : 0;
    _cameraController = CameraController(
      widget.cameras[idx],
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );
    await _cameraController!.initialize();
    if (!mounted) return;
    setState(() => _isInitialized = true);
    _cameraController!.startImageStream(_onFrame);
  }

  InputImageRotation _getRotation() {
    final camera = widget.cameras[_cameraIndex < widget.cameras.length ? _cameraIndex : 0];
    switch (camera.sensorOrientation) {
      case 90: return InputImageRotation.rotation90deg;
      case 180: return InputImageRotation.rotation180deg;
      case 270: return InputImageRotation.rotation270deg;
      default: return InputImageRotation.rotation0deg;
    }
  }

  void _onFrame(CameraImage image) async {
    if (!mounted) return;
    final size = MediaQuery.of(context).size;
    final result = await _handTracker.processFrame(image, size, _getRotation());
    if (!mounted) return;

    final rawPos = result.fingertip;
    final detected = rawPos != null;

    // ── Smooth finger position with exponential moving average ──
    if (detected) {
      if (_smoothedPosition == null) {
        _smoothedPosition = rawPos;
      } else {
        _smoothedPosition = Offset(
          _smoothedPosition!.dx * (1 - _kSmoothing) + rawPos.dx * _kSmoothing,
          _smoothedPosition!.dy * (1 - _kSmoothing) + rawPos.dy * _kSmoothing,
        );
      }
    }

    // ── Stability buffer: require N consecutive frames before switching ──
    if (detected) {
      _drawFrameCount++;
      _idleFrameCount = 0;
      _graceFramesLeft = _kGraceFrames; // reset grace period
    } else {
      _idleFrameCount++;
      _drawFrameCount = 0;
      if (_graceFramesLeft > 0) _graceFramesLeft--;
    }

    // Determine stable mode
    final bool shouldDraw = _drawFrameCount >= _kStableFrames || _graceFramesLeft > 0;
    final stableGesture = shouldDraw ? HandGesture.draw : HandGesture.idle;

    setState(() {
      _fingerPosition = _smoothedPosition;
      _gesture = stableGesture;
    });

    // ── Update drawing service ──
    if (stableGesture == HandGesture.draw && _smoothedPosition != null) {
      _drawingService.setMode(DrawMode.draw);
      _drawingService.addPoint(_smoothedPosition!);
    } else {
      // Only reset smoothed pos when truly idle (grace expired + no detection)
      if (!detected && _graceFramesLeft == 0) {
        _smoothedPosition = null;
      }
      _drawingService.setMode(DrawMode.idle);
    }
  }

  Future<void> _toggleCamera() async {
    await _cameraController?.stopImageStream();
    await _cameraController?.dispose();
    _cameraController = null;
    _drawFrameCount = 0;
    _idleFrameCount = 0;
    _graceFramesLeft = 0;
    _smoothedPosition = null;
    setState(() {
      _isInitialized = false;
      _fingerPosition = null;
      _gesture = HandGesture.idle;
      _cameraIndex = _cameraIndex == 0 ? 1 : 0;
    });
    await _initCamera();
  }

  Future<Uint8List?> _capture() async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data?.buffer.asUint8List();
    } catch (_) { return null; }
  }

  Future<void> _save() async {
    final bytes = await _capture();
    if (bytes == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/airwriting_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(bytes);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved to ${file.path}'), backgroundColor: Colors.green.shade800),
      );
    }
  }

  Future<void> _share() async {
    final bytes = await _capture();
    if (bytes == null) return;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/airwriting_share.png');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], text: 'Made with AirWriting ✨');
  }

  @override
  void dispose() {
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _handTracker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isInitialized ? _buildMain() : const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.cyanAccent),
            SizedBox(height: 16),
            Text('Starting camera...', style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _buildMain() {
    return Stack(
      children: [
        // Camera preview
        Positioned.fill(
          child: RepaintBoundary(
            key: _repaintKey,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CameraPreview(_cameraController!),
                ),
                // Drawing canvas overlay
                Positioned.fill(
                  child: DrawingCanvas(
                    service: _drawingService,
                    fingerPosition: _fingerPosition,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Top bar
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'AIR WRITING',
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              _GestureBadge(gesture: _gesture),
            ],
          ),
        ),

        // Bottom controls
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 12,
          left: 12,
          right: 12,
          child: _buildToolbar(),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return AnimatedBuilder(
      animation: _drawingService,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.75),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ToolBtn(icon: Icons.undo, label: 'Undo', onTap: _drawingService.undo, color: Colors.white70),
                _ToolBtn(icon: Icons.delete_outline, label: 'Clear', onTap: _drawingService.clear, color: Colors.redAccent),
                _ToolBtn(icon: Icons.save_alt, label: 'Save', onTap: _save, color: Colors.greenAccent),
                _ToolBtn(icon: Icons.share, label: 'Share', onTap: _share, color: Colors.cyanAccent),
                _ToolBtn(icon: Icons.flip_camera_ios, label: 'Flip', onTap: _toggleCamera, color: Colors.white70),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _colors.map((c) => GestureDetector(
                onTap: () => _drawingService.setColor(c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  width: _drawingService.color == c ? 32 : 24,
                  height: _drawingService.color == c ? 32 : 24,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _drawingService.color == c ? Colors.white : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: _drawingService.color == c
                        ? [BoxShadow(color: c.withOpacity(0.8), blurRadius: 10, spreadRadius: 2)]
                        : [],
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.line_weight, color: Colors.white38, size: 16),
                Expanded(
                  child: Slider(
                    value: _drawingService.thickness,
                    min: 2, max: 20,
                    activeColor: _drawingService.color,
                    inactiveColor: Colors.white12,
                    onChanged: _drawingService.setThickness,
                  ),
                ),
                Text(
                  '${_drawingService.thickness.round()}px',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GestureBadge extends StatelessWidget {
  final HandGesture gesture;
  const _GestureBadge({required this.gesture});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (gesture) {
      HandGesture.draw => ('✏️ DRAW', Colors.cyanAccent),
      HandGesture.erase => ('🧹 ERASE', Colors.orangeAccent),
      HandGesture.idle => ('⏸ IDLE', Colors.white38),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _ToolBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  const _ToolBtn({required this.icon, required this.label, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: color, fontSize: 9)),
      ],
    ),
  );
}
