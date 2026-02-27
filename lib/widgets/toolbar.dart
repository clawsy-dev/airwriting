import 'package:flutter/material.dart';
import '../services/drawing_service.dart';

class Toolbar extends StatelessWidget {
  final DrawingService service;
  final VoidCallback onSave;
  final VoidCallback onShare;

  const Toolbar({
    super.key,
    required this.service,
    required this.onSave,
    required this.onShare,
  });

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
    return AnimatedBuilder(
      animation: service,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.75),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Mode buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ModeButton(label: '✏️', mode: DrawMode.draw, service: service),
                  const SizedBox(width: 8),
                  _ModeButton(label: '🧹', mode: DrawMode.erase, service: service),
                  const SizedBox(width: 8),
                  _ModeButton(label: '⏸️', mode: DrawMode.idle, service: service),
                  const SizedBox(width: 16),
                  // Undo
                  _IconBtn(icon: Icons.undo, onTap: service.undo, tooltip: 'Undo'),
                  const SizedBox(width: 8),
                  // Clear
                  _IconBtn(icon: Icons.delete_outline, onTap: service.clear, tooltip: 'Clear', color: Colors.redAccent),
                  const SizedBox(width: 8),
                  // Save
                  _IconBtn(icon: Icons.save_alt, onTap: onSave, tooltip: 'Save', color: Colors.greenAccent),
                  const SizedBox(width: 8),
                  // Share
                  _IconBtn(icon: Icons.share, onTap: onShare, tooltip: 'Share', color: Colors.cyanAccent),
                ],
              ),
              const SizedBox(height: 8),
              // Color palette
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _colors.map((c) => GestureDetector(
                  onTap: () => service.setColor(c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: service.selectedColor == c ? 32 : 24,
                    height: service.selectedColor == c ? 32 : 24,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: service.selectedColor == c ? Colors.white : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: service.selectedColor == c ? [
                        BoxShadow(color: c.withOpacity(0.7), blurRadius: 8, spreadRadius: 2),
                      ] : [],
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 6),
              // Thickness slider
              Row(
                children: [
                  const Icon(Icons.line_weight, color: Colors.white54, size: 16),
                  Expanded(
                    child: Slider(
                      value: service.thickness,
                      min: 2,
                      max: 20,
                      activeColor: service.selectedColor,
                      inactiveColor: Colors.white24,
                      onChanged: service.setThickness,
                    ),
                  ),
                  Text('${service.thickness.round()}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final DrawMode mode;
  final DrawingService service;

  const _ModeButton({required this.label, required this.mode, required this.service});

  @override
  Widget build(BuildContext context) {
    final active = service.mode == mode;
    return GestureDetector(
      onTap: () => service.setMode(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? Colors.cyanAccent.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? Colors.cyanAccent : Colors.white24),
        ),
        child: Text(label, style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final Color color;

  const _IconBtn({required this.icon, required this.onTap, required this.tooltip, this.color = Colors.white70});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}
