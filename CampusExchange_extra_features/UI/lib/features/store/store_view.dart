import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/state/app_state.dart';
import '../../core/services/api_service.dart';
import 'dart:ui';

class StoreView extends ConsumerStatefulWidget {
  const StoreView({super.key});

  @override
  ConsumerState<StoreView> createState() => _StoreViewState();
}

class _StoreViewState extends ConsumerState<StoreView> {
  Color _getRarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'common': return Colors.grey.shade400;
      case 'uncommon': return Colors.greenAccent;
      case 'rare': return Colors.blueAccent;
      case 'epic': return Colors.purpleAccent;
      case 'legendary': return Colors.orangeAccent;
      case 'mythic': return Colors.pinkAccent;
      default: return Colors.amber;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'badge': return Icons.verified_rounded;
      case 'title': return Icons.title_rounded;
      case 'theme': return Icons.palette_rounded;
      default: return Icons.category_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final storeState = ref.watch(storeProvider);
    final wallet = ref.watch(walletProvider);
    final inventory = ref.watch(inventoryProvider);

    final ownedIds = inventory.items.map((i) => i.id).toSet();

    final badges = storeState.items
        .where((item) => item.category == 'badge' && !ownedIds.contains(item.id))
        .toList();
    final titles = storeState.items
        .where((item) => item.category == 'title' && !ownedIds.contains(item.id))
        .toList();

    return Theme(
      data: ThemeData.dark(),
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: CustomScrollView(
          slivers: [
            // ── Glassmorphic app bar (matches rest of app) ──────────
            SliverAppBar(
              toolbarHeight: 60,
              expandedHeight: 60,
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    color: const Color(0xFF101010).withOpacity(0.85),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.fromLTRB(60, 0, 24, 0),
                    child: Row(
                      children: [
                        Text(
                          "STORE",
                          style: GoogleFonts.lexend(
                            fontWeight: FontWeight.w700,
                            fontSize: 22,
                            letterSpacing: 1.5,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        // Coin balance pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.amber.withOpacity(0.25)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.monetization_on_rounded, color: Colors.amber, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                "${wallet.campusCoins.toInt()}",
                                style: GoogleFonts.robotoMono(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            if (storeState.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: Color(0xFF2962FF))),
              )
            else ...[
              // ── BADGES SECTION ──────────────────────────────────
              if (badges.isNotEmpty) ...[
                _buildSectionHeader("BADGES"),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildBadgeCard(badges[index]),
                      childCount: badges.length,
                    ),
                  ),
                ),
              ],

              // ── TITLES SECTION ─────────────────────────────────
              if (titles.isNotEmpty) ...[
                _buildSectionHeader("TITLES"),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildTitleCard(titles[index]),
                      childCount: titles.length,
                    ),
                  ),
                ),
              ],
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // Section header
  // ===========================================================================
  Widget _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
        child: Row(
          children: [
            Text(
              title,
              style: GoogleFonts.lexend(
                color: Colors.grey.shade500,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Divider(color: Colors.white.withOpacity(0.06), thickness: 1)),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // Badge card — glassmorphic style
  // ===========================================================================
  Widget _buildBadgeCard(StoreItem item) {
    final rarityColor = _getRarityColor(item.rarity);
    final icon = _categoryIcon(item.category);

    return GestureDetector(
      onTap: () => _showPurchaseDialog(item),
      child: Container(
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            rarityColor.withOpacity(0.04),
            const Color(0xFF1E1E1E),
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(color: rarityColor.withOpacity(0.08), blurRadius: 12, spreadRadius: -4),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            // Badge image / icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: rarityColor.withOpacity(0.08),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: rarityColor.withOpacity(0.15), blurRadius: 16, spreadRadius: -2),
                ],
              ),
              child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.network(
                        apiService.getMediaUrl(item.imageUrl!),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            Icon(icon, color: rarityColor, size: 22),
                      ),
                    )
                  : Icon(icon, color: rarityColor, size: 22),
            ),
            const Spacer(),
            // Price pill at bottom
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.15),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(19),
                  bottomRight: Radius.circular(19),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.monetization_on_rounded, color: Colors.amber, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    "${item.price.toInt()}",
                    style: GoogleFonts.robotoMono(
                      color: Colors.amber,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // Title card — glassmorphic banner style
  // ===========================================================================
  Widget _buildTitleCard(StoreItem item) {
    final rarityColor = _getRarityColor(item.rarity);

    return GestureDetector(
      onTap: () => _showPurchaseDialog(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: Color.alphaBlend(
                  rarityColor.withOpacity(0.04),
                  const Color(0xFF1E1E1E).withOpacity(0.8),
                ),
                gradient: RadialGradient(
                  center: Alignment.centerLeft,
                  radius: 3.0,
                  colors: [rarityColor.withOpacity(0.12), Colors.transparent],
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
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name.toUpperCase(),
                          style: GoogleFonts.montserrat(
                            color: rarityColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            shadows: [
                              Shadow(color: rarityColor.withOpacity(0.4), blurRadius: 12),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.description,
                          style: GoogleFonts.outfit(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.withOpacity(0.15)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.monetization_on_rounded, color: Colors.amber, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          "${item.price.toInt()}",
                          style: GoogleFonts.robotoMono(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
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

  // ===========================================================================
  // Purchase dialog — glassmorphic
  // ===========================================================================
  void _showPurchaseDialog(StoreItem item) {
    final rarityColor = _getRarityColor(item.rarity);
    final icon = _categoryIcon(item.category);
    bool isBuying = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1F),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.all(28),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Item icon / image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: rarityColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: rarityColor.withOpacity(0.25), width: 2),
                  boxShadow: [
                    BoxShadow(color: rarityColor.withOpacity(0.2), blurRadius: 20, spreadRadius: -4),
                  ],
                ),
                child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: Image.network(
                          apiService.getMediaUrl(item.imageUrl!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Icon(icon, color: rarityColor, size: 36),
                        ),
                      )
                    : Icon(icon, color: rarityColor, size: 36),
              ),
              const SizedBox(height: 20),

              // Name
              Text(
                item.name,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),

              // Description
              Text(
                item.description,
                style: GoogleFonts.outfit(color: Colors.grey.shade500, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),

              // Rarity tag
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: rarityColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: rarityColor.withOpacity(0.3)),
                ),
                child: Text(
                  item.rarity.toUpperCase(),
                  style: GoogleFonts.montserrat(
                    color: rarityColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Price row
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Price", style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                    Row(
                      children: [
                        const Icon(Icons.monetization_on_rounded, color: Colors.amber, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          "${item.price.toInt()}",
                          style: GoogleFonts.robotoMono(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Buy button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D09C),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: isBuying ? null : () async {
                    setState(() => isBuying = true);
                    try {
                      await ref.read(storeProvider.notifier).buyItem(item.id);
                      await ref.read(walletProvider.notifier).refresh();
                      await ref.read(inventoryProvider.notifier).refresh();
                      if (context.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("✅ Purchased ${item.name}!"),
                            backgroundColor: const Color(0xFF00D09C),
                          ),
                        );
                      }
                    } catch (e) {
                      setState(() => isBuying = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("❌ ${e.toString().replaceAll('Exception: ', '')}"),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    }
                  },
                  child: isBuying
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : Text("PURCHASE NOW", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel", style: TextStyle(color: Colors.white38)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
