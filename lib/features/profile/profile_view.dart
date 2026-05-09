import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/state/app_state.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/rarity_utils.dart';
import 'inventory_view.dart';
import 'leaderboard_page.dart';
import '../store/store_view.dart';

class ProfileView extends ConsumerStatefulWidget {
  const ProfileView({super.key});

  @override
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final apiService = ApiService();
  String _username = '';
  String _fullName = '';
  List<dynamic> _transactions = [];
  List<dynamic> _myBets = [];
  bool _loadingActivity = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && !_tabController.indexIsChanging) {
        ref.read(achievementProvider.notifier).acknowledge();
      }
    });
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    try {
      final results = await Future.wait([
        apiService.getCurrentUser(),
        apiService.getTransactions(),
        apiService.getMyBets(),
      ]);
      if (mounted) {
        setState(() {
          final user = results[0] as Map<String, dynamic>;
          _username = user['username'] ?? '';
          _fullName = user['fullName'] ?? '';
          _transactions = (results[1] as List<dynamic>).take(15).toList();
          _myBets = (results[2] as List<dynamic>);
          _loadingActivity = false;
        });
      }
    } catch (e) {
      debugPrint('[Profile] Error loading data: $e');
      if (mounted) setState(() => _loadingActivity = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Using shared getRarityColor() from rarity_utils.dart

  @override
  Widget build(BuildContext context) {
    final coins = ref.watch(currentCoinsProvider);
    final steps = ref.watch(currentStepsProvider);
    final orbs = ref.watch(orbsProvider);
    final inventoryState = ref.watch(inventoryProvider);
    final achievementState = ref.watch(achievementProvider);

    final equippedBadge = inventoryState.items.where((i) => i.category == 'badge' && i.isEquipped).toList();
    final equippedTitle = inventoryState.items.where((i) => i.category == 'title' && i.isEquipped).toList();
    final displayName = _fullName.isNotEmpty ? _fullName.toUpperCase() : (_username.isNotEmpty ? _username.toUpperCase() : 'TRADER');

    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D0E12),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text("CAMPUS IDENTITY", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 2)),
          centerTitle: true,
          actions: [
             IconButton(
               icon: const Icon(Icons.leaderboard_rounded, color: Color(0xFF00E5FF)),
               onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LeaderboardPage())),
             )
          ],
        ),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        if (equippedBadge.isNotEmpty && equippedBadge.first.imageUrl != null && equippedBadge.first.imageUrl!.isNotEmpty)
                          SizedBox(
                            width: 150, height: 150,
                            child: Opacity(
                              opacity: 0.8,
                              child: Image.network(
                                apiService.getMediaUrl(equippedBadge.first.imageUrl!),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle, 
                            border: Border.all(
                              color: equippedBadge.isNotEmpty ? getRarityColor(equippedBadge.first.rarity) : Colors.amber, 
                              width: 3
                            ),
                            boxShadow: [BoxShadow(color: equippedBadge.isNotEmpty ? getRarityColor(equippedBadge.first.rarity).withOpacity(0.3) : Colors.black.withOpacity(0.5), blurRadius: 20)]
                          ),
                          child: CircleAvatar(
                            radius: 54,
                            backgroundColor: const Color(0xFF16171B),
                            child: CircleAvatar(
                              radius: 51,
                              backgroundImage: NetworkImage(
                                'https://api.dicebear.com/7.x/avataaars/png?seed=${_username.isNotEmpty ? _username : "user"}'
                              ),
                              backgroundColor: Colors.transparent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      equippedTitle.isNotEmpty ? equippedTitle.first.name.toUpperCase() : displayName,
                      style: TextStyle(
                        color: equippedTitle.isNotEmpty ? getRarityColor(equippedTitle.first.rarity) : Colors.amber,
                        fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 4,
                        shadows: [Shadow(color: (equippedTitle.isNotEmpty ? getRarityColor(equippedTitle.first.rarity) : Colors.amber).withOpacity(0.5), blurRadius: 10)],
                      ),
                    ),
                    if (equippedBadge.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: getRarityColor(equippedBadge.first.rarity).withOpacity(0.1), 
                          borderRadius: BorderRadius.circular(12), 
                          border: Border.all(color: getRarityColor(equippedBadge.first.rarity).withOpacity(0.2))
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min, 
                          children: [
                            equippedBadge.first.imageUrl != null && equippedBadge.first.imageUrl!.isNotEmpty
                                ? Image.network(
                                    apiService.getMediaUrl(equippedBadge.first.imageUrl!),
                                    width: 14, height: 14, fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => Icon(Icons.military_tech_rounded, color: getRarityColor(equippedBadge.first.rarity), size: 14),
                                  )
                                : Icon(Icons.military_tech_rounded, color: getRarityColor(equippedBadge.first.rarity), size: 14),
                            const SizedBox(width: 6), 
                            Text(equippedBadge.first.name, style: GoogleFonts.outfit(color: getRarityColor(equippedBadge.first.rarity), fontSize: 11, fontWeight: FontWeight.bold))
                          ]
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      _username.isNotEmpty ? "@$_username" : "",
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    Container(padding: const EdgeInsets.symmetric(vertical: 24), child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_buildMetric("STEPS", "$steps", Colors.white), _buildMetric("COINS", "${coins.toStringAsFixed(1)}", Colors.amber), _buildMetric("ORBS", "$orbs", Colors.purpleAccent)])),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _navTile(Icons.inventory_2_rounded, "INVENTORY", "${inventoryState.items.length} items", const Color(0xFF00E5FF), () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InventoryView()))),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _navTile(Icons.storefront_rounded, "CAMPUS STORE", "New items", Colors.amber, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const StoreView()))),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _navTile(Icons.leaderboard_rounded, "RANKINGS", "${_myBets.length} bets", Colors.purpleAccent, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LeaderboardPage()))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
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
                  tabs: const [Tab(text: "ACTIVITY"), Tab(text: "ACHIEVEMENTS")],
                ),
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildActivityTab(),
              _buildAchievementsList(achievementState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityTab() {
    if (_loadingActivity) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF), strokeWidth: 2));
    }

    if (_transactions.isEmpty && _myBets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_rounded, color: Colors.white.withOpacity(0.15), size: 54),
            const SizedBox(height: 16),
            Text("No activity yet", style: GoogleFonts.outfit(color: Colors.white30, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text("Your trades and bets will appear here.", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchProfileData,
      color: const Color(0xFF00E5FF),
      backgroundColor: const Color(0xFF1E1E1E),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (_myBets.isNotEmpty) ...[
            _buildSectionHeader("BET HISTORY"),
            ..._myBets.map((bet) {
              final question = bet['question'] ?? 'Unknown Bet';
              final myChoice = (bet['myResponse'] ?? '').toString().toUpperCase();
              final staked = bet['myCoins'] ?? 0;
              final betStatus = (bet['status'] ?? '').toString().toLowerCase();
              final betResult = (bet['result'] ?? '').toString().toUpperCase();
              
              String outcome;
              Color accentColor;
              String pnl;

              if (betStatus == 'closed') {
                // Compare user's response with the bet result
                final didWin = myChoice == betResult;
                if (didWin) {
                  outcome = 'Won';
                  accentColor = Colors.greenAccent;
                  pnl = '+$staked CMX';
                } else {
                  outcome = 'Lost';
                  accentColor = Colors.redAccent;
                  pnl = '-$staked CMX';
                }
              } else {
                outcome = 'Pending';
                accentColor = Colors.orangeAccent;
                pnl = 'Locked: $staked CMX';
              }
              
              return _buildHistoryCard("$question ($myChoice)", outcome, pnl, accentColor);
            }),
            const SizedBox(height: 24),
          ],
          if (_transactions.isNotEmpty) ...[
            _buildSectionHeader("RECENT TRANSACTIONS"),
            ..._transactions.map((tx) {
              final title = tx['title'] ?? 'Transaction';
              final amount = tx['amount'] ?? 0;
              final isPositive = tx['isPositive'] ?? false;
              return _buildHistoryCard(
                title,
                isPositive ? "Credit" : "Debit",
                "${isPositive ? '+' : '-'}$amount CMX",
                isPositive ? Colors.greenAccent : Colors.redAccent,
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _navTile(IconData icon, String label, String sub, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFF16171B), borderRadius: BorderRadius.circular(18), border: Border.all(color: color.withOpacity(0.2))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 12),
            Text(label, style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1)),
            Text(sub, style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsList(AchievementState state) {
    if (state.isLoading) return const Center(child: CircularProgressIndicator());
    if (state.achievements.isEmpty) return const Center(child: Text("No achievements yet."));
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: state.achievements.length,
      itemBuilder: (context, index) => _buildAchievementCard(state.achievements[index]),
    );
  }

  Widget _buildAchievementCard(AchievementData ach) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF16171B), borderRadius: BorderRadius.circular(16), border: Border.all(color: ach.isUnlocked ? Colors.amber.withOpacity(0.3) : Colors.white.withOpacity(0.05))),
      child: Row(
        children: [
          ach.imageUrl != null && ach.imageUrl!.isNotEmpty
              ? Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: ach.isUnlocked ? Colors.amber.withOpacity(0.1) : Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Opacity(
                      opacity: ach.isUnlocked ? 1.0 : 0.4,
                      child: Image.network(
                        apiService.getMediaUrl(ach.imageUrl!),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(Icons.stars_rounded, color: ach.isUnlocked ? Colors.amber : Colors.grey.shade700, size: 32),
                      ),
                    ),
                  ),
                )
              : Icon(Icons.stars_rounded, color: ach.isUnlocked ? Colors.amber : Colors.grey.shade700, size: 32),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(ach.title, style: GoogleFonts.outfit(color: ach.isUnlocked ? Colors.white : Colors.grey, fontWeight: FontWeight.bold, fontSize: 15)), Text(ach.description, style: TextStyle(color: Colors.grey.shade500, fontSize: 11))])),
          if (ach.isUnlocked) const Icon(Icons.check_circle_rounded, color: Colors.amber, size: 18),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(padding: const EdgeInsets.only(bottom: 16), child: Align(alignment: Alignment.centerLeft, child: Text(title, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5))));
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Column(children: [Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold))]);
  }

  Widget _buildHistoryCard(String title, String outcome, String pnl, Color accent) {
    return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF16171B), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text("Outcome: $outcome", style: TextStyle(color: Colors.grey.shade400, fontSize: 12))])), Text(pnl, style: TextStyle(color: accent, fontWeight: FontWeight.bold))]));
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;
  @override double get minExtent => _tabBar.preferredSize.height;
  @override double get maxExtent => _tabBar.preferredSize.height;
  @override Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => Container(color: const Color(0xFF0D0E12), child: _tabBar);
  @override bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
