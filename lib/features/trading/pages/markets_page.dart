import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math';
import 'package:google_fonts/google_fonts.dart';
import 'package:candlesticks/candlesticks.dart';
import '../../../core/state/app_state.dart';
import '../../../core/services/api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MarketsPage extends ConsumerWidget {
  const MarketsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stocks = ref.watch(marketsProvider);
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
                        "EXPLORE",
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
          
          // Filter Chips
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                   _buildChip("All", true),
                   _buildChip("Top Gainers", false),
                   _buildChip("Top Losers", false),
                   _buildChip("Indexes", false),
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
                    return _buildAssetRow(context, stock.symbol, stock.name, stock.currentPrice.toStringAsFixed(2), changeStr, stock.isUp);
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

  Widget _buildChip(String label, bool isSelected) {
    return Container(
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

  Widget _buildAssetRow(BuildContext context, String symbol, String name, String price, String change, bool isPositive) {
    final Color trendColor = isPositive ? const Color(0xFF00D09C) : const Color(0xFFEB5B3C);
    
    return GestureDetector(
      onTap: () => showTradeSheet(context, name, price, trendColor, stockId: symbol), // Click block -> BottomSheet
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
                  GestureDetector(
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
                        body: SingleChildScrollView(child: TradeSheet(asset: name, price: price, accentColor: trendColor, stockId: symbol)),
                      )));
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, decoration: TextDecoration.underline)),
                        const SizedBox(height: 4),
                        Text("AMM", style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                      ],
                    ),
                  ),
                  
                  // Jagged Real Market Sparkline
                  SizedBox(
                    width: 80,
                    height: 30,
                    child: CustomPaint(
                      painter: _MiniChartPainter(color: trendColor, isPositive: isPositive),
                    ),
                  ),
      
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(price, style: GoogleFonts.robotoMono(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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

void showTradeSheet(BuildContext context, String asset, String price, Color accentColor, {String? stockId}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1A1A1A),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (context) => TradeSheet(asset: asset, price: price, accentColor: accentColor, stockId: stockId),
  );
}

class _MiniChartPainter extends CustomPainter {
  final Color color;
  final bool isPositive;
  _MiniChartPainter({required this.color, required this.isPositive});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final random = Random(isPositive ? 42 : 24);
    
    double cy = size.height / 2;
    path.moveTo(0, cy);
    
    // Generate 15 rough segments
    for (int i = 1; i <= 15; i++) {
      double dx = size.width * (i / 15);
      
      // Gradually move towards positive or negative based on trend
      double drift = isPositive ? -(i * 1.5) : (i * 1.5);
      cy = cy + (random.nextDouble() * 10 - 5) + (drift / 15);
      
      // Clamp bounds
      cy = cy.clamp(0.0, size.height);
      path.lineTo(dx, cy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TradeSheet extends ConsumerStatefulWidget {
  final String asset;
  final String price;
  final Color accentColor;
  /// The stockId used by the backend (derived from `symbol` if provided)
  final String? stockId;
  const TradeSheet({required this.asset, required this.price, required this.accentColor, this.stockId, super.key});

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
  int _selectedInterval = 1; // 0: 1H, 1: 1D, 2: 1M, 3: 1Y
  int _selectedChartType = 0; // 0: Candle, 1: Line, 2: Area, 3: Bar

  final _intervals = ["1H", "1D", "1M", "1Y"];

  List<Candle> _generateMockCandles() {
    return List.generate(40, (index) {
      final close = 100.0 + (index * 2) % 20 - 10;
      return Candle(
        date: DateTime.now().subtract(Duration(days: index)),
        high: close + 5,
        low: close - 5,
        open: close + (index % 2 == 0 ? -2 : 2),
        close: close,
        volume: 1000.0 * (index % 5 + 1),
      );
    });
  }

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

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.asset, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white)),
              Text(widget.price, style: GoogleFonts.robotoMono(color: widget.accentColor, fontWeight: FontWeight.bold, fontSize: 20)),
            ],
          ),
          const SizedBox(height: 16),
          
          // Chart Controls (Time + Type)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              // Chart Type Buttons
              Row(
                children: [
                  _buildChartTypeIcon(0, Icons.candlestick_chart),
                  _buildChartTypeIcon(1, Icons.show_chart),
                  _buildChartTypeIcon(2, Icons.area_chart),
                  _buildChartTypeIcon(3, Icons.bar_chart),
                ],
              )
            ],
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
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildChartTypeIcon(int index, IconData icon) {
    final isSel = _selectedChartType == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedChartType = index),
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFF2962FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: isSel ? Colors.white : Colors.white54),
      ),
    );
  }

  Widget _buildSelectedChart() {
    if (_selectedChartType == 0) {
      return Candlesticks(candles: _generateMockCandles());
    }
    
    // Custom painted lines/area/bars for dummy visualization
    return Container(
      color: const Color(0xFF1E1E1E),
      width: double.infinity,
      child: CustomPaint(
        painter: _MockChartPainter(
          type: _selectedChartType,
          accentColor: widget.accentColor,
          intervalSalt: _selectedInterval,
        ),
      ),
    );
  }
}

