import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/state/app_state.dart';

class WalletPage extends ConsumerStatefulWidget {
  const WalletPage({super.key});

  @override
  ConsumerState<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends ConsumerState<WalletPage> {
  final TextEditingController _stepController = TextEditingController();
  final TextEditingController _orbController = TextEditingController();
  double _stepCoins = 0.0;
  double _orbCoins = 0.0;
  bool _isConverting = false;

  @override
  void initState() {
    super.initState();
    _stepController.addListener(() {
      setState(() {
        _stepCoins = (double.tryParse(_stepController.text) ?? 0) / 100.0;
      });
    });
    _orbController.addListener(() {
      setState(() {
        _orbCoins = (double.tryParse(_orbController.text) ?? 0) * 5.0;
      });
    });
  }

  @override
  void dispose() {
    _stepController.dispose();
    _orbController.dispose();
    super.dispose();
  }

  Future<void> _convertNow() async {
    final typedSteps = int.tryParse(_stepController.text) ?? 0;
    final typedOrbs = int.tryParse(_orbController.text) ?? 0;

    if (typedSteps == 0 && typedOrbs == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter steps or orbs to convert"), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isConverting = true);
    try {
      double totalCoinsEarned = 0;

      if (typedSteps > 0) {
        final result = await ref.read(walletProvider.notifier).convertSteps(typedSteps);
        if (result) {
          totalCoinsEarned += _stepCoins;
          _stepController.clear();
        }
      }

      if (typedOrbs > 0) {
        final result = await ref.read(walletProvider.notifier).convertOrbs(typedOrbs);
        if (result) {
          totalCoinsEarned += _orbCoins;
          _orbController.clear();
        }
      }

      if (totalCoinsEarned > 0) {
        ref.invalidate(transactionsProvider);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ Earned ${totalCoinsEarned.toStringAsFixed(2)} Campus Coins!"),
            backgroundColor: const Color(0xFF00D09C),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ ${e.toString().replaceAll('Exception: ', '')}"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isConverting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletProvider);
    final availableSteps = wallet.stepsCount;
    final availableOrbs = wallet.orbs;
    final availableCoins = wallet.campusCoins;

    int typedSteps = int.tryParse(_stepController.text) ?? 0;
    int typedOrbs = int.tryParse(_orbController.text) ?? 0;

    int remainingSteps = availableSteps - typedSteps;
    int remainingOrbs = availableOrbs - typedOrbs;

    final txnsAsync = ref.watch(transactionsProvider);

    return Theme(
      data: ThemeData.dark(),
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: const Color(0xFF121212),
          title: Text("Wallet", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white54),
              onPressed: () {
                ref.read(walletProvider.notifier).refresh();
                ref.invalidate(transactionsProvider);
              },
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Current Holdings Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(16)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildBalanceMetric("COINS", "${availableCoins.toStringAsFixed(2)}", Colors.amber),
                  _buildBalanceMetric("STEPS", "$availableSteps", Colors.white),
                  _buildBalanceMetric("ORBS", "$availableOrbs", Colors.purpleAccent),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Conversion Facility
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  const Icon(Icons.currency_exchange_rounded, color: Colors.greenAccent, size: 48),
                  const SizedBox(height: 16),
                  Text("Convert Steps to Coins", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Rate: 100 Steps = 1 Coin", style: TextStyle(color: Colors.grey.shade400)),
                      Text("Avail: $availableSteps", style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _stepController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    decoration: InputDecoration(
                      labelText: "Enter Steps",
                      labelStyle: TextStyle(color: Colors.grey.shade500),
                      enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white24), borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF00D09C)), borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.directions_walk, color: Colors.white54),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Receive: ${_stepCoins.toStringAsFixed(2)} Coins", style: const TextStyle(color: Color(0xFF00D09C), fontWeight: FontWeight.bold, fontSize: 14)),
                      Text("Rem: ${remainingSteps >= 0 ? remainingSteps : 0} Steps", style: TextStyle(color: remainingSteps >= 0 ? Colors.white : Colors.red, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Divider(color: Colors.white10),
                  ),

                  Text("Convert Special Orbs", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Rate: 1 Orb = 5 Coins", style: TextStyle(color: Colors.grey.shade400)),
                      Text("Avail: $availableOrbs", style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _orbController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    decoration: InputDecoration(
                      labelText: "Enter Orbs",
                      labelStyle: TextStyle(color: Colors.grey.shade500),
                      enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white24), borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.purpleAccent), borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.blur_on_rounded, color: Colors.purpleAccent),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Receive: ${_orbCoins.toStringAsFixed(2)} Coins", style: const TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                      Text("Rem: ${remainingOrbs >= 0 ? remainingOrbs : 0} Orbs", style: TextStyle(color: remainingOrbs >= 0 ? Colors.white : Colors.red, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00D09C),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isConverting ? null : _convertNow,
                      child: _isConverting
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                          : const Text("CONVERT NOW", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text("TRANSACTION HISTORY", style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1.5)),
            const SizedBox(height: 16),
            
            txnsAsync.when(
              data: (txns) {
                if (txns.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text("No transactions yet.", style: TextStyle(color: Colors.grey.shade600)),
                    ),
                  );
                }
                return Column(
                  children: txns.map((t) {
                    final isToday = t.createdAt.day == DateTime.now().day;
                    final timePrefix = isToday ? "Today," : "${t.createdAt.day}/${t.createdAt.month}";
                    final timeString = "$timePrefix ${t.createdAt.hour.toString().padLeft(2, '0')}:${t.createdAt.minute.toString().padLeft(2, '0')}";
                    
                    return _buildTxRow(t.title, "${t.isPositive ? '+' : ''}${t.amount.toStringAsFixed(2)} Coins", timeString, t.isPositive);
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
            ),
            
            const SizedBox(height: 48), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildTxRow(String title, String amount, String time, bool isPositive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(time, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            ],
          ),
          Text(
            amount,
            style: TextStyle(
              color: isPositive ? const Color(0xFF00D09C) : const Color(0xFFEB5B3C),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
