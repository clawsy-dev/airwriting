import 'package:flutter/material.dart';
import '../models/stroke.dart';
import '../services/drawing_service.dart';

class DrawingCanvas extends StatelessWidget {
  final DrawingService service;

  const DrawingCanvas({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: service,
      builder: (context, _) {
        return GestureDetector(
          onPanStart: (d) => service.startStroke(d.localPosition),
          onPanUpdate: (d) => service.addPoint(d.localPosition),
          onPanEnd: (_) => service.endStroke(),
          child: CustomPaint(
            painter: _CanvasPainter(
              strokes: service.strokes,
              currentStroke: service.currentStroke,
            ),
            child: Container(color: Colors.transparent),
          ),
        );
      },
    );
  }
}

class _CanvasPainter extends CustomPainter {
  final List<Stroke> strokes;
  final Stroke? currentStroke;

  _CanvasPainter({required this.strokes, this.currentStroke});

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in [...strokes, if (currentStroke != null) currentStroke!]) {
      _drawStroke(canvas, stroke);
    }
  }

  void _drawStroke(Canvas canvas, Stroke stroke) {
    if (stroke.points.length < 2) return;
    final paint = Paint()
      ..color = stroke.isEraser ? Colors.transparent : stroke.color
      ..strokeWidth = stroke.thickness
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..blendMode = stroke.isEraser ? BlendMode.clear : BlendMode.srcOver;

    if (stroke.isEraser) {
      final eraserPaint = Paint()
        ..color = Colors.transparent
        ..strokeWidth = stroke.thickness
        ..strokeCap = StrokeCap.round
        ..blendMode = BlendMode.clear
        ..style = PaintingStyle.stroke;
      final path = Path()..moveTo(stroke.points.first.dx, stroke.points.first.dy);
      for (int i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
      }
      canvas.drawPath(path, eraserPaint);
      return;
    }

    // Draw with glow effect
    final glowPaint = Paint()
      ..color = stroke.color.withOpacity(0.3)
      ..strokeWidth = stroke.thickness * 2.5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
      ..style = PaintingStyle.stroke;

    final path = Path()..moveTo(stroke.points.first.dx, stroke.points.first.dy);
    for (int i = 1; i < stroke.points.length - 1; i++) {
      final mid = Offset(
        (stroke.points[i].dx + stroke.points[i + 1].dx) / 2,
        (stroke.points[i].dy + stroke.points[i + 1].dy) / 2,
      );
      path.quadraticBezierTo(stroke.points[i].dx, stroke.points[i].dy, mid.dx, mid.dy);
    }
    path.lineTo(stroke.points.last.dx, stroke.points.last.dy);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CanvasPainter old) => true;
}
