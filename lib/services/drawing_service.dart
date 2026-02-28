import 'package:flutter/material.dart';
import '../models/stroke.dart';

enum DrawMode { idle, draw, erase }

class DrawingService extends ChangeNotifier {
  final List<Stroke> _strokes = [];
  Stroke? _currentStroke;
  DrawMode _mode = DrawMode.idle;
  Color _color = Colors.cyanAccent;
  double _thickness = 6.0;

  List<Stroke> get strokes => List.unmodifiable(_strokes);
  Stroke? get currentStroke => _currentStroke;
  DrawMode get mode => _mode;
  Color get color => _color;
  double get thickness => _thickness;

  void setMode(DrawMode mode) {
    if (_mode != mode) {
      if (_mode == DrawMode.draw) _commitStroke();
      _mode = mode;
      notifyListeners();
    }
  }

  void setColor(Color c) { _color = c; notifyListeners(); }
  void setThickness(double t) { _thickness = t; notifyListeners(); }

  void addPoint(Offset point) {
    if (_mode != DrawMode.draw) return;
    if (_currentStroke == null) {
      _currentStroke = Stroke(points: [point], color: _color, thickness: _thickness);
    } else {
      _currentStroke = _currentStroke!.copyWith(
        points: [..._currentStroke!.points, point],
      );
    }
    notifyListeners();
  }

  void _commitStroke() {
    if (_currentStroke != null && _currentStroke!.points.length > 1) {
      _strokes.add(_currentStroke!);
    }
    _currentStroke = null;
  }

  void eraseLastStroke() {
    if (_strokes.isNotEmpty) {
      _strokes.removeLast();
      notifyListeners();
    }
  }

  void undo() {
    _commitStroke();
    if (_strokes.isNotEmpty) {
      _strokes.removeLast();
      notifyListeners();
    }
  }

  void clear() {
    _strokes.clear();
    _currentStroke = null;
    notifyListeners();
  }
}
