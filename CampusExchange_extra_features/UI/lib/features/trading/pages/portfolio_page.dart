import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/state/app_state.dart';
import 'markets_page.dart';
import '../../store/store_view.dart';

class PortfolioPage extends ConsumerWidget {
  const PortfolioPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holdings = ref.watch(portfolioProvider);
    final wallet = ref.watch(walletProvider);

    // Compute totals from live data
    double currentTotal = holdings.fold(0, (sum, h) => sum + h.quantity * h.currentPrice);
    double previousTotal = holdings.fold(0, (sum, h) => sum + h.quantity * h.previousPrice);
    double totalReturns = currentTotal - previousTotal;
    double returnsPct = previousTotal == 0 ? 0 : (totalReturns / previousTotal) * 100;

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
                        "PORTFOLIO",
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
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white54, size: 20),
                        onPressed: () => ref.read(portfolioProvider.notifier).refresh(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Returns Dashboard
                _buildReturnsDashboard(currentTotal, totalReturns, returnsPct),
                
                const SizedBox(height: 32),
                
                // Claim Pending Steps (Campus Exchange Specific)
                _buildClaimCard(wallet.stepsCount),
                
                const SizedBox(height: 32),
                
                Text("Your Holdings", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 16),
                
                if (holdings.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Column(
                        children: [
                          const Icon(Icons.inbox_rounded, color: Colors.white24, size: 48),
                          const SizedBox(height: 12),
                          Text("No holdings yet. Buy some stocks!", style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  )
                else
                  ...holdings.map((h) {
                    final invested = h.quantity * h.previousPrice;
                    final current = h.quantity * h.currentPrice;
                    final ret = current - invested;
                    final retPct = invested == 0 ? 0.0 : (ret / invested) * 100;
                    return _buildHoldingRow(
                      context,
                      h.name,
                      h.quantity.toString(),
                      current.toStringAsFixed(2),
                      "${ret >= 0 ? '+' : ''}${ret.toStringAsFixed(2)}",
                      "${retPct >= 0 ? '+' : ''}${retPct.toStringAsFixed(2)}%",
                      h.currentPrice,
                      h.stockId,
                    );
                  }).toList(),
                
                const SizedBox(height: 100), // padding for bottom nav
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReturnsDashboard(double currentTotal, double returns, double returnsPct) {
    final isPositive = returns >= 0;
    final Color retColor = isPositive ? const Color(0xFF00D09C) : const Color(0xFFEB5B3C);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Current Value", style: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(currentTotal.toStringAsFixed(2), style: GoogleFonts.robotoMono(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("Total Returns", style: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text("${isPositive ? '+' : ''}${returns.toStringAsFixed(2)}", style: GoogleFonts.robotoMono(color: retColor, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text("${isPositive ? '+' : ''}${returnsPct.toStringAsFixed(2)}%", style: TextStyle(color: retColor, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClaimCard(int pendingSteps) {
    final coinsEquivalent = pendingSteps / 100;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2962FF), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Available Steps", style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text("${pendingSteps.toString()}", style: GoogleFonts.robotoMono(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text("≈ ${coinsEquivalent.toStringAsFixed(1)} COINS", style: const TextStyle(color: Color(0xFF00FF66), fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
          Text("Go to Wallet →", style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildHoldingRow(BuildContext context, String name, String qty, String value, String returnAmount, String returnPercent, double price, String stockId) {
    final bool isPositive = returnAmount.startsWith('+');
    final Color trendColor = isPositive ? const Color(0xFF00D09C) : const Color(0xFFEB5B3C);

    return GestureDetector(
      onTap: () => showTradeSheet(context, name, value, trendColor, stockId: stockId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color.alphaBlend(trendColor.withOpacity(0.05), const Color(0xFF1E1E1E).withOpacity(0.8)),
                gradient: RadialGradient(
                  center: Alignment.bottomRight,
                  radius: 2.5,
                  colors: [trendColor.withOpacity(0.30), Colors.transparent],
                  stops: const [0.0, 1.0],
                ),
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.1)),
                  left: BorderSide(color: Colors.white.withOpacity(0.1)),
                  right: BorderSide(color: Colors.white.withOpacity(0.02)),
                  bottom: BorderSide(color: Colors.white.withOpacity(0.02)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text("$qty Qty", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(value, style: GoogleFonts.robotoMono(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(returnAmount, style: TextStyle(color: trendColor, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 4),
                          Text("($returnPercent)", style: TextStyle(color: trendColor, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
