import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/state/app_state.dart';
import '../../../core/services/api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChallengesPage extends ConsumerWidget {
  const ChallengesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challenges = ref.watch(challengesProvider);
    return Theme(
      data: ThemeData.dark(),
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              toolbarHeight: 60,
              expandedHeight: 60,
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    color: const Color(0xFF101010).withOpacity(0.85),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => mainScaffoldKey.currentState?.openDrawer(),
                          child: const Icon(Icons.sort_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          "CHALLENGES",
                          style: GoogleFonts.lexend(
                            fontWeight: FontWeight.w700,
                            fontSize: 22,
                            letterSpacing: 1.5,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (challenges.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _ChallengesEmptyState(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final bet = challenges[index];
                        
                        Color color = Colors.orangeAccent;
                        if (bet.accentColor == 'blue') color = Colors.blueAccent;
                        if (bet.accentColor == 'red') color = Colors.redAccent;
                        if (bet.accentColor == 'green') color = Colors.greenAccent;

                        // Compute real AMM odds from yesPool and noPool
                        final total = bet.yesPool + bet.noPool;
                        final progressYes = total == 0 ? 0.5 : bet.yesPool / total;
                        final progressNo = total == 0 ? 0.5 : bet.noPool / total;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: _buildChallengeCard(
                            context: context,
                            ref: ref,
                            bet: bet,
                            title: bet.title,
                            subTitle: bet.description,
                            progressA: progressYes,
                            progressB: progressNo,
                            timeLeft: bet.timeLeft,
                            participants: bet.participants,
                            prize: bet.pool,
                            accentColor: color,
                          ),
                        );
                      },
                      childCount: challenges.length,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showEnrollDialog(BuildContext context, WidgetRef ref, Challenge bet) {
    String selectedResponse = 'YES';
    final coinController = TextEditingController();
    bool isEnrolling = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Join Alliance", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(bet.title, style: TextStyle(color: Colors.grey.shade400, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 20),
              // YES / NO toggle
              Row(
                children: ['YES', 'NO'].map((opt) {
                  final isSelected = selectedResponse == opt;
                  final optColor = opt == 'YES' ? const Color(0xFF00D09C) : const Color(0xFFEB5B3C);
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setDialogState(() => selectedResponse = opt),
                      child: Container(
                        margin: EdgeInsets.only(right: opt == 'YES' ? 8 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? optColor.withOpacity(0.2) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? optColor : Colors.white24),
                        ),
                        alignment: Alignment.center,
                        child: Text(opt, style: TextStyle(color: isSelected ? optColor : Colors.white54, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: coinController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Campus Coins to stake",
                  labelStyle: TextStyle(color: Colors.grey.shade600),
                  enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white24), borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF00D09C)), borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.monetization_on_rounded, color: Colors.amber),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D09C),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: isEnrolling ? null : () async {
                final coins = int.tryParse(coinController.text.trim());
                if (coins == null || coins <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Enter a valid coin amount"), backgroundColor: Colors.orange),
                  );
                  return;
                }
                setDialogState(() => isEnrolling = true);
                try {
                  await apiService.enrollInBet(
                    betId: bet.betId,
                    response: selectedResponse,
                    campusCoins: coins,
                  );
                  ref.read(walletProvider.notifier).refresh();
                  ref.read(challengesProvider.notifier).refresh();
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("✅ Joined with $coins CMX on $selectedResponse!"),
                      backgroundColor: const Color(0xFF00D09C),
                    ),
                  );
                } catch (e) {
                  setDialogState(() => isEnrolling = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("❌ ${e.toString().replaceAll('Exception: ', '')}"),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
              child: isEnrolling
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Text("CONFIRM"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeCard({
    required BuildContext context,
    required WidgetRef ref,
    required Challenge bet,
    required String title,
    required String subTitle,
    required double progressA,
    required double progressB,
    required String timeLeft,
    required int participants,
    required String prize,
    required Color accentColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color.alphaBlend(accentColor.withOpacity(0.03), const Color(0xFF1E1E1E).withOpacity(0.8)),
              gradient: RadialGradient(
                center: Alignment.bottomRight,
                radius: 2.5,
                colors: [accentColor.withOpacity(0.30), Colors.transparent],
                stops: const [0.0, 1.0],
              ),
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.1)),
                left: BorderSide(color: Colors.white.withOpacity(0.1)),
                right: BorderSide(color: Colors.white.withOpacity(0.02)),
                bottom: BorderSide(color: Colors.white.withOpacity(0.02)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(title, style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: accentColor.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.timer_outlined, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(timeLeft, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(subTitle, style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                
                const SizedBox(height: 24),
                
                // YES side
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("YES", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    Text("${(progressA * 100).toInt()}%", style: TextStyle(fontWeight: FontWeight.bold, color: accentColor)),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progressA,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  borderRadius: BorderRadius.circular(4),
                  minHeight: 8,
                ),
                
                const SizedBox(height: 16),
  
                // NO side
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("NO", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    Text("${(progressB * 100).toInt()}%", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white54)),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progressB,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white70),
                  borderRadius: BorderRadius.circular(4),
                  minHeight: 8,
                ),
  
                const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(color: Colors.white10)),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.people_alt_rounded, color: Colors.grey, size: 16),
                        const SizedBox(width: 4),
                        Text("$participants Joining", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(prize, style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor.withOpacity(0.2),
                      foregroundColor: accentColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                    onPressed: bet.timeLeft == "Closed"
                        ? null
                        : () => _showEnrollDialog(context, ref, bet),
                    child: Text(
                      bet.timeLeft == "Closed" ? "CLOSED" : "JOIN ALLIANCE",
                      style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChallengesEmptyState extends StatelessWidget {
  const _ChallengesEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.flag_rounded, color: Colors.white24, size: 54),
            const SizedBox(height: 16),
            Text(
              "No challenges yet",
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Create bets from the backend to populate this screen.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
