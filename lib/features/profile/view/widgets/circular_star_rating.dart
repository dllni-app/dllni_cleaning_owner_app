import 'dart:math' as math;

import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';

class CircularStarRating extends StatelessWidget {
  const CircularStarRating({
    super.key,
    required this.rating,
    this.starSize = 20,
    this.orbitRadius = 20,
    this.color = const Color(0xffFAE13D),
    this.emptyColor = const Color(0x66FAE13D),
  });

  final double rating;
  final double starSize;
  final double orbitRadius;
  final Color color;
  final Color emptyColor;

  @override
  Widget build(BuildContext context) {
    final clampedRating = rating.clamp(0.0, 5.0);
    final boxSize = (orbitRadius + starSize) * 2;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: boxSize,
          height: boxSize,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (var index = 0; index < 5; index++)
                _buildStar(index, boxSize, clampedRating),
            ],
          ),
        ),
        AppText.labelMedium(
          clampedRating.toStringAsFixed(1),
          color: context.onPrimary,
          fontWeight: FontWeight.w600,
        ),
      ],
    );
  }

  Widget _buildStar(int index, double boxSize, double clampedRating) {
    final angle = -math.pi / 2 + index * (2 * math.pi / 5);
    final center = boxSize / 2;
    final left = center + orbitRadius * math.cos(angle) - starSize / 2;
    final top = center + orbitRadius * math.sin(angle) - starSize / 2;
    final starValue = index + 1;

    return Positioned(
      left: left,
      top: top,
      child: Icon(
        _iconForStar(starValue, clampedRating),
        size: starSize,
        color: _colorForStar(starValue, clampedRating),
      ),
    );
  }

  IconData _iconForStar(int starValue, double clampedRating) {
    if (clampedRating >= starValue) {
      return Icons.star_rounded;
    }
    if (clampedRating >= starValue - 0.5) {
      return Icons.star_half_rounded;
    }
    return Icons.star_outline_rounded;
  }

  Color _colorForStar(int starValue, double clampedRating) {
    if (clampedRating >= starValue - 0.5) {
      return color;
    }
    return emptyColor;
  }
}
