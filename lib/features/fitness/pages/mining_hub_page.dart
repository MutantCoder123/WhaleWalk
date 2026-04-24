import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/state/app_state.dart';

class ZonePage extends ConsumerStatefulWidget {
  const ZonePage({super.key});

  @override
  ConsumerState<ZonePage> createState() => _ZonePageState();
}

class _ZonePageState extends ConsumerState<ZonePage> {
  final MapController _mapController = MapController();
  bool _autoFollow = true;

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletProvider);
    final campusZones = ref.watch(zonesProvider);
    final orbs = wallet.orbs;
    final activeZone = wallet.activeZone;

    // Optional: Auto-follow user logic
    if (_autoFollow && wallet.userLat != null && wallet.userLng != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(LatLng(wallet.userLat!, wallet.userLng!), _mapController.camera.zoom);
      });
    }

    return Stack(
      children: [
        // Map as background
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: const LatLng(25.5358, 84.8510), // IIT Patna anchor
            initialZoom: 16.0,
            onPositionChanged: (pos, hasGesture) {
              if (hasGesture && _autoFollow) {
                setState(() => _autoFollow = false);
              }
            },
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
                if (wallet.userLat != null && wallet.userLng != null)
                  Marker(
                    point: LatLng(wallet.userLat!, wallet.userLng!),
                    width: 60,
                    height: 60,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 25,
                          height: 25,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2962FF).withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2962FF),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 6)],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            )
          ],
        ),
        
        // Recenter Button
        if (!_autoFollow)
          Positioned(
            bottom: 32,
            right: 24,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: const Color(0xFF2962FF),
              onPressed: () => setState(() => _autoFollow = true),
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
          ),

        // Floating header for Orbs
        Positioned(
          top: 24,
          left: 24,
          right: 24,
          child: _buildOrbsHeader(wallet),
        ),
      ],
    );
  }

  Widget _buildOrbsHeader(WalletData wallet) {
    final activeZone = wallet.activeZone;
    final orbs = wallet.orbs;
    final stepsToNext = wallet.stepsToNextOrb;
    final stepsToNearest = wallet.stepsToNearestZone;
    final nearestName = wallet.nearestZoneName;

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
            Column(
              children: [
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
                ),
                const SizedBox(height: 8),
                Text(
                  "Next orb in $stepsToNext steps",
                  style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ],
            )
          else
             Column(
               children: [
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
                if (nearestName != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    "Nearest: $nearestName ($stepsToNearest steps away)",
                    style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ],
               ],
             ),
        ],
      ),
    );
  }
}
