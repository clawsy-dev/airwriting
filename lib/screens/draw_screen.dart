import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../services/drawing_service.dart';
import '../widgets/drawing_canvas.dart';
import '../widgets/toolbar.dart';

class DrawScreen extends StatefulWidget {
  const DrawScreen({super.key});

  @override
  State<DrawScreen> createState() => _DrawScreenState();
}

class _DrawScreenState extends State<DrawScreen> {
  final DrawingService _drawingService = DrawingService();
  final GlobalKey _canvasKey = GlobalKey();

  Future<Uint8List?> _captureCanvas() async {
    try {
      final boundary = _canvasKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveToGallery() async {
    final bytes = await _captureCanvas();
    if (bytes == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to capture drawing')),
      );
      return;
    }
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/airwriting_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Saved!'),
            backgroundColor: Colors.green.shade800,
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _shareDrawing() async {
    final bytes = await _captureCanvas();
    if (bytes == null) return;
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/airwriting_share.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Made with AirWriting ✨');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Dark gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [Color(0xFF0a0a1a), Color(0xFF000000)],
              ),
            ),
          ),
          // Grid lines (subtle)
          CustomPaint(
            painter: _GridPainter(),
            size: Size.infinite,
          ),
          // Drawing canvas
          RepaintBoundary(
            key: _canvasKey,
            child: DrawingCanvas(service: _drawingService),
          ),
          // Top bar - app name + mode indicator
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // App title
                const Text(
                  'AIR WRITING',
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
                // Mode indicator
                AnimatedBuilder(
                  animation: _drawingService,
                  builder: (context, _) {
                    final modeLabels = {
                      DrawMode.idle: ('⏸ IDLE', Colors.white54),
                      DrawMode.draw: ('✏️ DRAW', Colors.cyanAccent),
                      DrawMode.erase: ('🧹 ERASE', Colors.orangeAccent),
                    };
                    final (label, color) = modeLabels[_drawingService.mode]!;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color.withOpacity(0.5)),
                      ),
                      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
                    );
                  },
                ),
              ],
            ),
          ),
          // Bottom toolbar
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            left: 16,
            right: 16,
            child: Toolbar(
              service: _drawingService,
              onSave: _saveToGallery,
              onShare: _shareDrawing,
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 0.5;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}
