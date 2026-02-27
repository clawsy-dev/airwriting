import 'package:flutter/material.dart';
import '../models/stroke.dart';

enum DrawMode { idle, draw, erase }

class DrawingService extends ChangeNotifier {
  final List<Stroke> _strokes = [];
  final List<Stroke> _undoStack = [];
  Stroke? _currentStroke;

  DrawMode mode = DrawMode.idle;
  Color selectedColor = Colors.cyanAccent;
  double thickness = 5.0;
  double eraserSize = 40.0;

  List<Stroke> get strokes => List.unmodifiable(_strokes);
  Stroke? get currentStroke => _currentStroke;

  void startStroke(Offset point) {
    if (mode == DrawMode.idle) return;
    _currentStroke = Stroke(
      points: [point],
      color: mode == DrawMode.erase ? Colors.transparent : selectedColor,
      thickness: mode == DrawMode.erase ? eraserSize : thickness,
      isEraser: mode == DrawMode.erase,
    );
    notifyListeners();
  }

  void addPoint(Offset point) {
    if (_currentStroke == null || mode == DrawMode.idle) return;
    _currentStroke = _currentStroke!.copyWith(
      points: [..._currentStroke!.points, point],
    );
    notifyListeners();
  }

  void endStroke() {
    if (_currentStroke == null) return;
    if (_currentStroke!.points.length > 1) {
      _strokes.add(_currentStroke!);
      _undoStack.clear();
    }
    _currentStroke = null;
    notifyListeners();
  }

  void undo() {
    if (_strokes.isEmpty) return;
    _undoStack.add(_strokes.removeLast());
    notifyListeners();
  }

  void redo() {
    if (_undoStack.isEmpty) return;
    _strokes.add(_undoStack.removeLast());
    notifyListeners();
  }

  void clear() {
    _strokes.clear();
    _undoStack.clear();
    _currentStroke = null;
    notifyListeners();
  }

  void setMode(DrawMode newMode) {
    mode = newMode;
    notifyListeners();
  }

  void setColor(Color color) {
    selectedColor = color;
    if (mode == DrawMode.idle) mode = DrawMode.draw;
    notifyListeners();
  }

  void setThickness(double t) {
    thickness = t;
    notifyListeners();
  }
}
