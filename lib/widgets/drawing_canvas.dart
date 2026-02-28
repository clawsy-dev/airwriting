import 'package:flutter/material.dart';
import '../models/stroke.dart';
import '../services/drawing_service.dart';

class DrawingCanvas extends StatelessWidget {
  final DrawingService service;
  final Offset? fingerPosition;
  final bool isDetecting;

  const DrawingCanvas({
    super.key,
    required this.service,
    this.fingerPosition,
    this.isDetecting = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: service,
      builder: (_, __) => SizedBox.expand(
        child: CustomPaint(
          painter: _CanvasPainter(
            strokes: service.strokes,
            currentStroke: service.currentStroke,
            fingerPosition: fingerPosition,
            isDetecting: isDetecting,
            mode: service.mode,
            color: service.color,
          ),
        ),
      ),
    );
  }
}

class _CanvasPainter extends CustomPainter {
  final List<Stroke> strokes;
  final Stroke? currentStroke;
  final Offset? fingerPosition;
  final bool isDetecting;
  final DrawMode mode;
  final Color color;

  const _CanvasPainter({
    required this.strokes,
    this.currentStroke,
    this.fingerPosition,
    required this.isDetecting,
    required this.mode,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw all committed strokes
    for (final s in strokes) {
      _paintStroke(canvas, s);
    }
    // Draw current in-progress stroke
    if (currentStroke != null) {
      _paintStroke(canvas, currentStroke!);
    }
    // Draw cursor where hand is
    if (fingerPosition != null) {
      _paintCursor(canvas, fingerPosition!);
    }
  }

  void _paintStroke(Canvas canvas, Stroke stroke) {
    if (stroke.points.length < 2) return;

    // Thick outer glow
    final glowPaint = Paint()
      ..color = stroke.color.withOpacity(0.5)
      ..strokeWidth = stroke.thickness * 4
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
      ..style = PaintingStyle.stroke;

    // Solid bright stroke
    final paint = Paint()
      ..color = stroke.color
      ..strokeWidth = stroke.thickness
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // White core for extra visibility
    final corePaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = stroke.thickness * 0.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(stroke.points.first.dx, stroke.points.first.dy);

    for (int i = 1; i < stroke.points.length - 1; i++) {
      final mid = Offset(
        (stroke.points[i].dx + stroke.points[i + 1].dx) / 2,
        (stroke.points[i].dy + stroke.points[i + 1].dy) / 2,
      );
      path.quadraticBezierTo(
          stroke.points[i].dx, stroke.points[i].dy, mid.dx, mid.dy);
    }
    path.lineTo(stroke.points.last.dx, stroke.points.last.dy);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);
    canvas.drawPath(path, corePaint);
  }

  void _paintCursor(Canvas canvas, Offset pos) {
    final cursorColor = mode == DrawMode.draw
        ? color
        : mode == DrawMode.erase
            ? Colors.orangeAccent
            : Colors.white70;

    // Big outer pulse ring
    canvas.drawCircle(
        pos,
        24,
        Paint()
          ..color = cursorColor.withOpacity(0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14));

    // Solid ring
    canvas.drawCircle(
        pos,
        14,
        Paint()
          ..color = cursorColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5);

    // Center fill dot
    canvas.drawCircle(pos, 5, Paint()..color = cursorColor);

    // White center sparkle
    canvas.drawCircle(pos, 2, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_CanvasPainter old) => true;
}
