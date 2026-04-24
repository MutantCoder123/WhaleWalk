import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/state/app_state.dart';
import '../../../core/services/api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../store/store_view.dart';

class ChallengesPage extends ConsumerStatefulWidget {
  const ChallengesPage({super.key});

  @override
  ConsumerState<ChallengesPage> createState() => _ChallengesPageState();
}

class _ChallengesPageState extends ConsumerState<ChallengesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final challenges = ref.watch(timedChallengesProvider);
    final dailyChallenges = challenges.where((c) => c.duration == 'DAILY').toList();
    final weeklyChallenges = challenges.where((c) => c.duration == 'WEEKLY').toList();

    return Theme(
      data: ThemeData.dark(),
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: Column(
          children: [
            // Glassmorphic Header
            _buildHeader(context),
            
            // Tab Bar
            _buildTabBar(),

            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildChallengeList(dailyChallenges),
                  _buildChallengeList(weeklyChallenges),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFF101010).withOpacity(0.8),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
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
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.shopping_basket_rounded, color: Colors.white, size: 24),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const StoreView()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 10, 24, 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF00D09C),
        ),
        labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1),
        unselectedLabelColor: Colors.white54,
        labelColor: Colors.black,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: "DAILY"),
          Tab(text: "WEEKLY"),
        ],
      ),
    );
  }

  Widget _buildChallengeList(List<TaskChallenge> challenges) {
    if (challenges.isEmpty) {
      return const _ChallengesEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(timedChallengesProvider.notifier).refresh(),
      color: const Color(0xFF00D09C),
      backgroundColor: const Color(0xFF1E1E1E),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
        itemCount: challenges.length,
        itemBuilder: (context, index) => _buildChallengeCard(challenges[index]),
      ),
    );
  }

  Widget _buildChallengeCard(TaskChallenge challenge) {
    final progressVal = (challenge.targetValue == 0) ? 0.0 : (challenge.progress / challenge.targetValue).clamp(0.0, 1.0);
    final isCompleted = challenge.status == 'COMPLETED';
    final isClaimed = challenge.status == 'CLAIMED';
    // ignore: unused_local_variable
    final isExpired = challenge.status == 'EXPIRED';

    Color accentColor;
    IconData icon;
    switch (challenge.metric) {
      case 'STEPS':
        accentColor = const Color(0xFFFF5722);
        icon = Icons.directions_run_rounded;
        break;
      case 'BETS_WON':
        accentColor = const Color(0xFF2196F3);
        icon = Icons.emoji_events_rounded;
        break;
      case 'COINS_EARNED':
        accentColor = Colors.amber;
        icon = Icons.monetization_on_rounded;
        break;
      default:
        accentColor = const Color(0xFF00D09C);
        icon = Icons.bolt_rounded;
    }

    final diff = challenge.expiresAt.difference(DateTime.now());
    final timeLeft = diff.isNegative ? "Expired" : "${diff.inHours}h ${diff.inMinutes % 60}m left";

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accentColor.withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: accentColor, size: 20),
                    ),
                    _buildRarityBadge(challenge.intensity),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  challenge.title,
                  style: GoogleFonts.lexend(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  challenge.description,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 24),
                
                // Progress Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${challenge.progress} / ${challenge.targetValue}",
                      style: GoogleFonts.robotoMono(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      "${(progressVal * 100).toInt()}%",
                      style: GoogleFonts.robotoMono(
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progressVal,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  borderRadius: BorderRadius.circular(4),
                  minHeight: 6,
                ),
                
                const SizedBox(height: 20),
                
                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined, color: Colors.grey, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          timeLeft,
                          style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        _rewardChip(Icons.monetization_on_rounded, Colors.amber, challenge.rewardCoins.toString()),
                        const SizedBox(width: 8),
                        _rewardChip(Icons.auto_awesome_rounded, Colors.purpleAccent, challenge.rewardOrbs.toString()),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Claim Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isClaimed 
                          ? Colors.white10 
                          : (isCompleted ? const Color(0xFF00D09C) : Colors.white.withOpacity(0.08)),
                      foregroundColor: isClaimed ? Colors.white24 : (isCompleted ? Colors.black : Colors.white70),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: isCompleted && !isClaimed 
                        ? () => _claimReward(challenge)
                        : null,
                    child: Text(
                      isClaimed ? "CLAIMED" : (isCompleted ? "CLAIM REWARD" : "IN PROGRESS"),
                      style: GoogleFonts.lexend(fontWeight: FontWeight.bold, letterSpacing: 1),
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

  Widget _buildRarityBadge(int intensity) {
    String label;
    Color color;
    switch (intensity) {
      case 1: label = "Common"; color = Colors.grey; break;
      case 2: label = "Uncommon"; color = Colors.green; break;
      case 3: label = "Rare"; color = Colors.blue; break;
      case 4: label = "Epic"; color = Colors.purple; break;
      case 5: label = "Legendary"; color = Colors.orange; break;
      default: label = "Common"; color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.outfit(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
      ),
    );
  }

  Widget _rewardChip(IconData icon, Color color, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            value,
            style: GoogleFonts.robotoMono(color: color, fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ],
      ),
    );
  }

  void _claimReward(TaskChallenge challenge) async {
    try {
      await ref.read(timedChallengesProvider.notifier).claimReward(challenge.id);
      ref.read(walletProvider.notifier).refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Reward Claimed! +${challenge.rewardCoins} CMX, +${challenge.rewardOrbs} Orbs"),
          backgroundColor: const Color(0xFF00D09C),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
      );
    }
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
            const Icon(Icons.bolt_rounded, color: Colors.white24, size: 54),
            const SizedBox(height: 16),
            Text(
              "No active challenges",
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Check back later for new tasks and rewards!",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
