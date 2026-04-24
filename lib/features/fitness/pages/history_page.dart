import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/state/app_state.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  String _showingStat = 'steps'; // 'steps' | 'distance'

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFFF5722);
    final secondaryColor = Colors.orange.shade300;
    const mutedTextColor = Colors.grey;
    final historyAsync = ref.watch(historyProvider);

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: primaryColor)),
      error: (err, stack) => Center(child: Text("Error: $err")),
      data: (history) {
        if (history.isEmpty) {
          return const _NoDataState();
        }

        double maxY = 0;
        if (_showingStat == 'steps') {
          maxY = history.map((e) => (e['actualSteps'] ?? 0).toDouble()).reduce((a, b) => a > b ? a : b) * 1.2;
          if (maxY < 1000) maxY = 1000;
        } else {
          maxY = history.map((e) => (e['distanceKm'] ?? 0).toDouble()).reduce((a, b) => a > b ? a : b) * 1.2;
          if (maxY < 1.0) maxY = 1.0;
        }

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "LAST 7 DAYS", 
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: mutedTextColor, letterSpacing: 1.5)
                ),
                _buildToggle(),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 250,
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => Colors.black87,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${rod.toY.toStringAsFixed(_showingStat == 'steps' ? 0 : 1)}${_showingStat == 'steps' ? '' : ' KM'}',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          if (value.toInt() >= history.length) return const SizedBox.shrink();
                          final dateStr = history[value.toInt()]['date'] as String;
                          final date = DateTime.parse(dateStr);
                          final labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8), 
                            child: Text(labels[date.weekday - 1], style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 10))
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(history.length, (i) {
                    final val = (_showingStat == 'steps' 
                      ? (history[i]['actualSteps'] ?? 0) 
                      : (history[i]['distanceKm'] ?? 0)).toDouble();
                    return _buildBarGroup(i, val, maxY, _showingStat == 'steps' ? primaryColor : secondaryColor);
                  }),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text("ACTIVITY LOG", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: mutedTextColor, letterSpacing: 1.5)),
            const SizedBox(height: 16),
            ...history.reversed.map((data) {
              final date = DateTime.parse(data['date']);
              final isToday = DateTime.now().toIso8601String().slice(0, 10) == data['date'];
              return _buildHistoryDay(
                isToday ? "TODAY" : _getWeekdayName(date.weekday), 
                "${data['actualSteps']} Steps", 
                "${(data['distanceKm'] as num).toStringAsFixed(1)} KM", 
                const Color(0xFF212529), 
                mutedTextColor
              );
            }),
          ],
        );
      }
    );
  }

  Widget _buildToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleButton('STEPS', _showingStat == 'steps', () => setState(() => _showingStat = 'steps')),
          _ToggleButton('DIST', _showingStat == 'distance', () => setState(() => _showingStat = 'distance')),
        ],
      ),
    );
  }

  Widget _ToggleButton(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFFF5722) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label, 
          style: TextStyle(
            color: active ? Colors.white : Colors.grey, 
            fontSize: 10, 
            fontWeight: FontWeight.bold
          )
        ),
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y, double maxY, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 16,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          backDrawRodData: BackgroundBarChartRodData(show: true, toY: maxY, color: Colors.grey.shade100),
        ),
      ],
    );
  }

  Widget _buildHistoryDay(String day, String steps, String distance, Color textColor, Color mutedTextColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFFF5722).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.directions_run_rounded, color: Color(0xFFFF5722), size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(day, style: TextStyle(color: mutedTextColor, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1)),
                  Text(steps, style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
            ],
          ),
          Text(distance, style: GoogleFonts.robotoMono(color: Colors.orange.shade700, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  String _getWeekdayName(int weekday) {
    const days = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'];
    return days[weekday - 1];
  }
}

extension StringExtension on String {
  String slice(int start, int end) => substring(start, end);
}

class _NoDataState extends StatelessWidget {
  const _NoDataState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text("NO ACTIVITY RECORDED", style: GoogleFonts.outfit(color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Start walking to see your progress!", style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}
