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

/// Returns a BoxDecoration with a mild neon glow border for the given rarity.
/// [borderRadius] defaults to 16. [isEquipped] intensifies the glow slightly.
BoxDecoration rarityGlowDecoration({
  required String rarity,
  double borderRadius = 16,
  bool isEquipped = false,
  Color? backgroundColor,
}) {
  final color = getRarityColor(rarity);
  final glowOpacity = isEquipped ? 0.45 : 0.25;
  final borderOpacity = isEquipped ? 0.7 : 0.4;

  return BoxDecoration(
    color: backgroundColor ?? Color.alphaBlend(
      color.withOpacity(0.06),
      const Color(0xFF16171B),
    ),
    borderRadius: BorderRadius.circular(borderRadius),
    border: Border.all(
      color: color.withOpacity(borderOpacity),
      width: isEquipped ? 1.5 : 1.0,
    ),
    boxShadow: [
      BoxShadow(
        color: color.withOpacity(glowOpacity),
        blurRadius: isEquipped ? 16 : 10,
        spreadRadius: isEquipped ? -2 : -4,
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
    color: color.withOpacity(0.08),
    shape: BoxShape.circle,
    boxShadow: [
      BoxShadow(
        color: color.withOpacity(isEquipped ? 0.35 : 0.2),
        blurRadius: 18,
        spreadRadius: -2,
      ),
    ],
  );
}
