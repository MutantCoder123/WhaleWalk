import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/state/app_state.dart';
import '../../../core/services/api_service.dart';

class StakingPage extends ConsumerStatefulWidget {
  const StakingPage({super.key});

  @override
  ConsumerState<StakingPage> createState() => _StakingPageState();
}

class _StakingPageState extends ConsumerState<StakingPage> {
  List<Map<String, dynamic>> _myBets = [];
  bool _loadingMyBets = true;

  @override
  void initState() {
    super.initState();
    _fetchMyBets();
  }

  Future<void> _fetchMyBets() async {
    try {
      final data = await apiService.getMyBets();
      if (mounted) {
        setState(() {
          _myBets = data.cast<Map<String, dynamic>>();
          _loadingMyBets = false;
        });
      }
    } catch (e) {
      debugPrint('[StakingPage] Error fetching my bets: $e');
      if (mounted) setState(() => _loadingMyBets = false);
    }
  }

  /// Returns the user's enrollment data for a given betId, or null if not enrolled
  Map<String, dynamic>? _getMyEnrollment(String betId) {
    try {
      return _myBets.firstWhere((b) => b['betId'] == betId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final challenges = ref.watch(challengesProvider);

    return Scaffold(
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
                        "POOLS",
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
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.hub_rounded, color: Colors.white24, size: 54),
                    const SizedBox(height: 16),
                    Text("No pools yet", style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text("Pools will appear here when available.", style: TextStyle(color: Colors.grey.shade500)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final bet = challenges[index];
                    final enrollment = _getMyEnrollment(bet.betId);
                    final isEnrolled = enrollment != null;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: _PoolCard(
                        bet: bet,
                        isEnrolled: isEnrolled,
                        enrollment: enrollment,
                        onEnrolled: () {
                          _fetchMyBets();
                          ref.read(challengesProvider.notifier).refresh();
                          ref.read(walletProvider.notifier).refresh();
                        },
                      ),
                    );
                  },
                  childCount: challenges.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

// =============================================================================
// Individual Pool Card — handles its own enrollment dialog
// =============================================================================
class _PoolCard extends StatelessWidget {
  final Challenge bet;
  final bool isEnrolled;
  final Map<String, dynamic>? enrollment;
  final VoidCallback onEnrolled;

  const _PoolCard({
    required this.bet,
    required this.isEnrolled,
    this.enrollment,
    required this.onEnrolled,
  });

  Color get _accentColor {
    if (isEnrolled) return const Color(0xFF00D09C); // teal/green for enrolled
    switch (bet.accentColor) {
      case 'blue':   return Colors.blueAccent;
      case 'red':    return Colors.redAccent;
      case 'green':  return Colors.greenAccent;
      default:       return Colors.orangeAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = bet.yesPool + bet.noPool;
    final progressYes = total == 0 ? 0.5 : bet.yesPool / total;
    final progressNo  = total == 0 ? 0.5 : bet.noPool / total;
    final accent = _accentColor;

    return GestureDetector(
      onTap: () {
        if (isEnrolled) {
          _showEnrolledInfoDialog(context);
        } else {
          _showEnrollDialog(context);
        }
      },
      child: Container(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color.alphaBlend(accent.withOpacity(0.03), const Color(0xFF1E1E1E).withOpacity(0.8)),
                gradient: RadialGradient(
                  center: Alignment.bottomRight,
                  radius: 2.5,
                  colors: [accent.withOpacity(0.30), Colors.transparent],
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
                  // Header row: title + enrolled badge / timer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          bet.title,
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isEnrolled)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00D09C).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF00D09C).withOpacity(0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Color(0xFF00D09C), size: 14),
                              const SizedBox(width: 4),
                              Text("JOINED", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF00D09C), fontSize: 11, letterSpacing: 1)),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: accent.withOpacity(0.5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.timer_outlined, color: Colors.white, size: 14),
                              const SizedBox(width: 4),
                              Text(bet.timeLeft, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(bet.description, style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),

                  const SizedBox(height: 24),

                  // YES progress bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("YES", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      Text("${(progressYes * 100).toInt()}%", style: TextStyle(fontWeight: FontWeight.bold, color: accent)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progressYes,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                    borderRadius: BorderRadius.circular(4),
                    minHeight: 8,
                  ),

                  const SizedBox(height: 16),

                  // NO progress bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("NO", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      Text("${(progressNo * 100).toInt()}%", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white54)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progressNo,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white70),
                    borderRadius: BorderRadius.circular(4),
                    minHeight: 8,
                  ),

                  const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(color: Colors.white10)),

                  // Stats row: participants + pool
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.people_alt_rounded, color: Colors.grey, size: 16),
                          const SizedBox(width: 4),
                          Text("${bet.participants} Enrolled", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(bet.pool, style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Action button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isEnrolled
                            ? const Color(0xFF00D09C).withOpacity(0.15)
                            : accent.withOpacity(0.2),
                        foregroundColor: isEnrolled ? const Color(0xFF00D09C) : accent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: bet.timeLeft == "Closed"
                          ? null
                          : () {
                              if (isEnrolled) {
                                _showEnrolledInfoDialog(context);
                              } else {
                                _showEnrollDialog(context);
                              }
                            },
                      child: Text(
                        isEnrolled
                            ? "VIEW MY STAKE"
                            : (bet.timeLeft == "Closed" ? "CLOSED" : "ENTER POOL"),
                        style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, letterSpacing: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Dialog: Enroll (manual text input for coin amount)
  // ───────────────────────────────────────────────────────────────────────────
  void _showEnrollDialog(BuildContext context) {
    String selectedResponse = 'YES';
    final coinController = TextEditingController();
    bool isEnrolling = false;

    // Compute potential payout live
    double _computePayout(int coins, String side) {
      final myPool = side == 'YES' ? bet.yesPool + coins : bet.noPool + coins;
      final otherPool = side == 'YES' ? bet.noPool : bet.yesPool;
      final totalPool = myPool + otherPool;
      if (myPool == 0) return 0;
      return (coins / myPool) * totalPool;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final coins = int.tryParse(coinController.text.trim()) ?? 0;
          final payout = coins > 0 ? _computePayout(coins, selectedResponse) : 0.0;

          return AlertDialog(
            backgroundColor: const Color(0xFF1A1A1F),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            contentPadding: const EdgeInsets.all(24),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  "Enter Pool",
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
                ),
                const SizedBox(height: 6),
                Text(
                  bet.title,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 20),

                // Info chips: enrolled count + total pool
                Row(
                  children: [
                    _infoChip(Icons.people_alt_rounded, "${bet.participants} enrolled"),
                    const SizedBox(width: 10),
                    _infoChip(Icons.account_balance_wallet_rounded, bet.pool),
                  ],
                ),

                const SizedBox(height: 24),

                // YES / NO toggle
                Row(
                  children: ['YES', 'NO'].map((opt) {
                    final isSelected = selectedResponse == opt;
                    final optColor = opt == 'YES' ? const Color(0xFF00D09C) : const Color(0xFFEB5B3C);
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setDialogState(() => selectedResponse = opt),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: EdgeInsets.only(right: opt == 'YES' ? 8 : 0),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: isSelected ? optColor.withOpacity(0.2) : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? optColor : Colors.white24,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            opt,
                            style: TextStyle(
                              color: isSelected ? optColor : Colors.white54,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // Manual coin input
                TextField(
                  controller: coinController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: GoogleFonts.robotoMono(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  onChanged: (_) => setDialogState(() {}),
                  decoration: InputDecoration(
                    labelText: "Coins to stake",
                    labelStyle: TextStyle(color: Colors.grey.shade600),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white24),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF00D09C), width: 2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    prefixIcon: const Icon(Icons.monetization_on_rounded, color: Colors.amber),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.04),
                  ),
                ),

                const SizedBox(height: 16),

                // Potential payout display
                if (coins > 0)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D09C).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF00D09C).withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Potential Payout", style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                        Text(
                          "${payout.toInt()} CMX",
                          style: GoogleFonts.robotoMono(
                            color: const Color(0xFF00D09C),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text("Cancel", style: TextStyle(color: Colors.white38)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00D09C),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                        ),
                        onPressed: isEnrolling ? null : () async {
                          final coinAmt = int.tryParse(coinController.text.trim());
                          if (coinAmt == null || coinAmt <= 0) {
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
                              campusCoins: coinAmt,
                            );
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("✅ Staked $coinAmt CMX on $selectedResponse!"),
                                backgroundColor: const Color(0xFF00D09C),
                              ),
                            );
                            onEnrolled();
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
                            : Text("CONFIRM STAKE", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Dialog: Already enrolled — show chosen outcome + potential payout
  // ───────────────────────────────────────────────────────────────────────────
  void _showEnrolledInfoDialog(BuildContext context) {
    final myResponse = enrollment?['myResponse'] ?? '—';
    final myCoins = (enrollment?['myCoins'] ?? 0) as num;
    final isYes = myResponse.toString().toUpperCase() == 'YES';
    final responseColor = isYes ? const Color(0xFF00D09C) : const Color(0xFFEB5B3C);

    // Compute potential payout from current pools
    final myPool = isYes ? bet.yesPool : bet.noPool;
    final totalPool = bet.yesPool + bet.noPool;
    final potentialPayout = myPool > 0 ? (myCoins / myPool) * totalPool : 0.0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(28),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Check icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF00D09C).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF00D09C), size: 36),
            ),
            const SizedBox(height: 20),
            Text("You're In!", style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(bet.title, style: TextStyle(color: Colors.grey.shade500, fontSize: 13), textAlign: TextAlign.center, maxLines: 2),

            const SizedBox(height: 28),

            // Chosen outcome
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: responseColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: responseColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Your Pick", style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                  Row(
                    children: [
                      Icon(
                        isYes ? Icons.thumb_up_rounded : Icons.thumb_down_rounded,
                        color: responseColor,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        myResponse.toString().toUpperCase(),
                        style: GoogleFonts.montserrat(
                          color: responseColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Amount staked
            _infoRow("Coins Staked", "${myCoins.toInt()} CMX", Colors.amber),

            const SizedBox(height: 12),

            // Potential payout
            _infoRow("Potential Payout", "${potentialPayout.toInt()} CMX", const Color(0xFF00D09C)),

            const SizedBox(height: 12),

            // Participants
            _infoRow("Total Enrolled", "${bet.participants}", Colors.white54),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  backgroundColor: Colors.white.withOpacity(0.05),
                ),
                child: Text("GOT IT", style: GoogleFonts.montserrat(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, Color valueColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
          Text(value, style: GoogleFonts.robotoMono(color: valueColor, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.grey.shade500, size: 14),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
        ],
      ),
    );
  }
}