class _MockChartPainter extends CustomPainter {
  final int type; 
  final Color accentColor;
  final int intervalSalt;

  _MockChartPainter({required this.type, required this.accentColor, required this.intervalSalt});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Grid and Axes Strings
    _drawAxes(canvas, size);

    // Padding for chart rendering
    final chartRect = Rect.fromLTWH(0, 0, size.width - 40, size.height - 20);

    if (type == 3) {
      _paintBars(canvas, chartRect);
      return;
    }

    final paint = Paint()
      ..color = accentColor
      ..strokeWidth = 2.0
      ..style = type == 1 ? PaintingStyle.stroke : PaintingStyle.fill;

    // Generate chaotic mock data
    final random = Random(intervalSalt + 100);
    final points = <Offset>[];
    
    double currentY = chartRect.height * 0.6;
    int pointCount = 30;
    
    for (int i = 0; i < pointCount; i++) {
      double dx = chartRect.width * (i / (pointCount - 1));
      currentY += (random.nextDouble() * 40 - 20);
      currentY = currentY.clamp(chartRect.height * 0.1, chartRect.height * 0.9);
      points.add(Offset(dx, currentY));
    }

    // Smooth Line
    final p = Path();
    p.moveTo(points[0].dx, points[0].dy);
    for (int i = 0; i < points.length - 1; i++) {
      double cx = (points[i].dx + points[i+1].dx) / 2;
      p.quadraticBezierTo(cx, points[i].dy, points[i+1].dx, points[i+1].dy);
    }

    if (type == 1) {
      canvas.drawPath(p, paint);
    } else if (type == 2) {
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
  }

  void _drawAxes(Canvas canvas, Size size) {
    final gridPaint = Paint()..color = Colors.white10..strokeWidth = 1.0;
    // Y-Axis Horizontal Lines
    for (int i = 1; i <= 4; i++) {
        double y = (size.height - 20) * (i / 5);
        canvas.drawLine(Offset(0, y), Offset(size.width - 40, y), gridPaint);
        _drawText(canvas, "${(1000 - i * 150)}", Offset(size.width - 35, y - 6));
    }
    
    // X-Axis Vertical markers based on interval
    List<String> xLabels = [];
    if (intervalSalt == 0) {
      xLabels = ["9:00", "10:00", "11:00", "12:00"]; // 1H
    } else if (intervalSalt == 1) {
      xLabels = ["Mon", "Tue", "Wed", "Thu"]; // 1D
    } else if (intervalSalt == 2) {
      xLabels = ["W1", "W2", "W3", "W4"]; // 1M
    } else {
      xLabels = ["Q1", "Q2", "Q3", "Q4"]; // 1Y
    }
    
    for (int i = 0; i < xLabels.length; i++) {
      double x = (size.width - 40) * ((i + 1) / (xLabels.length + 1));
      _drawText(canvas, xLabels[i], Offset(x - 10, size.height - 15));
    }
  }

  void _drawText(Canvas canvas, String text, Offset position) {
    final span = TextSpan(style: const TextStyle(color: Colors.white54, fontSize: 10), text: text);
    final tp = TextPainter(text: span, textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, position);
  }

  void _paintBars(Canvas canvas, Rect bounds) {
    final random = Random(intervalSalt + 50);
    int barCount = 18;
    final barWidth = bounds.width / (barCount * 1.5);
    
    for (int i = 0; i < barCount; i++) {
      final h = bounds.height * (0.2 + random.nextDouble() * 0.7);
      bool up = random.nextBool();
      Paint paint = Paint()..color = up ? const Color(0xFF00D09C) : const Color(0xFFEB5B3C);
      
      double x = i * (bounds.width / barCount) + (barWidth / 2);
      canvas.drawRect(Rect.fromLTWH(x, bounds.height - h, barWidth, h), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
