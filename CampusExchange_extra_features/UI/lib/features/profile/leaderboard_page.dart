import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/state/app_state.dart';
import '../../core/services/api_service.dart';

class LeaderboardPage extends ConsumerStatefulWidget {
  const LeaderboardPage({super.key});

  @override
  ConsumerState<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends ConsumerState<LeaderboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> _coinsEntries = [];
  List<Map<String, dynamic>> _stepsEntries = [];
  List<Map<String, dynamic>> _betsEntries = [];
  List<Map<String, dynamic>> _portfolioEntries = [];

  bool _loadingCoins = true;
  bool _loadingSteps = true;
  bool _loadingBets = true;
  bool _loadingPortfolio = true;

  // Default titles based on rank position when no equipped title
  static const _defaultTitles = [
    "Gold Master",
    "Silver Elite",
    "Bronze Novice",
    "Apprentice",
  ];

  String _defaultTitle(int rank) {
    if (rank <= _defaultTitles.length) return _defaultTitles[rank - 1];
    return "Apprentice";
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAll() async {
    _fetchCoins();
    _fetchSteps();
    _fetchBets();
    _fetchPortfolio();
  }

  Future<void> _fetchCoins() async {
    try {
      final data = await apiService.getLeaderboard();
      setState(() {
        _coinsEntries = data.cast<Map<String, dynamic>>();
        _loadingCoins = false;
      });
    } catch (e) {
      debugPrint('[Leaderboard] Coins error: $e');
      setState(() => _loadingCoins = false);
    }
  }

  Future<void> _fetchSteps() async {
    try {
      final data = await apiService.getStepsLeaderboard();
      setState(() {
        _stepsEntries = data.cast<Map<String, dynamic>>();
        _loadingSteps = false;
      });
    } catch (e) {
      debugPrint('[Leaderboard] Steps error: $e');
      setState(() => _loadingSteps = false);
    }
  }

  Future<void> _fetchBets() async {
    try {
      final data = await apiService.getBetsWonLeaderboard();
      setState(() {
        _betsEntries = data.cast<Map<String, dynamic>>();
        _loadingBets = false;
      });
    } catch (e) {
      debugPrint('[Leaderboard] Bets error: $e');
      setState(() => _loadingBets = false);
    }
  }

  Future<void> _fetchPortfolio() async {
    try {
      final data = await apiService.getPortfolioLeaderboard();
      setState(() {
        _portfolioEntries = data.cast<Map<String, dynamic>>();
        _loadingPortfolio = false;
      });
    } catch (e) {
      debugPrint('[Leaderboard] Portfolio error: $e');
      setState(() => _loadingPortfolio = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(appModeProvider);
    final isDark = mode == AppMode.trading;

    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Theme(
      data: isDark ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: surfaceColor,
          title: Text(
            "Global Rankings",
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: textColor),
          ),
          iconTheme: IconThemeData(color: textColor),
          elevation: isDark ? 0 : 2,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF2962FF),
            indicatorWeight: 3,
            labelColor: const Color(0xFF2962FF),
            unselectedLabelColor: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
            labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 0.3),
            unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 11),
            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
            tabs: const [
              Tab(icon: Icon(Icons.monetization_on_rounded, size: 16), text: "COINS"),
              Tab(icon: Icon(Icons.directions_walk_rounded, size: 16), text: "STEPS"),
              Tab(icon: Icon(Icons.emoji_events_rounded, size: 16), text: "BETS WON"),
              Tab(icon: Icon(Icons.pie_chart_rounded, size: 16), text: "PORTFOLIO"),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // ─── COINS TAB ───────────────────────────────────────
            _buildLeaderboardTab(
              entries: _coinsEntries,
              isLoading: _loadingCoins,
              valueKey: 'campusCoins',
              valueSuffix: '',
              valueIcon: Icons.monetization_on_rounded,
              valueColor: Colors.amber,
              isDark: isDark,
              surfaceColor: surfaceColor,
              textColor: textColor,
            ),
            // ─── STEPS TAB ──────────────────────────────────────
            _buildLeaderboardTab(
              entries: _stepsEntries,
              isLoading: _loadingSteps,
              valueKey: 'totalStepsWalked',
              valueSuffix: '',
              valueIcon: Icons.directions_walk_rounded,
              valueColor: const Color(0xFF00D09C),
              isDark: isDark,
              surfaceColor: surfaceColor,
              textColor: textColor,
            ),
            // ─── BETS WON TAB ───────────────────────────────────
            _buildLeaderboardTab(
              entries: _betsEntries,
              isLoading: _loadingBets,
              valueKey: 'betsWon',
              valueSuffix: ' won',
              valueIcon: Icons.emoji_events_rounded,
              valueColor: Colors.orangeAccent,
              isDark: isDark,
              surfaceColor: surfaceColor,
              textColor: textColor,
            ),
            // ─── PORTFOLIO TAB ──────────────────────────────────
            _buildLeaderboardTab(
              entries: _portfolioEntries,
              isLoading: _loadingPortfolio,
              valueKey: 'portfolioValue',
              valueSuffix: ' CMX',
              valueIcon: Icons.pie_chart_rounded,
              valueColor: const Color(0xFF7C4DFF),
              isDark: isDark,
              surfaceColor: surfaceColor,
              textColor: textColor,
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // Generic leaderboard tab builder
  // ===========================================================================
  Widget _buildLeaderboardTab({
    required List<Map<String, dynamic>> entries,
    required bool isLoading,
    required String valueKey,
    required String valueSuffix,
    required IconData valueIcon,
    required Color valueColor,
    required bool isDark,
    required Color surfaceColor,
    required Color textColor,
  }) {
    final mutedColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (entries.isEmpty) {
      return Center(
        child: Text("No rankings yet", style: TextStyle(color: mutedColor)),
      );
    }

    return CustomScrollView(
      slivers: [
        // Podium for top 3
        if (entries.length >= 3)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPodium(2, entries[1], Colors.grey.shade300, 130, isDark, textColor, valueKey, valueSuffix, valueColor),
                  const SizedBox(width: 8),
                  _buildPodium(1, entries[0], Colors.amber, 170, isDark, textColor, valueKey, valueSuffix, valueColor),
                  const SizedBox(width: 8),
                  _buildPodium(3, entries[2], Colors.orange.shade300, 110, isDark, textColor, valueKey, valueSuffix, valueColor),
                ],
              ),
            ),
          ),
        // Remaining ranks
        if (entries.length > 3)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final rank = index + 4;
                final entry = entries[index + 3];
                final title = entry['activeTitle'] ?? _defaultTitle(rank);
                final value = entry[valueKey] ?? 0;
                return _buildRankRow(
                  rank,
                  entry['username'] ?? 'Unknown',
                  title,
                  value,
                  valueSuffix,
                  valueIcon,
                  valueColor,
                  surfaceColor,
                  textColor,
                  mutedColor,
                );
              },
              childCount: entries.length - 3,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  // ===========================================================================
  // Podium for top 3
  // ===========================================================================
  Widget _buildPodium(
    int rank,
    Map<String, dynamic> entry,
    Color color,
    double height,
    bool isDark,
    Color textColor,
    String valueKey,
    String valueSuffix,
    Color valueColor,
  ) {
    final name = entry['username'] ?? 'Unknown';
    final title = entry['activeTitle'] ?? _defaultTitle(rank);
    final value = entry[valueKey] ?? 0;

    return Column(
      children: [
        Icon(Icons.workspace_premium_rounded, color: color, size: 32),
        const SizedBox(height: 4),
        Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        Text(title, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
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
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("#$rank", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 8),
              Text(
                "$value$valueSuffix",
                style: TextStyle(fontSize: 10, color: valueColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // Row for rank 4+
  // ===========================================================================
  Widget _buildRankRow(
    int rank,
    String name,
    String title,
    dynamic value,
    String valueSuffix,
    IconData valueIcon,
    Color valueColor,
    Color surface,
    Color text,
    Color muted,
  ) {
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
                Text(title, style: const TextStyle(color: Colors.purpleAccent, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Text("$value$valueSuffix", style: TextStyle(fontWeight: FontWeight.bold, color: valueColor)),
                  const SizedBox(width: 4),
                  Icon(valueIcon, size: 14, color: valueColor),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
