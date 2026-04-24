import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/state/app_state.dart';

class ZonePage extends ConsumerWidget {
  const ZonePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletProvider);
    final campusZones = ref.watch(zonesProvider);
    final orbs = wallet.orbs;
    final activeZone = wallet.activeZone;

    return Stack(
      children: [
        // Map as background
        FlutterMap(
          options: MapOptions(
            initialCenter: const LatLng(25.5358, 84.8510), // IIT Patna anchor
            initialZoom: 16.0,
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
              userAgentPackageName: 'com.example.app',
            ),
            CircleLayer(
              circles: campusZones.map((z) => CircleMarker(
                point: LatLng(z.latitude, z.longitude),
                color: activeZone == z.name ? Colors.orange.withOpacity(0.4) : Colors.blue.withOpacity(0.2),
                borderColor: activeZone == z.name ? Colors.orange : Colors.blue,
                borderStrokeWidth: 2,
                useRadiusInMeter: true,
                radius: z.radiusMeters,
              )).toList(),
            ),
            MarkerLayer(
              markers: [
                // Zone Markers (Labels)
                ...campusZones.map((z) => Marker(
                  point: LatLng(z.latitude, z.longitude),
                  width: 150,
                  height: 60,
                  child: Column(
                    children: [
                      Icon(Icons.location_on, 
                        color: activeZone == z.name ? Colors.orange : Colors.blue, 
                        size: 30
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: activeZone == z.name ? Colors.orange : Colors.black87,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            if (activeZone == z.name)
                              BoxShadow(color: Colors.orange.withOpacity(0.5), blurRadius: 10)
                          ],
                          border: Border.all(color: Colors.white24)
                        ),
                        child: Text(
                          z.name,
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                )),
                
                // User Location Marker
                if (wallet.userLat != null && wallet.userLng != null)
                  Marker(
                    point: LatLng(wallet.userLat!, wallet.userLng!),
                    width: 60,
                    height: 60,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2962FF).withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2962FF),
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            )
          ],
        ),
        
        // Floating header for Orbs
        Positioned(
          top: 24,
          left: 24,
          right: 24,
          child: _buildOrbsHeader(orbs, activeZone),
        ),
      ],
    );
  }

  Widget _buildOrbsHeader(int orbs, String? activeZone) {
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
          const SizedBox(height: 16),
          if (activeZone != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "FARMING IN: ${activeZone.toUpperCase()}",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            )
          else
             Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "MOVE TO A ZONE TO FARM ORBS",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
