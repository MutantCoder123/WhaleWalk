import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/state/app_state.dart';

class LeaderboardPage extends ConsumerWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(appModeProvider);
    final isDark = mode == AppMode.trading;
    
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final mutedColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Theme(
      data: isDark ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: surfaceColor,
          title: Text("Global Rankings", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: textColor)),
          iconTheme: IconThemeData(color: textColor),
          elevation: isDark ? 0 : 2,
        ),
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildPodium(context, 2, "Aarav", "Silver Elite", "24,500", "8.2k", Colors.grey.shade300, 130, isDark, textColor),
                    const SizedBox(width: 8),
                    _buildPodium(context, 1, "Indranil", "Gold Master", "42,000", "12k", Colors.amber, 170, isDark, textColor),
                    const SizedBox(width: 8),
                    _buildPodium(context, 3, "Sneha", "Bronze Novice", "18,200", "5k", Colors.orange.shade300, 110, isDark, textColor),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  const names = ["Vikram", "Ananya", "Rohan", "Aditi", "Priya", "Sid", "Karthik", "Nisha", "Riya", "Yash", "Pooja", "Arjun", "Neha", "Kabir", "Meera"];
                  final rank = index + 4;
                  return _buildRankRow(rank, names[index], "Apprentice", 15000 - (index * 500), 4000 - (index * 100), surfaceColor, textColor, mutedColor);
                },
                childCount: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPodium(BuildContext context, int rank, String name, String badge, String steps, String coins, Color color, double height, bool isDark, Color textColor) {
    return Column(
      children: [
        Icon(Icons.workspace_premium_rounded, color: color, size: 32),
        const SizedBox(height: 4),
        Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        Text(badge, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            color: color.withOpacity(isDark ? 0.2 : 0.4),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border.all(color: color, width: 2),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, -5))
            ]
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("#$rank", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 8),
              Text("$steps", style: TextStyle(fontSize: 10, color: textColor, fontWeight: FontWeight.bold)),
              Text("Steps", style: TextStyle(fontSize: 9, color: textColor.withOpacity(0.6))),
              const SizedBox(height: 4),
              Text("$coins", style: TextStyle(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.bold)),
              Text("Coins", style: TextStyle(fontSize: 9, color: Colors.amber.withOpacity(0.6))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRankRow(int rank, String name, String badge, int steps, int coins, Color surface, Color text, Color muted) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text("#$rank", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: muted)),
          ),
          CircleAvatar(
            backgroundColor: Colors.blue.withOpacity(0.1),
            child: Icon(Icons.person, color: Colors.blue.shade300),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: text)),
                Text(badge, style: TextStyle(color: Colors.purpleAccent, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Text("${steps}k", style: TextStyle(fontWeight: FontWeight.bold, color: text)),
                  const SizedBox(width: 4),
                  Icon(Icons.directions_walk, size: 14, color: muted),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text("$coins", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                  const SizedBox(width: 4),
                  const Icon(Icons.monetization_on, size: 14, color: Colors.amber),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }
}
