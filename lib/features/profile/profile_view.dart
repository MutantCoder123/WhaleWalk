import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/state/app_state.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coins = ref.watch(currentCoinsProvider);
    final steps = ref.watch(currentStepsProvider);
    final orbs = ref.watch(orbsProvider);
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D0E12),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text("CAMPUS IDENTITY",
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 2)),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Reputation Score & Dynamic Title
              const CircleAvatar(
                radius: 50,
                backgroundColor: Color(0xFF2962FF),
                child: Icon(Icons.person, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text(
                "GOLD MASTER",
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
              Text(
                "GLOBAL RANK: #1 • ACTIVE TRADER",
                style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
              // Live Metrics
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildMetric("STEPS", "$steps", Colors.white),
                    _buildMetric(
                        "COINS", "${coins.toStringAsFixed(1)}", Colors.amber),
                    _buildMetric("ORBS", "$orbs", Colors.purpleAccent),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Bets History
              _buildSectionHeader("PAST BET RECORDS (STAKING)"),
              _buildHistoryCard("Tech Stocks Bull Run", "Win", "+124 Coins",
                  Colors.greenAccent),
              _buildHistoryCard(
                  "Exam Week Predictor", "Loss", "-50 Coins", Colors.redAccent),
              _buildHistoryCard("Weekend Hackathon", "Pending", "Lock: 100",
                  Colors.orangeAccent),

              const SizedBox(height: 32),

              // Group Challenges History (PnL)
              _buildSectionHeader("GROUP CHALLENGES (PnL)"),
              _buildHistoryCard("Hostel A vs B Sprint", "Profit",
                  "+1,200 Coins", Colors.greenAccent),
              _buildHistoryCard("CS vs IT Hackathon", "Profit",
                  "+5,000 Coins & Elite Badge", Colors.purpleAccent),
              _buildHistoryCard("1st Year Steps Challenge", "Loss",
                  "-300 Coins", Colors.redAccent),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.5),
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 10,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildHistoryCard(
      String title, String outcome, String pnl, Color accent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16171B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text("Outcome: $outcome",
                    style:
                        TextStyle(color: Colors.grey.shade400, fontSize: 12)),
              ],
            ),
          ),
          Text(pnl,
              style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
