import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/state/app_state.dart';
import 'pages/dashboard_page.dart';
import 'pages/mining_hub_page.dart'; // will rename internally to ZonePage
import 'pages/history_page.dart';

class FitnessShell extends ConsumerWidget {
  const FitnessShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const primaryColor = Color(0xFFFF5722);
    const bgColor = Color(0xFFF8F9FA);
    final currentZone = ref.watch(walletProvider).activeZone ?? "Out of Zone";

    return Theme(
      data: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: bgColor,
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
      ),
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.menu_rounded, color: primaryColor),
              onPressed: () => mainScaffoldKey.currentState?.openDrawer(),
            ),
            title: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primaryColor.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.my_location_rounded, color: primaryColor, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    "Current Zone: $currentZone",
                    style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ),
            centerTitle: true,
            bottom: TabBar(
              indicatorColor: primaryColor,
              labelColor: primaryColor,
              unselectedLabelColor: Colors.grey.shade400,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              tabs: const [
                Tab(text: "DASHBOARD"),
                Tab(text: "RECORD"),
                Tab(text: "ZONE"),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              DashboardPage(),
              HistoryPage(), // Renamed internally to record
              ZonePage(), // Was MiningHubPage
            ],
          ),
        ),
      ),
    );
  }
}
