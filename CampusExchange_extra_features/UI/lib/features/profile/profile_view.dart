import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/state/app_state.dart';
import '../../core/services/api_service.dart';
import 'inventory_view.dart';

class ProfileView extends ConsumerStatefulWidget {
  const ProfileView({super.key});

  @override
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView> with SingleTickerProviderStateMixin {
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

  Color _getRarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'common':
        return Colors.grey.shade400;
      case 'uncommon':
        return Colors.greenAccent;
      case 'rare':
        return Colors.blueAccent;
      case 'epic':
        return Colors.purpleAccent;
      case 'legendary':
        return Colors.orangeAccent;
      case 'mythic':
        return Colors.pinkAccent;
      default:
        return Colors.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final coins = ref.watch(currentCoinsProvider);
    final steps = ref.watch(currentStepsProvider);
    final orbs = ref.watch(orbsProvider);
    final inventoryState = ref.watch(inventoryProvider);
    final achievementState = ref.watch(achievementProvider);

    // Find equipped badge and title
    final equippedBadge = inventoryState.items
        .where((i) => i.category == 'badge' && i.isEquipped)
        .toList();
    final equippedTitle = inventoryState.items
        .where((i) => i.category == 'title' && i.isEquipped)
        .toList();

    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D0E12),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text("CAMPUS IDENTITY", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 2)),
          centerTitle: true,
        ),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // ── Avatar + Equipped Badge ──
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        if (equippedBadge.isNotEmpty && equippedBadge.first.imageUrl != null)
                          SizedBox(
                            width: 145,
                            height: 145,
                            child: Image.network(
                              apiService.getMediaUrl(equippedBadge.first.imageUrl!),
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => Container(),
                            ),
                          ),
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 54,
                            backgroundColor: const Color(0xFF16171B),
                            child: const CircleAvatar(
                              radius: 51,
                              backgroundImage: NetworkImage('https://api.dicebear.com/7.x/avataaars/png?seed=Felix'),
                              backgroundColor: Colors.transparent,
                            ),
                          ),
                        ),
                        if (equippedBadge.isNotEmpty)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16171B),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFFD700).withOpacity(0.3),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.military_tech_rounded, color: Color(0xFFFFD700), size: 18),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Title ──
                    Text(
                      equippedTitle.isNotEmpty
                          ? equippedTitle.first.name.toUpperCase()
                          : "GOLD MASTER",
                      style: TextStyle(
                        color: equippedTitle.isNotEmpty 
                            ? _getRarityColor(equippedTitle.first.rarity)
                            : Colors.amber,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                        shadows: [
                          Shadow(
                            color: (equippedTitle.isNotEmpty 
                                ? _getRarityColor(equippedTitle.first.rarity)
                                : Colors.amber).withOpacity(0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),

                    if (equippedBadge.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (equippedBadge.first.imageUrl != null)
                              Padding(
                                padding: const EdgeInsets.only(right: 6.0),
                                child: Image.network(
                                  apiService.getMediaUrl(equippedBadge.first.imageUrl!),
                                  width: 16,
                                  height: 16,
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.military_tech_rounded, color: Color(0xFFFFD700), size: 14),
                                ),
                              )
                            else
                              const Icon(Icons.military_tech_rounded, color: Color(0xFFFFD700), size: 14),
                            Text(
                              equippedBadge.first.name,
                              style: GoogleFonts.outfit(
                                color: const Color(0xFFFFD700),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 4),
                    Text(
                      "GLOBAL RANK: #1 • ACTIVE TRADER",
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 12, fontWeight: FontWeight.bold),
                    ),

                    // ── Live Metrics ──
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildMetric("STEPS", "$steps", Colors.white),
                          _buildMetric("COINS", "${coins.toStringAsFixed(1)}", Colors.amber),
                          _buildMetric("ORBS", "$orbs", Colors.purpleAccent),
                        ],
                      ),
                    ),

                    // ── Inventory Button ──
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const InventoryView()),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF2962FF).withOpacity(0.15),
                              const Color(0xFF00E5FF).withOpacity(0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFF2962FF).withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2962FF).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.inventory_2_rounded, color: Color(0xFF00E5FF), size: 22),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("MY INVENTORY", style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                                  const SizedBox(height: 2),
                                  Text("${inventoryState.items.length} items • ${inventoryState.items.where((i) => i.isEquipped).length} equipped", style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF00E5FF), size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFF2962FF),
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey,
                  tabs: const [
                    Tab(text: "ACTIVITY"),
                    Tab(text: "ACHIEVEMENTS"),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              // ── Activity Tab ──
              ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _buildSectionHeader("PAST BET RECORDS (STAKING)"),
                  _buildHistoryCard("Tech Stocks Bull Run", "Win", "+124 Coins", Colors.greenAccent),
                  _buildHistoryCard("Exam Week Predictor", "Loss", "-50 Coins", Colors.redAccent),
                  _buildHistoryCard("Weekend Hackathon", "Pending", "Lock: 100", Colors.orangeAccent),
                  const SizedBox(height: 24),
                  _buildSectionHeader("GROUP CHALLENGES (PnL)"),
                  _buildHistoryCard("Hostel A vs B Sprint", "Profit", "+1,200 Coins", Colors.greenAccent),
                  _buildHistoryCard("CS vs IT Hackathon", "Profit", "+5,000 Coins & Elite Badge", Colors.purpleAccent),
                  _buildHistoryCard("1st Year Steps Challenge", "Loss", "-300 Coins", Colors.redAccent),
                ],
              ),
              // ── Achievements Tab ──
              ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: achievementState.achievements.length,
                itemBuilder: (context, index) {
                  final ach = achievementState.achievements[index];
                  return _buildAchievementCard(ach);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementCard(AchievementData ach) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: !ach.isUnlocked ? const Color(0xFF16171B) : const Color(0xFF16171B).withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: !ach.isUnlocked ? Colors.white10 : Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: !ach.isUnlocked ? Colors.amber.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.stars_rounded,
              color: !ach.isUnlocked ? Colors.amber : Colors.grey.shade700,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ach.title,
                  style: GoogleFonts.outfit(
                    color: !ach.isUnlocked ? Colors.white : Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ach.description,
                  style: TextStyle(
                    color: !ach.isUnlocked ? Colors.grey.shade400 : Colors.grey.shade700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (ach.rewardCoins > 0)
                      _rewardMiniChip(Icons.monetization_on_rounded, Colors.amber, ach.rewardCoins.toString(), !ach.isUnlocked),
                    if (ach.rewardOrbs > 0) ...[
                      const SizedBox(width: 8),
                      _rewardMiniChip(Icons.auto_awesome_rounded, Colors.purpleAccent, ach.rewardOrbs.toString(), !ach.isUnlocked),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (ach.isUnlocked)
            Icon(Icons.check_circle_rounded, color: Colors.grey.shade700, size: 20)
          else
            const Icon(Icons.lock_open_rounded, color: Colors.amber, size: 18),
        ],
      ),
    );
  }

  Widget _rewardMiniChip(IconData icon, Color color, String val, bool isUnlocked) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (isUnlocked ? color : Colors.grey).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(icon, color: isUnlocked ? color : Colors.grey.shade700, size: 10),
          const SizedBox(width: 4),
          Text(val, style: TextStyle(color: isUnlocked ? color : Colors.grey.shade700, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
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
          style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5),
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildHistoryCard(String title, String outcome, String pnl, Color accent) {
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
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text("Outcome: $outcome", style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
              ],
            ),
          ),
          Text(pnl, style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFF0D0E12),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
