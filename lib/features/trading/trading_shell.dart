import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pages/markets_page.dart';
import 'pages/portfolio_page.dart';
import 'pages/staking_page.dart';
import 'pages/activity_page.dart';
import 'pages/challenges_page.dart';

class TradingShell extends StatefulWidget {
  const TradingShell({super.key});

  @override
  State<TradingShell> createState() => _TradingShellState();
}

class _TradingShellState extends State<TradingShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Moved into build method so Hot Reload correctly updates the list length natively!
    final List<Widget> pages = [
      const MarketsPage(),
      const PortfolioPage(),
      const ChallengesPage(),
      const StakingPage(),
      const ActivityPage(),
    ];

    return Theme(
      data: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212), // Deeper premium black
        textTheme: GoogleFonts.montserratTextTheme(Theme.of(context).textTheme).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      ),
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: pages,
        ),
        bottomNavigationBar: Theme(
          data: ThemeData(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E1E), // Slightly elevated from background
              border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: const Color(0xFF00D09C), // Groww-style vibrant green
              unselectedItemColor: Colors.grey.shade600,
              type: BottomNavigationBarType.fixed,
              selectedLabelStyle: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5),
              unselectedLabelStyle: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w500),
              showUnselectedLabels: true,
              items: const [
                BottomNavigationBarItem(icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.explore_rounded)), label: "EXPLORE"),
                BottomNavigationBarItem(icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.pie_chart_rounded)), label: "PORTFOLIO"),
                BottomNavigationBarItem(icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.group_work_rounded)), label: "CHALLENGES"),
                BottomNavigationBarItem(icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.hub_rounded)), label: "POOLS"),
                BottomNavigationBarItem(icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.receipt_long_rounded)), label: "ORDERS"),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
