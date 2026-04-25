import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/state/app_state.dart';

class ActivityPage extends ConsumerWidget {
  const ActivityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingOrders = ref.watch(pendingOrdersProvider);
    final completedOrders = ref.watch(completedOrdersProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              toolbarHeight: 40,
              expandedHeight: 110,
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    color: const Color(0xFF101010).withOpacity(0.85),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => mainScaffoldKey.currentState?.openDrawer(),
                          child: const Icon(Icons.sort_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          "ORDERS",
                          style: GoogleFonts.lexend(
                            fontWeight: FontWeight.w700,
                            fontSize: 21,
                            letterSpacing: 1.5,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white54, size: 18),
                          onPressed: () {
                            ref.read(pendingOrdersProvider.notifier).refresh();
                            ref.read(completedOrdersProvider.notifier).refresh();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              bottom: const TabBar(
                indicatorColor: Color(0xFF00D09C),
                labelColor: Color(0xFF00D09C),
                unselectedLabelColor: Colors.grey,
                indicatorWeight: 3,
                tabs: [
                  Tab(icon: Icon(Icons.hourglass_bottom_rounded, size: 18), text: "PROCESSING"),
                  Tab(icon: Icon(Icons.check_circle_outline_rounded, size: 18), text: "COMPLETED"),
                ],
              ),
            ),
            SliverFillRemaining(
              child: TabBarView(
                children: [
                  // Processing (Pending orders)
                  _buildOrderList(pendingOrders, isProcessing: true),
                  // Completed (Executed orders)
                  _buildOrderList(completedOrders, isProcessing: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList(List<StockOrder> orders, {required bool isProcessing}) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isProcessing ? Icons.hourglass_empty_rounded : Icons.check_box_outline_blank_rounded,
                color: Colors.white24, size: 48),
            const SizedBox(height: 12),
            Text(
              isProcessing ? "No pending orders" : "No completed trades yet",
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    // Group by date
    final Map<String, List<StockOrder>> grouped = {};
    for (final order in orders) {
      final now = DateTime.now();
      final date = order.createdAt;
      String label;
      if (date.year == now.year && date.month == now.month && date.day == now.day) {
        label = "TODAY";
      } else if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
        label = "YESTERDAY";
      } else {
        label = "${date.day}/${date.month}/${date.year}";
      }
      grouped.putIfAbsent(label, () => []).add(order);
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        for (final entry in grouped.entries) ...[
          _buildDateHeader(entry.key),
          ...entry.value.map((o) {
            final isBuy = o.type == 'buy';
            final color = isBuy ? Colors.greenAccent : Colors.redAccent;
            final title = "${isBuy ? 'BOUGHT' : 'SOLD'} ${o.stockId.toUpperCase()}";
            final subtitle = "${o.quantity} Shares @ ${o.limitPrice.toStringAsFixed(2)}";
            final timeStr = _formatTime(o.createdAt);
            return _buildActivityItem(title, subtitle, timeStr, color);
          }).toList(),
          const SizedBox(height: 16),
        ],
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildDateHeader(String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(date, style: GoogleFonts.outfit(color: Colors.grey.shade500, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return "${diff.inMinutes} mins ago";
    if (diff.inHours < 24) return "${diff.inHours} hours ago";
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  Widget _buildActivityItem(String title, String subtitle, String time, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 48,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          ),
          Text(time, style: TextStyle(color: Colors.grey.shade700, fontSize: 10)),
        ],
      ),
    );
  }
}
