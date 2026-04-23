import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/state/app_state.dart';
import 'markets_page.dart';

class StakingPage extends StatefulWidget {
  const StakingPage({super.key});

  @override
  State<StakingPage> createState() => _StakingPageState();
}

class _StakingPageState extends State<StakingPage> {
  double _stakeVal = 100;

  @override
  Widget build(BuildContext context) {
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
                        "POOLS",
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
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                StakingCard(title: "MESS PANEER", question: "Will Mess serve Paneer today?", w: 45000, l: 20000, f: 0.05),
                const SizedBox(height: 24),
                StakingCard(title: "CRICKET FINALS", question: "Will Hostel A win against B?", w: 120000, l: 85000, f: 0.05),
                const SizedBox(height: 24),
                StakingCard(title: "ENDSEM RESULTS", question: "Highest CGPA > 9.8?", w: 60000, l: 40000, f: 0.05),
                const SizedBox(height: 24),
                StakingCard(title: "TECH FEST DATES", question: "Will fest be postponed by a week?", w: 30000, l: 70000, f: 0.05),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class StakingCard extends StatefulWidget {
  final String title;
  final String question;
  final double w;
  final double l;
  final double f;

  const StakingCard({super.key, required this.title, required this.question, required this.w, required this.l, required this.f});

  @override
  State<StakingCard> createState() => _StakingCardState();
}

class _StakingCardState extends State<StakingCard> {
  double _stakeVal = 100;

  @override
  Widget build(BuildContext context) {
    final double potentialPayout = _stakeVal + (_stakeVal / widget.w) * widget.l * (1 - widget.f);

    return GestureDetector(
      onTap: () => showTradeSheet(context, widget.title, "AMM ODDS: ${( (widget.w+widget.l)/widget.w ).toStringAsFixed(2)}x", Colors.blueAccent),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color.alphaBlend(Colors.blueAccent.withOpacity(0.03), const Color(0xFF1E1E1E).withOpacity(0.8)),
                gradient: RadialGradient(
                  center: Alignment.bottomRight,
                  radius: 2.5,
                  colors: [
                    Colors.blueAccent.withOpacity(0.30),
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
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
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
                      body: SingleChildScrollView(child: TradeSheet(asset: widget.title, price: "ODDS", accentColor: Colors.blueAccent)),
                    )));
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(widget.title, style: GoogleFonts.montserrat(color: const Color(0xFF2962FF), fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2, decoration: TextDecoration.underline)),
                      const Icon(Icons.hub_rounded, color: Colors.blueAccent, size: 18),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(widget.question, style: GoogleFonts.montserrat(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMetric("LIQUIDITY", "\$${(widget.w + widget.l).toInt()}"),
                    _buildMetric("MULTIPLIER", "${( (widget.w+widget.l)/widget.w ).toStringAsFixed(2)}x"),
                  ],
                ),
                const SizedBox(height: 24),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFF2962FF),
                    inactiveTrackColor: Colors.white10,
                    thumbColor: Colors.white,
                    overlayColor: const Color(0xFF2962FF).withOpacity(0.2),
                    trackHeight: 6,
                  ),
                  child: Slider(
                    value: _stakeVal,
                    min: 10,
                    max: 1000,
                    onChanged: (val) => setState(() => _stakeVal = val),
                  ),
                ),
                Center(
                  child: Column(
                    children: [
                      Text(
                        "ALLOCATION: ${_stakeVal.toInt()} | POTENTIAL YIELD: ${potentialPayout.toInt()} 🪙",
                        style: GoogleFonts.robotoMono(color: const Color(0xFF00D09C), fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text("Includes Network Burn Fee", style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2962FF),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {},
                    child: Text("FURNISH STAKE", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildMetric(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 10, letterSpacing: 1)),
        Text(val, style: GoogleFonts.robotoMono(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}
