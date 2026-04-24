import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A custom clipper that creates a perfect circle from the exact center of the screen.
/// 
/// The [progress] parameter ranges from 0.0 to 1.0.
/// 0.0: Radius is 0. 
/// 1.0: Radius is the maximum distance from center to a corner (fully expanding over the screen).
class ThemeRevealClipper extends CustomClipper<Path> {
  final double progress;

  ThemeRevealClipper({required this.progress});

  @override
  Path getClip(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Max radius needed to cover all four corners of the screen from the center.
    final maxRadius = math.sqrt(math.pow(size.width/2, 2) + math.pow(size.height/2, 2));

    final path = Path()
      ..addOval(Rect.fromCircle(
        center: center,
        radius: maxRadius * progress,
      ));
    
    return path;
  }

  @override
  bool shouldReclip(ThemeRevealClipper oldClipper) => oldClipper.progress != progress;
}
