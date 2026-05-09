import 'package:flutter/material.dart';

/// Centralized rarity color definitions for badges and items.
/// Use these everywhere to ensure consistent neon glow styling.

/// Returns the neon color for a given rarity tier.
Color getRarityColor(String rarity) {
  switch (rarity.toLowerCase()) {
    case 'common':
      return const Color(0xFF9E9E9E); // grey
    case 'uncommon':
      return const Color(0xFF69F0AE); // green neon
    case 'rare':
      return const Color(0xFF448AFF); // blue neon
    case 'epic':
      return const Color(0xFFE040FB); // purple neon
    case 'legendary':
      return const Color(0xFFFFAB40); // orange neon
    case 'mythic':
      return const Color(0xFFFF4081); // pink neon
    default:
      return const Color(0xFFFFD740); // amber fallback
  }
}

/// Returns a BoxDecoration with a visible neon glow border for the given rarity.
/// [borderRadius] defaults to 16. [isEquipped] intensifies the glow.
BoxDecoration rarityGlowDecoration({
  required String rarity,
  double borderRadius = 16,
  bool isEquipped = false,
  Color? backgroundColor,
}) {
  final color = getRarityColor(rarity);
  final isCommon = rarity.toLowerCase() == 'common';

  return BoxDecoration(
    color: backgroundColor ?? Color.alphaBlend(
      color.withOpacity(isCommon ? 0.04 : 0.10),
      const Color(0xFF16171B),
    ),
    borderRadius: BorderRadius.circular(borderRadius),
    border: Border.all(
      color: color.withOpacity(isEquipped ? 0.85 : 0.55),
      width: isEquipped ? 2.0 : 1.5,
    ),
    boxShadow: [
      // Inner concentrated glow
      BoxShadow(
        color: color.withOpacity(isEquipped ? 0.55 : 0.35),
        blurRadius: isEquipped ? 12 : 8,
        spreadRadius: 0,
      ),
      // Outer diffuse glow (skip for common rarity)
      if (!isCommon)
        BoxShadow(
          color: color.withOpacity(isEquipped ? 0.30 : 0.15),
          blurRadius: isEquipped ? 24 : 16,
          spreadRadius: 1,
        ),
    ],
  );
}

/// Returns a circular BoxDecoration with neon glow for badge icons.
BoxDecoration rarityCircleGlow({
  required String rarity,
  bool isEquipped = false,
}) {
  final color = getRarityColor(rarity);
  return BoxDecoration(
    color: color.withOpacity(0.12),
    shape: BoxShape.circle,
    boxShadow: [
      BoxShadow(
        color: color.withOpacity(isEquipped ? 0.50 : 0.30),
        blurRadius: 20,
        spreadRadius: 1,
      ),
    ],
  );
}
