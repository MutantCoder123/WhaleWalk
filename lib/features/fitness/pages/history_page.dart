import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFFF5722);
    const mutedTextColor = Colors.grey;
    const textColor = Color(0xFF212529);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text("LAST 7 DAYS", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: mutedTextColor, letterSpacing: 1.5)),
        const SizedBox(height: 16),
        Container(
          height: 250,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 15000,
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      const style = TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 10);
                      const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                      return Padding(padding: const EdgeInsets.only(top: 8), child: Text(days[value.toInt() % 7], style: style));
                    },
                  ),
                ),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: [
                 _buildBarGroup(0, 8000, primaryColor),
                 _buildBarGroup(1, 14000, primaryColor),
                 _buildBarGroup(2, 8400, primaryColor),
                 _buildBarGroup(3, 12105, primaryColor),
                 _buildBarGroup(4, 7432, primaryColor),
                 _buildBarGroup(5, 5000, primaryColor),
                 _buildBarGroup(6, 11000, primaryColor),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text("ACTIVITY LOG", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: mutedTextColor, letterSpacing: 1.5)),
        const SizedBox(height: 16),
        _buildHistoryDay("TODAY", "7,432 Steps", "120 Coins Earned", textColor, mutedTextColor),
        _buildHistoryDay("YESTERDAY", "12,105 Steps", "185 Coins Earned", textColor, mutedTextColor),
        _buildHistoryDay("WEDNESDAY", "8,400 Steps", "130 Coins Earned", textColor, mutedTextColor),
        _buildHistoryDay("TUESDAY", "14,000 Steps", "210 Coins Earned", textColor, mutedTextColor),
      ],
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 16,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
    );
  }


  Widget _buildHistoryDay(String day, String steps, String coins, Color textColor, Color mutedTextColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(day, style: TextStyle(color: mutedTextColor, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1)),
              Text(steps, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          Text(coins, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}
