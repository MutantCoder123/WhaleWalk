import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/state/app_state.dart';
import '../../core/services/api_service.dart';

class InventoryView extends ConsumerStatefulWidget {
  const InventoryView({super.key});

  @override
  ConsumerState<InventoryView> createState() => _InventoryViewState();
}

class _InventoryViewState extends ConsumerState<InventoryView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _categories = ['All', 'Badges', 'Titles', 'Themes'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _categoryFilter(int index) {
    switch (index) {
      case 1:
        return 'badge';
      case 2:
        return 'title';
      case 3:
        return 'theme';
      default:
        return 'all';
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'badge':
        return Icons.military_tech_rounded;
      case 'title':
        return Icons.workspace_premium_rounded;
      case 'theme':
        return Icons.palette_rounded;
      default:
        return Icons.inventory_2_rounded;
    }
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'badge':
        return const Color(0xFFFFD700);
      case 'title':
        return const Color(0xFF00E5FF);
      case 'theme':
        return const Color(0xFFE040FB);
      default:
        return Colors.white;
    }
  }

  List<InventoryItem> _filteredItems(List<InventoryItem> items) {
    final filter = _categoryFilter(_tabController.index);
    if (filter == 'all') return items;
    return items.where((item) => item.category == filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final inventoryState = ref.watch(inventoryProvider);
    final filtered = _filteredItems(inventoryState.items);

    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D0E12),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0E12),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white70, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inventory_2_rounded, color: Color(0xFF00E5FF), size: 20),
              const SizedBox(width: 8),
              Text(
                "INVENTORY",
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 2,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white54),
              onPressed: () => ref.read(inventoryProvider.notifier).refresh(),
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF16171B),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white10),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2962FF), Color(0xFF00E5FF)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2962FF).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white38,
                labelStyle: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
                unselectedLabelStyle: GoogleFonts.outfit(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
                tabs: _categories.map((c) => Tab(text: c.toUpperCase())).toList(),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00E5FF),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "${filtered.length} ITEM${filtered.length == 1 ? '' : 'S'}",
                    style: GoogleFonts.outfit(
                      color: Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "${inventoryState.items.where((i) => i.isEquipped).length} EQUIPPED",
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF00E5FF).withOpacity(0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: inventoryState.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF00E5FF),
                        strokeWidth: 2,
                      ),
                    )
                  : inventoryState.error != null
                      ? _buildErrorState(inventoryState.error!)
                      : filtered.isEmpty
                          ? _buildEmptyState()
                          : _buildItemGrid(filtered),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
          const SizedBox(height: 16),
          Text(
            "Failed to load inventory",
            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => ref.read(inventoryProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text("Retry"),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF00E5FF)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, color: Colors.white.withOpacity(0.15), size: 72),
          const SizedBox(height: 16),
          Text(
            "NO ITEMS YET",
            style: GoogleFonts.outfit(
              color: Colors.white30,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Visit the store to purchase items",
            style: GoogleFonts.outfit(color: Colors.white24, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildItemGrid(List<InventoryItem> items) {
    final badges = items.where((item) => item.category == 'badge').toList();
    final titles = items.where((item) => item.category == 'title').toList();

    return CustomScrollView(
      slivers: [
        if (badges.isNotEmpty) ...[
          _buildSectionHeader("BADGES"),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                childAspectRatio: 1.0,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildBadgeCard(badges[index]),
                childCount: badges.length,
              ),
            ),
          ),
        ],

        if (titles.isNotEmpty) ...[
          _buildSectionHeader("TITLES"),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildTitleCard(titles[index]),
                childCount: titles.length,
              ),
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        child: Row(
          children: [
            Text(
              title,
              style: GoogleFonts.lexend(
                color: Colors.white.withOpacity(0.3),
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Divider(color: Colors.white.withOpacity(0.05), thickness: 1)),
          ],
        ),
      ),
    );
  }

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

  Widget _buildBadgeCard(InventoryItem item) {
    final rarityColor = _getRarityColor(item.rarity);
    final icon = _categoryIcon(item.category);

    return GestureDetector(
      onTap: () => _showItemDetail(item),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: const Color(0xFF16171B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: item.isEquipped ? rarityColor.withOpacity(0.6) : Colors.white.withOpacity(0.05),
            width: item.isEquipped ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: rarityColor.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: rarityColor, size: 20),
              ),
              if (item.isEquipped)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: rarityColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF16171B), width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleCard(InventoryItem item) {
    final rarityColor = _getRarityColor(item.rarity);

    return GestureDetector(
      onTap: () => _showItemDetail(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF16171B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: item.isEquipped ? rarityColor.withOpacity(0.6) : Colors.white.withOpacity(0.05),
            width: item.isEquipped ? 1.5 : 1,
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
                    style: GoogleFonts.lexend(
                      color: rarityColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (item.isEquipped)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: rarityColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: rarityColor.withOpacity(0.3)),
                ),
                child: Text(
                  "EQUIPPED",
                  style: GoogleFonts.outfit(
                    color: rarityColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showItemDetail(InventoryItem item) {
    final color = _categoryColor(item.category);
    final icon = _categoryIcon(item.category);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final currentState = ref.watch(inventoryProvider);
            final currentItem = currentState.items.firstWhere((i) => i.id == item.id, orElse: () => item);
            final isEquipped = currentItem.isEquipped;
            final canEquip = item.category == 'badge' || item.category == 'title';

            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF16171B).withOpacity(0.95),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border.all(color: color.withOpacity(0.2)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 24),
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(24), border: Border.all(color: color.withOpacity(0.3))),
                      child: Icon(icon, color: color, size: 40),
                    ),
                    const SizedBox(height: 20),
                    Text(item.name, style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 0.5), textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: color, size: 14), const SizedBox(width: 6), Text(item.category.toUpperCase(), style: GoogleFonts.outfit(color: color, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5))]),
                    ),
                    const SizedBox(height: 16),
                    if (item.description.isNotEmpty)
                      Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)), child: Text(item.description, style: GoogleFonts.outfit(color: Colors.white60, fontSize: 14, height: 1.5), textAlign: TextAlign.center)),
                    const SizedBox(height: 24),
                    if (canEquip)
                      SizedBox(
                        width: double.infinity, height: 52,
                        child: ElevatedButton(
                          onPressed: isEquipped ? null : () async {
                            try {
                              await ref.read(inventoryProvider.notifier).equipItem(item.id);
                              if (context.mounted) Navigator.pop(context);
                            } catch (e) {}
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: isEquipped ? color.withOpacity(0.15) : const Color(0xFF2962FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                          child: Text(isEquipped ? "CURRENTLY EQUIPPED" : "EQUIP ITEM", style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
