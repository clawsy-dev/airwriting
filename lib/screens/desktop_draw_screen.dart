import 'package:flutter/material.dart';
import '../services/drawing_service.dart';
import '../widgets/drawing_canvas.dart';

/// Desktop test screen — no camera, pure touch/mouse drawing
/// Used to verify canvas rendering before testing on Android
class DesktopDrawScreen extends StatefulWidget {
  const DesktopDrawScreen({super.key});

  @override
  State<DesktopDrawScreen> createState() => _DesktopDrawScreenState();
}

class _DesktopDrawScreenState extends State<DesktopDrawScreen> {
  final DrawingService _service = DrawingService();
  Offset? _cursor;

  static const _colors = [
    Colors.cyanAccent,
    Colors.redAccent,
    Colors.greenAccent,
    Colors.yellowAccent,
    Colors.purpleAccent,
    Colors.white,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a1a),
      body: Stack(
        children: [
          // Grid background
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),

          // Drawing canvas — touch/mouse input
          Positioned.fill(
            child: GestureDetector(
              onPanStart: (d) {
                _service.setMode(DrawMode.draw);
                _service.addPoint(d.localPosition);
                setState(() => _cursor = d.localPosition);
              },
              onPanUpdate: (d) {
                _service.addPoint(d.localPosition);
                setState(() => _cursor = d.localPosition);
              },
              onPanEnd: (_) {
                _service.commitCurrentStroke();
                setState(() => _cursor = null);
              },
              child: DrawingCanvas(
                service: _service,
                fingerPosition: _cursor,
                isDetecting: _cursor != null,
              ),
            ),
          ),

          // Header
          Positioned(
            top: 16, left: 20, right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('AIR WRITING — DESKTOP TEST',
                  style: TextStyle(color: Colors.cyanAccent, fontSize: 14,
                      fontWeight: FontWeight.bold, letterSpacing: 3)),
                const Text('Draw with mouse to test canvas',
                    style: TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),

          // Bottom toolbar
          Positioned(
            bottom: 16, left: 16, right: 16,
            child: AnimatedBuilder(
              animation: _service,
              builder: (_, __) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                    _btn(Icons.undo, 'Undo', _service.undo, Colors.white70),
                    _btn(Icons.delete_outline, 'Clear', _service.clear, Colors.redAccent),
                  ]),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.center,
                    children: _colors.map((c) => GestureDetector(
                      onTap: () => _service.setColor(c),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        width: _service.color == c ? 32 : 24,
                        height: _service.color == c ? 32 : 24,
                        decoration: BoxDecoration(
                          color: c, shape: BoxShape.circle,
                          border: Border.all(
                            color: _service.color == c ? Colors.white : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.line_weight, color: Colors.white38, size: 16),
                    Expanded(
                      child: Slider(
                        value: _service.thickness,
                        min: 2, max: 20,
                        activeColor: _service.color,
                        inactiveColor: Colors.white12,
                        onChanged: _service.setThickness,
                      ),
                    ),
                    Text('${_service.thickness.round()}px',
                        style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  ]),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, String label, VoidCallback onTap, Color color) =>
    GestureDetector(
      onTap: onTap,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 12)),
      ]),
    );
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withOpacity(0.04)..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }
  @override
  bool shouldRepaint(_GridPainter _) => false;
}
