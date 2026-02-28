import 'package:flutter/material.dart';
import '../models/stroke.dart';
import '../services/drawing_service.dart';

class DrawingCanvas extends StatelessWidget {
  final DrawingService service;
  final Offset? fingerPosition;

  const DrawingCanvas({super.key, required this.service, this.fingerPosition});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: service,
      builder: (_, __) => CustomPaint(
        painter: _CanvasPainter(
          strokes: service.strokes,
          currentStroke: service.currentStroke,
          fingerPosition: fingerPosition,
          mode: service.mode,
          color: service.color,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _CanvasPainter extends CustomPainter {
  final List<Stroke> strokes;
  final Stroke? currentStroke;
  final Offset? fingerPosition;
  final DrawMode mode;
  final Color color;

  const _CanvasPainter({
    required this.strokes,
    this.currentStroke,
    this.fingerPosition,
    required this.mode,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in strokes) _paintStroke(canvas, s);
    if (currentStroke != null) _paintStroke(canvas, currentStroke!);
    if (fingerPosition != null) _paintCursor(canvas, fingerPosition!);
  }

  void _paintStroke(Canvas canvas, Stroke stroke) {
    if (stroke.points.length < 2) return;

    final glowPaint = Paint()
      ..color = stroke.color.withOpacity(0.3)
      ..strokeWidth = stroke.thickness * 3
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
      ..style = PaintingStyle.stroke;

    final paint = Paint()
      ..color = stroke.color
      ..strokeWidth = stroke.thickness
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
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

  void _paintCursor(Canvas canvas, Offset pos) {
    final cursorColor = mode == DrawMode.draw
        ? color
        : mode == DrawMode.erase
            ? Colors.orangeAccent
            : Colors.white54;

    // Outer glow
    canvas.drawCircle(pos, 20,
      Paint()
        ..color = cursorColor.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));

    // Ring
    canvas.drawCircle(pos, 12,
      Paint()
        ..color = cursorColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2);

    // Center dot
    canvas.drawCircle(pos, 4,
      Paint()..color = cursorColor);
  }

  @override
  bool shouldRepaint(_CanvasPainter old) => true;
}
