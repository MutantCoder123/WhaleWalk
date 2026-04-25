import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/state/app_state.dart';
import 'features/auth/auth_page.dart';
import 'features/fitness/fitness_shell.dart';
import 'features/trading/trading_shell.dart';
import 'features/profile/profile_view.dart';
import 'features/profile/leaderboard_page.dart';
import 'features/admin/admin_view.dart';
import 'features/trading/pages/wallet_page.dart';
import 'dart:math' as math;

void main() {
  runApp(const ProviderScope(child: CampusExchangeApp()));
}

class CampusExchangeApp extends StatelessWidget {
  const CampusExchangeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Campus Exchange',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    return auth.isLoggedIn ? const MainScaffold() : const AuthPage();
  }
}

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isToggleCollapsed = false;

  @override
  void initState() {
    super.initState();
    // 0.0 means fitness mode invisible (trading visible)
    // 1.0 means fitness mode full screen
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOutExpo);
    
    // Initial state is Fitness Mode, so we start at value 1.0
    _controller.value = 1.0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleMode() {
    final currentMode = ref.read(appModeProvider);
    if (currentMode == AppMode.fitness) {
      // Switch to trading (Light to Dark)
      ref.read(appModeProvider.notifier).state = AppMode.trading;
      _controller.reverse();
    } else {
      // Switch to fitness (Dark to Light)
      ref.read(appModeProvider.notifier).state = AppMode.fitness;
      _controller.forward();
    }
  }

  void _handleToggle() {
    if (_isToggleCollapsed) {
      setState(() => _isToggleCollapsed = false);
    } else {
      _toggleMode();
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _isToggleCollapsed = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(appModeProvider);

    // Listen for new achievements to show notifications globally
    ref.listen(achievementProvider, (previous, next) {
      if (next.newlyUnlocked.isNotEmpty) {
        for (final ach in next.newlyUnlocked) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.stars_rounded, color: Colors.amber),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("ACHIEVEMENT UNLOCKED!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Text(ach.title, style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF1E1E2C),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'VIEW',
                textColor: Colors.amber,
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileView())),
              ),
            ),
          );
        }
        // Clear the newlyUnlocked list so we don't show the same Toast again
        ref.read(achievementProvider.notifier).clearNewlyUnlocked();
      }
    });

    return Scaffold(
      key: mainScaffoldKey,
      drawer: Drawer(
        backgroundColor: mode == AppMode.trading ? const Color(0xFF0D0E12) : Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: mode == AppMode.trading ? const Color(0xFF2962FF) : const Color(0xFFFF5722)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("CAMPUS EXCHANGE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                  Text("v1.4.0", style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.leaderboard_rounded, color: mode == AppMode.trading ? Colors.amber : Colors.orange),
              title: Text("Leaderboard", style: TextStyle(color: mode == AppMode.trading ? Colors.white : Colors.black87)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const LeaderboardPage()));
              },
            ),
            if (mode == AppMode.trading) ...[
              ListTile(
                leading: const Icon(Icons.account_balance_wallet_rounded, color: Colors.greenAccent),
                title: const Text("Wallet", style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const WalletPage()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_rounded, color: Colors.white),
                title: const Text("Profile", style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileView()));
                },
              ),
            ],
            ListTile(
              leading: Icon(Icons.admin_panel_settings_rounded, color: mode == AppMode.trading ? Colors.white : Colors.grey.shade800),
              title: Text("Admin Console", style: TextStyle(color: mode == AppMode.trading ? Colors.white : Colors.black87)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminView()));
              },
            ),
            const Divider(color: Colors.white10),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded, color: Colors.white54),
              title: const Text("About Project", style: TextStyle(color: Colors.white54)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: const Text("Logout", style: TextStyle(color: Colors.redAccent)),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(authProvider.notifier).logout();
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Bottom Layer: Dark Theme (Trading Shell)
          const TradingShell(),
          
          // Top Layer: Light Theme (Fitness Shell) animated by a soft expanding/shrinking Radial ShaderMask
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
            // Excellent performance optimization here
            if (_animation.value == 0) return const SizedBox.shrink(); 

            return ShaderMask(
              shaderCallback: (Rect bounds) {
                // 1. Get screen dimensions
                final double width = bounds.width;
                final double height = bounds.height;
        
                // 2. RadialGradient radius of 1.0 is based on half the shortest side
                final double halfShortestSide = math.min(width, height) / 2;
        
                // 3. Exact distance from center to the farthest corner (Pythagoras)
                final double distanceToCorner = math.sqrt(
                  math.pow(width / 2, 2) + math.pow(height / 2, 2)
                );
        
                // 4. Calculate the perfect multiplier (usually around 2.2 on tall phones)
                final double maxRadiusMultiplier = distanceToCorner / halfShortestSide;

                return RadialGradient(
                  center: Alignment.center,
                  // Multiply animation (0.0 to 1.0) by the exact max radius needed
                  radius: _animation.value * maxRadiusMultiplier, 
                  colors: [
                    Colors.white, 
                    Colors.white.withOpacity(0.0) // Explicit 0.0 for safety
                  ],
                  stops: const [
                    0.6, // Solid center
                    1.0  // Soft fade to the edge
                  ],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: child,
            );
          },
          child: const FitnessShell(),
        ),

          // Edge-roll Toggle Switch
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            bottom: 40,
            right: _isToggleCollapsed ? -10 : 24, // Slides to the edge
            child: GestureDetector(
              onTap: _handleToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _isToggleCollapsed ? 50 : 140,
                height: 56,
                decoration: BoxDecoration(
                  color: mode == AppMode.fitness ? Colors.black : Colors.white,
                  borderRadius: _isToggleCollapsed 
                    ? const BorderRadius.horizontal(left: Radius.circular(28)) 
                    : BorderRadius.circular(28),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
                ),
                alignment: Alignment.centerLeft,
                padding: _isToggleCollapsed ? const EdgeInsets.only(left: 12) : const EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  child: Row(
                    children: [
                      Icon(
                        mode == AppMode.fitness ? Icons.candlestick_chart : Icons.directions_run,
                        color: mode == AppMode.fitness ? Colors.white : Colors.black,
                      ),
                      if (!_isToggleCollapsed) ...[
                        const SizedBox(width: 8),
                        Text(
                          mode == AppMode.fitness ? "TRADE" : "FITNESS",
                          style: TextStyle(
                            color: mode == AppMode.fitness ? Colors.white : Colors.black, 
                            fontWeight: FontWeight.bold, 
                            letterSpacing: 1.2
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
