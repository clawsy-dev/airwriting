import 'package:flutter/material.dart';

class Stroke {
  final List<Offset> points;
  final Color color;
  final double thickness;
  final bool isEraser;

  const Stroke({
    required this.points,
    required this.color,
    required this.thickness,
    this.isEraser = false,
  });

  Stroke copyWith({List<Offset>? points}) => Stroke(
    points: points ?? this.points,
    color: color,
    thickness: thickness,
    isEraser: isEraser,
  );
}
