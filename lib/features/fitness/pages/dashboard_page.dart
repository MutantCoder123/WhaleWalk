import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/state/app_state.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const primaryColor = Color(0xFFFF5722);
    final secondaryColor = Colors.orange.shade300;
    const textColor = Color(0xFF212529);
    final mutedTextColor = Colors.grey.shade500;
    final wallet = ref.watch(walletProvider);
    final orbs = wallet.orbs;
    final steps = wallet.actualSteps;
    final goalFraction = (steps / 10000).clamp(0.0, 1.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Text(
            "TODAY'S ACTIVITY",
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade400,
                letterSpacing: 2.0),
          ),
          const SizedBox(height: 24),

          // Animated Goal Ring
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: goalFraction),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 220,
                        width: 220,
                        child: CircularProgressIndicator(
                          value: value,
                          strokeWidth: 16,
                          backgroundColor: Colors.grey.shade300,
                          valueColor:
                              const AlwaysStoppedAnimation(Color(0xFFFF5722)),
                        ),
                      ),
                      const Icon(Icons.directions_walk_rounded,
                          size: 100, color: Color(0xFFFF5722)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "${(value * 100).toInt()}%",
                    style: GoogleFonts.outfit(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: textColor),
                  ),
                  Text("OF DAILY GOAL",
                      style: TextStyle(
                          color: mutedTextColor,
                          letterSpacing: 2,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      "${(value * 10000).toInt()} / 10,000 STEPS",
                      style: GoogleFonts.robotoMono(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: primaryColor),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 32),

          // Quick Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatItem(Icons.blur_on_rounded, "$orbs", "ORBS", Colors.purple),
              _StatItem(
                  Icons.local_fire_department, wallet.stats.kcal.toStringAsFixed(0), "KCAL", primaryColor),
              _StatItem(Icons.location_on, wallet.stats.distanceKm.toStringAsFixed(1), "KM", secondaryColor),
              _StatItem(Icons.timer, wallet.stats.activeMin.toString(), "MIN", primaryColor),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String val;
  final String unit;
  final Color col;
  const _StatItem(this.icon, this.val, this.unit, this.col);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: col, size: 28),
        const SizedBox(height: 8),
        Text(val,
            style:
                GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(unit, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
      ],
    );
  }
}
