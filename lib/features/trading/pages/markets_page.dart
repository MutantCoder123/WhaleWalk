import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/state/app_state.dart';
import '../../../core/services/api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MarketsPage extends ConsumerStatefulWidget {
  const MarketsPage({super.key});

  @override
  ConsumerState<MarketsPage> createState() => _MarketsPageState();
}

class _MarketsPageState extends ConsumerState<MarketsPage> {
  String _selectedFilter = "All";

  @override
  Widget build(BuildContext context) {
    final stocksSource = ref.watch(marketsProvider);
    
    // Sort logic
    List<Stock> stocks = List.from(stocksSource);
    if (_selectedFilter == "Top Gainers") {
      stocks.sort((a, b) => b.lastDayPercentageChange.compareTo(a.lastDayPercentageChange));
    } else if (_selectedFilter == "Top Losers") {
      stocks.sort((a, b) => a.lastDayPercentageChange.compareTo(b.lastDayPercentageChange));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            toolbarHeight: 60,
            expandedHeight: 40,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  color: const Color(0xFF101010).withOpacity(0.85),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.fromLTRB(24, 5, 24, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => mainScaffoldKey.currentState?.openDrawer(),
                        child: const Icon(Icons.sort_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        "EXPLORE",
                        style: GoogleFonts.lexend(
                          fontWeight: FontWeight.w600,
                          fontSize: 20,
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
          
          // Filter Chips
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                   _buildChip("All"),
                   _buildChip("Top Gainers"),
                   _buildChip("Top Losers")
                ],
              ),
            ),
          ),

          // Markets List
          _buildSectionHeaderSliver("STOCKS"),
          if (stocks.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _MarketEmptyState(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final stock = stocks[index];
                    final changeStr = stock.isUp ? "+${stock.percentageChange.toStringAsFixed(1)}%" : "${stock.percentageChange.toStringAsFixed(1)}%";
                    return _buildAssetRow(context, stock, changeStr, stock.isUp);
                  },
                  childCount: stocks.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    final bool isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        if (label != "Indexes") { // Just ignore dummy indexes for now
          setState(() => _selectedFilter = label);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.white : Colors.white10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildSectionHeaderSliver(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: _buildSectionHeader(title),
      ),
    );
  }

  Widget _buildAssetRow(BuildContext context, Stock stock, String change, bool isPositive) {
    final Color trendColor = isPositive ? const Color(0xFF00D09C) : const Color(0xFFEB5B3C);
    
    return GestureDetector(
      onTap: () => showTradeSheet(context, stock.name, stock.currentPrice.toStringAsFixed(2), trendColor, stockId: stock.symbol, history: stock.history), // Click block -> BottomSheet
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
                  colors: [
                    trendColor.withOpacity(0.30),
                    Colors.transparent,
                  ],
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
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        // Click Name -> Full Page
                        Navigator.push(context, MaterialPageRoute(builder: (context) => Scaffold(
                          appBar: AppBar(
                            backgroundColor: const Color(0xFF101010), 
                            elevation: 0,
                            leading: IconButton(
                              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          backgroundColor: const Color(0xFF121212),
                          body: SingleChildScrollView(child: TradeSheet(asset: stock.name, price: stock.currentPrice.toStringAsFixed(2), accentColor: trendColor, stockId: stock.symbol, history: stock.history)),
                        )));
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(stock.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, decoration: TextDecoration.underline)),
                          const SizedBox(height: 4),
                          Text("AMM", style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Jagged Real Market Sparkline
                  SizedBox(
                    width: 80,
                    height: 30,
                    child: CustomPaint(
                      painter: _MiniChartPainter(color: trendColor, isPositive: isPositive, history: stock.history),
                    ),
                  ),
      
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(stock.currentPrice.toStringAsFixed(2), style: GoogleFonts.robotoMono(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(change, style: TextStyle(color: trendColor, fontSize: 12, fontWeight: FontWeight.bold)),
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

class _MarketEmptyState extends StatelessWidget {
  const _MarketEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.candlestick_chart_rounded, color: Colors.white24, size: 54),
            const SizedBox(height: 16),
            Text(
              "No stocks listed",
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Create stocks from the backend to populate this market.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

void showTradeSheet(BuildContext context, String asset, String price, Color accentColor, {String? stockId, List<double> history = const []}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1A1A1A),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (context) => TradeSheet(asset: asset, price: price, accentColor: accentColor, stockId: stockId, history: history),
  );
}

class _MiniChartPainter extends CustomPainter {
  final Color color;
  final bool isPositive;
  final List<double> history;
  _MiniChartPainter({required this.color, required this.isPositive, required this.history});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    if (history.isEmpty) return;
    
    // Normalize to chart height
    double minPrice = history.reduce((a, b) => a < b ? a : b);
    double maxPrice = history.reduce((a, b) => a > b ? a : b);
    if (maxPrice == minPrice) { maxPrice += 1; minPrice -= 1; }

    for (int i = 0; i < history.length; i++) {
      double dx = size.width * (i / (history.length - 1 == 0 ? 1 : history.length - 1));
      double normY = (history[i] - minPrice) / (maxPrice - minPrice);
      double dy = size.height - (normY * size.height);
      
      if (i == 0) path.moveTo(dx, dy);
      else path.lineTo(dx, dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class TradeSheet extends ConsumerStatefulWidget {
  final String asset;
  final String price;
  final Color accentColor;
  /// The stockId used by the backend (derived from `symbol` if provided)
  final String? stockId;
  final List<double> history;
  const TradeSheet({required this.asset, required this.price, required this.accentColor, this.stockId, this.history = const [], super.key});

  @override
  ConsumerState<TradeSheet> createState() => _TradeSheetState();
}

class _TradeSheetState extends ConsumerState<TradeSheet> {
  String _orderType = "MARKET"; // MARKET, LIMIT
  bool _isBuy = true;
  bool _isPlacingOrder = false;
  final _qtyController = TextEditingController();
  final _limitPriceController = TextEditingController();
  
  // Graph controls
  int _selectedInterval = 0; // 0: 1D, 1: 1W, 2: 1M
  final _intervals = ["1D", "1W", "1M"];

  Future<void> _placeOrder() async {
    final qty = int.tryParse(_qtyController.text.trim());
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid quantity"), backgroundColor: Colors.orange),
      );
      return;
    }

    // Derive stockId: widget.stockId if explicitly passed, else use asset name as a rough key
    final stockId = widget.stockId ?? widget.asset.toUpperCase().replaceAll(' ', '_');
    double? limitPrice;
    if (_orderType == "LIMIT") {
      limitPrice = double.tryParse(_limitPriceController.text.trim());
      if (limitPrice == null || limitPrice <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Enter a valid limit price"), backgroundColor: Colors.orange),
        );
        return;
      }
    }

    setState(() => _isPlacingOrder = true);
    try {
      await apiService.placeOrder(
        stockId: stockId,
        quantity: qty,
        type: _isBuy ? 'buy' : 'sell',
        limitPrice: limitPrice, // null = market order
      );
      // Refresh portfolio, orders and wallet after successful trade
      ref.read(pendingOrdersProvider.notifier).refresh();
      ref.read(completedOrdersProvider.notifier).refresh();
      ref.read(portfolioProvider.notifier).refresh();
      ref.read(walletProvider.notifier).refresh();
      ref.invalidate(transactionsProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ ${_isBuy ? 'BUY' : 'SELL'} order placed for $qty × $stockId"),
            backgroundColor: const Color(0xFF00D09C),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ ${e.toString().replaceAll('Exception: ', '')}"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color actionColor = _isBuy ? const Color(0xFF00D09C) : const Color(0xFFEB5B3C);

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 32, left: 24, right: 24, top: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(widget.asset, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white))),
                const SizedBox(width: 16),
                Text(widget.price, style: GoogleFonts.robotoMono(color: widget.accentColor, fontWeight: FontWeight.bold, fontSize: 20)),
              ],
            ),
            const SizedBox(height: 16),
            
            // Chart Controls (Time + Type)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Interval Chips
                  Row(
                    children: List.generate(_intervals.length, (index) {
                      final isSel = _selectedInterval == index;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedInterval = index),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSel ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isSel ? Colors.white : Colors.white24),
                          ),
                          child: Text(_intervals[index], style: TextStyle(color: isSel ? Colors.black : Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
  
            // Dynamic Chart View
            SizedBox(
              height: 220,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _buildSelectedChart(),
              ),
            ),
            const SizedBox(height: 24),
            
            // BUY / SELL Toggle (Groww uses distinct tabbed approach)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isBuy = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: _isBuy ? const Color(0xFF00D09C) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text("BUY", style: TextStyle(fontWeight: FontWeight.bold, color: _isBuy ? Colors.black : Colors.white)),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isBuy = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: !_isBuy ? const Color(0xFFEB5B3C) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text("SELL", style: TextStyle(fontWeight: FontWeight.bold, color: !_isBuy ? Colors.white : Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
  
            // Order Type Selector
            Row(
              children: ["MARKET", "LIMIT"].map((type) => GestureDetector(
                onTap: () => setState(() => _orderType = type),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: _orderType == type ? actionColor : Colors.transparent, width: 2)),
                  ),
                  child: Text(type, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _orderType == type ? actionColor : Colors.white54)),
                ),
              )).toList(),
            ),
            const SizedBox(height: 24),
  
            TextField(
              controller: _qtyController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: "Qty",
                labelStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: actionColor)),
                fillColor: const Color(0xFF1E1E1E),
                filled: true,
              ),
            ),
            if (_orderType == "LIMIT") ...[
              const SizedBox(height: 16),
              TextField(
                controller: _limitPriceController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  labelText: "Limit Price",
                  labelStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: actionColor)),
                  fillColor: const Color(0xFF1E1E1E),
                  filled: true,
                ),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: actionColor,
                  foregroundColor: _isBuy ? Colors.black : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isPlacingOrder ? null : _placeOrder,
                child: _isPlacingOrder
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : Text(
                        _isBuy ? "BUY" : "SELL",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedChart() {
    return Container(
      color: const Color(0xFF1E1E1E),
      width: double.infinity,
      child: CustomPaint(
        painter: _RealChartPainter(
          history: widget.history,
          accentColor: widget.accentColor,
          intervalSize: _selectedInterval,
        ),
      ),
    );
  }
}

