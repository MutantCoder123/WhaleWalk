import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/state/app_state.dart';

class ZonePage extends ConsumerWidget {
  const ZonePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentZone = ref.watch(currentZoneProvider);
    final orbs = ref.watch(orbsProvider);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildOrbsHeader(orbs),
        const SizedBox(height: 32),
        const Text("AVAILABLE ZONES", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey, letterSpacing: 1.5)),
        const SizedBox(height: 16),
        _buildZoneOption(context, ref, "Library", currentZone == "Library"),
        _buildZoneOption(context, ref, "Gym", currentZone == "Gym"),
        _buildZoneOption(context, ref, "Canteen", currentZone == "Canteen"),
        _buildZoneOption(context, ref, "Tech Park", currentZone == "Tech Park"),
      ],
    );
  }

  Widget _buildOrbsHeader(int orbs) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2962FF),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFF2962FF).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          const Icon(Icons.blur_on_rounded, color: Colors.white, size: 48),
          const SizedBox(height: 8),
          const Text("SPECIAL ORBS", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 2)),
          Text("$orbs", style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
          const Text("1 Orb = 5 Coins in Wallet", style: TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildZoneOption(BuildContext context, WidgetRef ref, String zoneName, bool isActive) {
    return InkWell(
      onTap: () => ref.read(currentZoneProvider.notifier).state = zoneName,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isActive ? Colors.orange.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? const Color(0xFFFF5722) : Colors.grey.shade200, width: isActive ? 2 : 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(zoneName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isActive ? const Color(0xFFFF5722) : Colors.black)),
            if (isActive) const Icon(Icons.check_circle_rounded, color: Color(0xFFFF5722)),
          ],
        ),
      ),
    );
  }
}
