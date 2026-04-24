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
    final stepGoal = wallet.stepGoal;
    final distanceGoal = wallet.distanceGoal;
    final goalFraction = (steps / (stepGoal > 0 ? stepGoal : 10000)).clamp(0.0, 1.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 25),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 48), // Spacer for centering text
                Text(
                  "TODAY'S ACTIVITY",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade400,
                      letterSpacing: 2.0),
                ),
                IconButton(
                  onPressed: () => _showSetGoalDialog(context, ref, stepGoal, distanceGoal),
                  icon: const Icon(Icons.edit_rounded, size: 20),
                  color: Colors.grey.shade400,
                  tooltip: "Set Daily Goals",
                ),
              ],
            ),
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
                  const SizedBox(height: 12),
                  _buildGoalProgress("STEPS", steps, stepGoal, primaryColor),
                  const SizedBox(height: 8),
                  _buildGoalProgress("DISTANCE", wallet.stats.distanceKm, distanceGoal, secondaryColor, suffix: " KM"),
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

  Widget _buildGoalProgress(String label, num current, num target, Color color, {String suffix = ""}) {
    final progress = (current / (target > 0 ? target : 1)).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.bold)),
              Text("${current.toStringAsFixed(current is double ? 1 : 0)}$suffix / ${target.toStringAsFixed(target is double ? 1 : 0)}$suffix", 
                style: GoogleFonts.robotoMono(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress.toDouble(),
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  void _showSetGoalDialog(BuildContext context, WidgetRef ref, int currentSteps, double currentDistance) {
    final stepsController = TextEditingController(text: currentSteps.toString());
    final distanceController = TextEditingController(text: currentDistance.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Set Daily Goals", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: stepsController,
              decoration: const InputDecoration(labelText: "Steps Goal"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: distanceController,
              decoration: const InputDecoration(labelText: "Distance Goal (KM)"),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () {
              final steps = int.tryParse(stepsController.text);
              final distance = double.tryParse(distanceController.text);
              if (steps != null || distance != null) {
                ref.read(walletProvider.notifier).updateGoals(steps: steps, distance: distance);
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722)),
            child: const Text("SAVE GOALS", style: TextStyle(color: Colors.white)),
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