class _RealChartPainter extends CustomPainter {
  final List<double> history;
  final Color accentColor;
  final int intervalSize; // 0=1D, 1=1W, 2=1M

  _RealChartPainter({required this.history, required this.accentColor, required this.intervalSize});

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty) return;

    // Filter points based on interval logic.
    int takePoints = history.length;
    if (intervalSize == 0) takePoints = 24; // 1D
    else if (intervalSize == 1) takePoints = 168; // 1W
    else if (intervalSize == 2) takePoints = 720; // 1M
    
    // We only have max history, so take up to what we actually have
    final data = history.reversed.take(takePoints).toList().reversed.toList();
    if (data.isEmpty) return;

    // 1. Draw Grid and Axes Strings
    _drawAxes(canvas, size);

    final chartRect = Rect.fromLTWH(0, 0, size.width - 40, size.height - 20);

    double minPrice = data.reduce((a, b) => a < b ? a : b);
    double maxPrice = data.reduce((a, b) => a > b ? a : b);
    if (maxPrice == minPrice) { maxPrice += 1; minPrice -= 1; }

    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      double dx = chartRect.width * (i / (data.length - 1 == 0 ? 1 : data.length - 1));
      double normY = (data[i] - minPrice) / (maxPrice - minPrice);
      double dy = chartRect.height - (normY * chartRect.height);
      points.add(Offset(dx, dy));
    }

    final p = Path();
    p.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
        p.lineTo(points[i].dx, points[i].dy);
    }
    
    // Area Fill
    final areaPath = Path.from(p);
    areaPath.lineTo(chartRect.width, chartRect.height);
    areaPath.lineTo(0, chartRect.height);
    areaPath.close();
    
    canvas.drawPath(areaPath, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [accentColor.withOpacity(0.5), accentColor.withOpacity(0.0)],
      ).createShader(chartRect)
    );
    
    // Stroke on top
    canvas.drawPath(p, Paint()..color=accentColor..strokeWidth=2.0..style=PaintingStyle.stroke);
  }

  void _drawAxes(Canvas canvas, Size size) {
    final gridPaint = Paint()..color = Colors.white10..strokeWidth = 1.0;
    // Y-Axis Horizontal Lines
    for (int i = 1; i <= 4; i++) {
        double y = (size.height - 20) * (i / 5);
        canvas.drawLine(Offset(0, y), Offset(size.width - 40, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
