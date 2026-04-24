import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/pedometer_service.dart';
import 'package:geolocator/geolocator.dart';

// =============================================================================
// Zone Configuration
// =============================================================================
class ZoneConfig {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  const ZoneConfig({required this.id, required this.name, required this.latitude, required this.longitude, required this.radiusMeters});
}

class ZonesNotifier extends StateNotifier<List<ZoneConfig>> {
  ZonesNotifier() : super([]) {
    _fetchLive();
  }

  Future<void> _fetchLive() async {
    try {
       final data = await apiService.fetchZones();
       state = data.map<ZoneConfig>((j) => ZoneConfig(
           id: j['_id'] ?? '',
           name: j['name'] ?? 'Unknown',
           latitude: (j['latitude'] ?? 0.0).toDouble(),
           longitude: (j['longitude'] ?? 0.0).toDouble(),
           radiusMeters: (j['radiusMeters'] ?? 50.0).toDouble(),
       )).toList();
    } catch(e) {
       logApiError('ZonesNotifier', e);
    }
  }

  Future<void> refresh() => _fetchLive();
}

final zonesProvider = StateNotifierProvider<ZonesNotifier, List<ZoneConfig>>((ref) => ZonesNotifier());

// =============================================================================
// App Mode
// =============================================================================
enum AppMode { fitness, trading }

final appModeProvider = StateProvider<AppMode>((ref) => AppMode.fitness);

// Used by nav to open the drawer from child pages
final GlobalKey<ScaffoldState> mainScaffoldKey = GlobalKey<ScaffoldState>();

// =============================================================================
// Auth State
// =============================================================================
class AuthState {
  final String? username;
  final String? token;
  final bool isLoggedIn;
  const AuthState({this.username, this.token, this.isLoggedIn = false});
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _restore();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final username = prefs.getString('username');
    if (token != null && username != null) {
      state = AuthState(token: token, username: username, isLoggedIn: true);
    }
  }

  Future<void> login(String email, String password) async {
    final data = await apiService.login(email, password);
    state = AuthState(
      token: data['accessToken'],
      username: data['user']['username'],
      isLoggedIn: true,
    );
  }

  Future<void> register(
      String fullName, String email, String username, String password) async {
    await apiService.register(fullName, email, username, password);
    // Auto-login after register
    await login(email, password);
  }

  Future<void> logout() async {
    await apiService.logout();
    state = const AuthState();
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());

// =============================================================================
// Wallet / Coins / Steps / Orbs  (live from backend)
// =============================================================================
class FitnessStats {
  final double distanceKm;
  final double kcal;
  final int activeMin;
  const FitnessStats({
    this.distanceKm = 0.0,
    this.kcal = 0.0,
    this.activeMin = 0,
  });
}
class WalletData {
  final double campusCoins;
  final int orbs;
  final int actualSteps;
  final int availableSteps;
  final FitnessStats stats;
  final String? activeZone;
  final double? userLat;
  final double? userLng;
  final int stepsToNextOrb;
  final int stepsToNearestZone;
  final String? nearestZoneName;
  final int stepGoal;
  final double distanceGoal;

  const WalletData({
    this.campusCoins = 10000,
    this.orbs = 14,
    this.actualSteps = 0,
    this.availableSteps = 0,
    this.stats = const FitnessStats(),
    this.activeZone,
    this.userLat,
    this.userLng,
    this.stepsToNextOrb = 50,
    this.stepsToNearestZone = 0,
    this.nearestZoneName,
    this.stepGoal = 10000,
    this.distanceGoal = 8.0,
  });

  WalletData copyWith({
    double? campusCoins,
    int? actualSteps,
    int? availableSteps,
    int? orbs,
    FitnessStats? stats,
    String? activeZone,
    double? userLat,
    double? userLng,
    int? stepsToNextOrb,
    int? stepsToNearestZone,
    String? nearestZoneName,
    int? stepGoal,
    double? distanceGoal,
  }) =>
      WalletData(
        campusCoins: campusCoins ?? this.campusCoins,
        actualSteps: actualSteps ?? this.actualSteps,
        availableSteps: availableSteps ?? this.availableSteps,
        orbs: orbs ?? this.orbs,
        stats: stats ?? this.stats,
        activeZone: activeZone ?? this.activeZone,
        userLat: userLat ?? this.userLat,
        userLng: userLng ?? this.userLng,
        stepsToNextOrb: stepsToNextOrb ?? this.stepsToNextOrb,
        stepsToNearestZone: stepsToNearestZone ?? this.stepsToNearestZone,
        nearestZoneName: nearestZoneName ?? this.nearestZoneName,
        stepGoal: stepGoal ?? this.stepGoal,
        distanceGoal: distanceGoal ?? this.distanceGoal,
      );
}

class Transaction {
  final String title;
  final double amount;
  final bool isPositive;
  final DateTime createdAt;

  Transaction({
    required this.title,
    required this.amount,
    required this.isPositive,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      title: json['title'] ?? 'Unknown',
      amount: (json['amount'] ?? 0.0).toDouble(),
      isPositive: json['isPositive'] ?? true,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class WalletNotifier extends StateNotifier<WalletData> {
  final Ref ref;
  Timer? _pollingTimer;
  Position? _currentPos;
  String? _activeZone;
  int _lastOrbFarmBaseline = -1;

  WalletNotifier(this.ref) : super(const WalletData()) {
    _fetchLive();
    _startPolling();
    _initGeofence();
    
    // Listen to zone changes to re-evaluate geofencing immediately
    ref.listen(zonesProvider, (previous, next) {
      _evaluateZone();
    });
  }

  Future<void> _initGeofence() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return;

    Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5)
    ).listen((Position position) {
      _currentPos = position;
      state = state.copyWith(userLat: position.latitude, userLng: position.longitude);
      _evaluateZone();
    });
  }

  void _evaluateZone() {
    if (_currentPos == null) return;
    
    String? newZone;
    final liveZones = ref.read(zonesProvider);
    
    double minDistanceToBoundary = double.infinity;
    String? nearestZone;

    for (var zone in liveZones) {
       double distance = Geolocator.distanceBetween(
           _currentPos!.latitude, _currentPos!.longitude,
           zone.latitude, zone.longitude);
       
       double distanceToBoundary = distance - zone.radiusMeters;
       
       if (distance <= zone.radiusMeters) {
          newZone = zone.name;
          break;
       }

       if (distanceToBoundary < minDistanceToBoundary) {
         minDistanceToBoundary = distanceToBoundary;
         nearestZone = zone.name;
       }
    }

    if (_activeZone != newZone) {
      _activeZone = newZone;
      // Reset baseline when entering/leaving zone
      _lastOrbFarmBaseline = state.actualSteps;
    }

    int stepsToNextOrb = 50;
    if (_activeZone != null) {
      int progress = state.actualSteps - _lastOrbFarmBaseline;
      stepsToNextOrb = (50 - progress).clamp(0, 50);
    }

    int stepsToNearestZone = 0;
    if (newZone == null && nearestZone != null) {
       // 0.7 meters per step average
       stepsToNearestZone = (minDistanceToBoundary / 0.7).ceil();
    }

    state = state.copyWith(
      activeZone: newZone,
      stepsToNextOrb: stepsToNextOrb,
      stepsToNearestZone: stepsToNearestZone,
      nearestZoneName: nearestZone,
    );
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) => refresh());
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchLive() async {
    try {
      final data = await apiService.fetchWallet();
      state = state.copyWith(
        campusCoins: (data['campusCoins'] ?? 0).toDouble(),
        actualSteps: (data['actualSteps'] ?? data['stepsCount'] ?? 0).toInt(),
        availableSteps:
            (data['availableSteps'] ?? data['stepsCount'] ?? 0).toInt(),
        orbs: (data['orbs'] ?? 14).toInt(),
        stepGoal: (data['stepGoal'] ?? 10000).toInt(),
        distanceGoal: (data['distanceGoal'] ?? 8.0).toDouble(),
        stats: FitnessStats(
          distanceKm: (data['distanceKm'] ?? 0).toDouble(),
          kcal: (data['kcal'] ?? 0).toDouble(),
          activeMin: (data['activeMin'] ?? 0).toInt(),
        ),
      );
      
      // Also refresh history
      ref.invalidate(historyProvider);

      pedometerService.init(
        initialActualSteps: state.actualSteps,
        onStatsSynced: (actualSteps, availableSteps, distance, kcal, activeMin) {
          state = state.copyWith(
            actualSteps: actualSteps,
            availableSteps: availableSteps ?? state.availableSteps,
            stats: FitnessStats(distanceKm: distance, kcal: kcal, activeMin: activeMin),
          );

          if (_lastOrbFarmBaseline == -1) {
            _lastOrbFarmBaseline = actualSteps;
          }

          int stepsToNextOrb = 50;
          if (_activeZone != null) {
            int delta = actualSteps - _lastOrbFarmBaseline;
            stepsToNextOrb = (50 - delta).clamp(0, 50);

            if (delta >= 50) {
               _lastOrbFarmBaseline = actualSteps;
               stepsToNextOrb = 50;
               apiService.farmOrbs(delta).then((res) {
                  state = state.copyWith(orbs: (res['newOrbs'] ?? state.orbs).toInt());
               }).catchError((e) => logApiError('farmOrbs', e));
            }
          } else {
            _lastOrbFarmBaseline = actualSteps;
          }

          state = state.copyWith(
            actualSteps: actualSteps,
            availableSteps: availableSteps ?? state.availableSteps,
            stats: FitnessStats(distanceKm: distance, kcal: kcal, activeMin: activeMin),
            stepsToNextOrb: stepsToNextOrb,
          );
        },
      );
    } catch (e) {
      logApiError('WalletNotifier', e);
    }
  }

  Future<bool> convertSteps(int steps) async {
    try {
      final data = await apiService.convertSteps(steps);
      state = state.copyWith(
        campusCoins: (data['newCampusCoins'] ?? state.campusCoins).toDouble(),
        actualSteps: (data['newActualSteps'] ?? state.actualSteps).toInt(),
        availableSteps: (data['newAvailableSteps'] ??
                data['newStepsCount'] ??
                state.availableSteps)
            .toInt(),
      );
      return true;
    } catch (e) {
      logApiError('convertSteps', e);
      rethrow;
    }
  }

  Future<bool> convertOrbs(int orbs) async {
    try {
      final data = await apiService.convertOrbs(orbs);
      state = state.copyWith(
        campusCoins: (data['newCampusCoins'] ?? state.campusCoins).toDouble(),
        orbs: (data['newOrbs'] ?? state.orbs).toInt(),
      );
      return true;
    } catch (e) {
      logApiError('convertOrbs', e);
      rethrow;
    }
  }

  Future<void> refresh() => _fetchLive();

  Future<void> updateGoals({int? steps, double? distance}) async {
    try {
      final data = await apiService.updateFitnessGoals(stepGoal: steps, distanceGoal: distance);
      state = state.copyWith(
        stepGoal: (data['stepGoal'] ?? state.stepGoal).toInt(),
        distanceGoal: (data['distanceGoal'] ?? state.distanceGoal).toDouble(),
      );
    } catch (e) {
       logApiError('updateGoals', e);
    }
  }
}

final walletProvider = StateNotifierProvider<WalletNotifier, WalletData>(
    (ref) => WalletNotifier(ref));

final historyProvider = FutureProvider<List<dynamic>>((ref) async {
  return await apiService.fetchActivityHistory();
});

final transactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  final List<dynamic> response = await apiService.getTransactions();
  return response
      .map((t) => Transaction.fromJson(t as Map<String, dynamic>))
      .toList();
});

// Convenience providers that pages already reference
final currentCoinsProvider =
    Provider<double>((ref) => ref.watch(walletProvider).campusCoins);
final currentStepsProvider =
    Provider<int>((ref) => ref.watch(walletProvider).actualSteps);
final availableStepsProvider =
    Provider<int>((ref) => ref.watch(walletProvider).availableSteps);
final orbsProvider = Provider<int>((ref) => ref.watch(walletProvider).orbs);
final fitnessStatsProvider = Provider<FitnessStats>((ref) => ref.watch(walletProvider).stats);

// =============================================================================
// Stocks (Markets)
// =============================================================================
class Stock {
  final String name;
  final String symbol;
  final double currentPrice;
  final double previousPrice;
  final double percentageChange;
  final double lastDayPercentageChange;
  final bool isUp;
  final List<double> history;
  Stock(
      this.name,
      this.symbol,
      this.currentPrice,
      this.previousPrice,
      this.percentageChange,
      this.lastDayPercentageChange,
      this.isUp,
      this.history);
}

class MarketsNotifier extends StateNotifier<List<Stock>> {
  Timer? _pollingTimer;

  MarketsNotifier() : super([]) {
    _fetchLive();
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchLive());
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchLive() async {
    try {
      final liveData = await apiService.fetchStocks();
      state = liveData
          .map<Stock>((json) => Stock(
                json['name'] ?? 'Unknown',
                json['stockId'] ?? 'UNK',
                (json['price'] ?? 0.0).toDouble(),
                (json['previousPrice'] ?? 0.0).toDouble(),
                ((json['price'] ?? 1.0) - (json['previousPrice'] ?? 0.0)) /
                    ((json['previousPrice'] == 0 ? 1 : json['previousPrice'])) *
                    100,
                (json['lastDayPercentageChange'] ?? 0.0).toDouble(),
                (json['price'] ?? 0.0) >= (json['previousPrice'] ?? 0.0),
                (json['history'] as List?)
                        ?.map((e) {
                          if (e is Map<String, dynamic>) {
                            return (e['price'] as num).toDouble();
                          }
                          return (e as num).toDouble();
                        })
                        .toList() ??
                    [0.0],
              ))
          .toList();
    } catch (e) {
      logApiError('MarketsNotifier', e);
    }
  }

  Future<void> refresh() => _fetchLive();
}

final marketsProvider =
    StateNotifierProvider<MarketsNotifier, List<Stock>>((ref) {
  return MarketsNotifier();
});

// =============================================================================
// Portfolio (user's holdings)
// =============================================================================
class PortfolioHolding {
  final String stockId;
  final int quantity;
  final String name;
  final double currentPrice;
  final double previousPrice;
  final double avgPrice;
  const PortfolioHolding({
    required this.stockId,
    required this.quantity,
    required this.name,
    required this.currentPrice,
    required this.previousPrice,
    required this.avgPrice,
  });
}

class PortfolioNotifier extends StateNotifier<List<PortfolioHolding>> {
  PortfolioNotifier() : super([]) {
    _fetchLive();
  }

  Future<void> _fetchLive() async {
    try {
      // Portfolio gives [{stockId, quantity}]
      final portfolioData = await apiService.getPortfolio();
      // Stocks give current prices
      final stockData = await apiService.fetchStocks();

      final stockMap = <String, dynamic>{};
      for (final s in stockData) {
        stockMap[s['stockId']] = s;
      }

      state = portfolioData
          .where((p) => (p['quantity'] ?? 0) > 0)
          .map<PortfolioHolding>((p) {
        final stock = stockMap[p['stockId']];
        return PortfolioHolding(
          stockId: p['stockId'],
          quantity: (p['quantity'] ?? 0).toInt(),
          name: stock?['name'] ?? p['stockId'],
          currentPrice: (stock?['price'] ?? 0.0).toDouble(),
          previousPrice: (stock?['previousPrice'] ?? 0.0).toDouble(),
          avgPrice: (p['avgPrice'] ?? stock?['price'] ?? 0.0).toDouble(),
        );
      }).toList();
    } catch (e) {
      logApiError('PortfolioNotifier', e);
    }
  }

  Future<void> refresh() => _fetchLive();
}

final portfolioProvider =
    StateNotifierProvider<PortfolioNotifier, List<PortfolioHolding>>((ref) {
  return PortfolioNotifier();
});

// =============================================================================
// Orders (PROCESSING + COMPLETED tabs)
// =============================================================================
class StockOrder {
  final String stockId;
  final int quantity;
  final double limitPrice;
  final String type; // 'buy' | 'sell'
  final String status; // 'pending' | 'executed'
  final DateTime createdAt;
  const StockOrder({
    required this.stockId,
    required this.quantity,
    required this.limitPrice,
    required this.type,
    required this.status,
    required this.createdAt,
  });
}

class PendingOrdersNotifier extends StateNotifier<List<StockOrder>> {
  PendingOrdersNotifier() : super([]) {
    _fetchLive();
  }

  Future<void> _fetchLive() async {
    try {
      final data = await apiService.getMyOrders();
      state = data.map<StockOrder>(_fromJson).toList();
    } catch (e) {
      logApiError('PendingOrders', e);
    }
  }

  StockOrder _fromJson(dynamic j) => StockOrder(
        stockId: j['stockId'] ?? '',
        quantity: (j['quantity'] ?? 0).toInt(),
        limitPrice: (j['limitPrice'] ?? 0.0).toDouble(),
        type: j['type'] ?? 'buy',
        status: j['status'] ?? 'pending',
        createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
      );

  Future<void> refresh() => _fetchLive();
}

class CompletedOrdersNotifier extends StateNotifier<List<StockOrder>> {
  CompletedOrdersNotifier() : super([]) {
    _fetchLive();
  }

  Future<void> _fetchLive() async {
    try {
      final data = await apiService.getCompletedOrders();
      state = data.map<StockOrder>(_fromJson).toList();
    } catch (e) {
      logApiError('CompletedOrders', e);
    }
  }

  StockOrder _fromJson(dynamic j) => StockOrder(
        stockId: j['stockId'] ?? '',
        quantity: (j['quantity'] ?? 0).toInt(),
        limitPrice: (j['limitPrice'] ?? 0.0).toDouble(),
        type: j['type'] ?? 'buy',
        status: j['status'] ?? 'executed',
        createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
      );

  Future<void> refresh() => _fetchLive();
}

final pendingOrdersProvider =
    StateNotifierProvider<PendingOrdersNotifier, List<StockOrder>>((ref) {
  return PendingOrdersNotifier();
});

final completedOrdersProvider =
    StateNotifierProvider<CompletedOrdersNotifier, List<StockOrder>>((ref) {
  return CompletedOrdersNotifier();
});

// =============================================================================
// Challenges / Bets
// =============================================================================
class Challenge {
  final String betId;
  final String title;
  final String description;
  final String pool;
  final int participants;
  final String timeLeft;
  final bool isTrending;
  final String accentColor;
  final double yesPool;
  final double noPool;

  Challenge(
    this.betId,
    this.title,
    this.description,
    this.pool,
    this.participants,
    this.timeLeft,
    this.isTrending,
    this.accentColor,
    this.yesPool,
    this.noPool,
  );
}

class ChallengesNotifier extends StateNotifier<List<Challenge>> {
  ChallengesNotifier() : super([]) {
    _fetchLive();
  }

  Future<void> _fetchLive() async {
    try {
      final liveData = await apiService.fetchBets();
      state = liveData.map<Challenge>((json) {
        final rt =
            DateTime.tryParse(json['resultTime'] ?? '') ?? DateTime.now();
        final diff = rt.difference(DateTime.now());
        final timeLeft = diff.isNegative
            ? "Closed"
            : "${diff.inHours}h ${diff.inMinutes % 60}m";

        return Challenge(
          json['betId'] ?? '',
          json['question'] ?? 'Unknown',
          json['description'] ?? 'Active Challenge',
          "${json['totalPool'] ?? 0} CMX",
          json['totalEnrolled'] ?? 0,
          timeLeft,
          json['isTrending'] ?? false,
          json['accentColor'] ?? "orange",
          (json['yesPool'] ?? 0).toDouble(),
          (json['noPool'] ?? 0).toDouble(),
        );
      }).toList();
    } catch (e) {
      logApiError('ChallengesNotifier', e);
    }
  }

  Future<void> refresh() => _fetchLive();
}

final challengesProvider = StateNotifierProvider<ChallengesNotifier, List<Challenge>>((ref) {
  return ChallengesNotifier();
});

// ---------------------------------------------------------------------------
// Timed Challenges (Tasks like "Walk 10k steps")
// ---------------------------------------------------------------------------
class TaskChallenge {
  final String id;
  final String title;
  final String description;
  final String metric;
  final int targetValue;
  final int progress;
  final String duration;
  final int intensity;
  final int rewardCoins;
  final int rewardOrbs;
  final String status; // 'ACTIVE', 'COMPLETED', 'CLAIMED', 'EXPIRED'
  final DateTime expiresAt;

  TaskChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.metric,
    required this.targetValue,
    required this.progress,
    required this.duration,
    required this.intensity,
    required this.rewardCoins,
    required this.rewardOrbs,
    required this.status,
    required this.expiresAt,
  });
}

class TimedChallengesNotifier extends StateNotifier<List<TaskChallenge>> {
  TimedChallengesNotifier() : super([]) {
    _fetchLive();
  }

  Future<void> _fetchLive() async {
    try {
      final liveData = await apiService.fetchTimedChallenges();
      state = liveData.map<TaskChallenge>((json) {
        return TaskChallenge(
          id: json['id'] ?? '',
          title: json['title'] ?? 'Unknown',
          description: json['description'] ?? '',
          metric: json['metric'] ?? 'STEPS',
          targetValue: (json['targetValue'] ?? 0).toInt(),
          progress: (json['progress'] ?? 0).toInt(),
          duration: json['duration'] ?? 'DAILY',
          intensity: (json['intensity'] ?? 1).toInt(),
          rewardCoins: (json['rewardCoins'] ?? 0).toInt(),
          rewardOrbs: (json['rewardOrbs'] ?? 0).toInt(),
          status: json['status'] ?? 'ACTIVE',
          expiresAt: DateTime.tryParse(json['expiresAt'] ?? '') ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      logApiError('TimedChallengesNotifier', e);
    }
  }

  Future<void> claimReward(String challengeId) async {
    await apiService.claimChallengeReward(challengeId);
    await _fetchLive();
  }

  Future<void> refresh() => _fetchLive();
}

final timedChallengesProvider = StateNotifierProvider<TimedChallengesNotifier, List<TaskChallenge>>((ref) {
  return TimedChallengesNotifier();
});

// =============================================================================
// Inventory (user's owned items from store)
// =============================================================================
class InventoryItem {
  final String id;
  final String name;
  final String description;
  final String category; // 'badge', 'title', 'theme'
  final String? imageUrl;
  final String rarity; // 'common', 'uncommon', 'rare', 'epic', 'legendary', 'mythic'
  final bool isEquipped;

  const InventoryItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.imageUrl,
    this.rarity = 'common',
    this.isEquipped = false,
  });
}

class InventoryState {
  final List<InventoryItem> items;
  final bool isLoading;
  final String? error;

  const InventoryState({this.items = const [], this.isLoading = false, this.error});

  InventoryState copyWith({List<InventoryItem>? items, bool? isLoading, String? error}) =>
      InventoryState(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class InventoryNotifier extends StateNotifier<InventoryState> {
  InventoryNotifier() : super(const InventoryState()) {
    fetchInventory();
  }

  Future<void> fetchInventory() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final userData = await apiService.getUserInventory();

      final activeBadgeId = userData['activeBadge']?['_id']?.toString();
      final activeTitleId = userData['activeTitle']?['_id']?.toString();
      final inventoryList = userData['inventory'] as List? ?? [];

      final items = inventoryList.map<InventoryItem>((item) {
        final id = item['_id']?.toString() ?? '';
        final category = item['category'] ?? '';
        final isEquipped = (category == 'badge' && id == activeBadgeId) ||
            (category == 'title' && id == activeTitleId);

        return InventoryItem(
          id: id,
          name: item['name'] ?? 'Unknown',
          description: item['description'] ?? '',
          category: category,
          imageUrl: item['imageUrl'],
          rarity: item['rarity'] ?? 'common',
          isEquipped: isEquipped,
        );
      }).toList();

      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      logApiError('InventoryNotifier', e);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> equipItem(String itemId) async {
    try {
      await apiService.equipItem(itemId);
      await fetchInventory();
      return true;
    } catch (e) {
      logApiError('equipItem', e);
      rethrow;
    }
  }

  Future<void> refresh() => fetchInventory();
}

final inventoryProvider = StateNotifierProvider<InventoryNotifier, InventoryState>((ref) {
  return InventoryNotifier();
});

class StoreItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String? imageUrl;
  final String rarity;
  final bool isPurchasable;

  const StoreItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.imageUrl,
    this.rarity = 'common',
    this.isPurchasable = true,
  });
}

class StoreState {
  final List<StoreItem> items;
  final bool isLoading;
  final String? error;

  const StoreState({this.items = const [], this.isLoading = false, this.error});

  StoreState copyWith({List<StoreItem>? items, bool? isLoading, String? error}) =>
      StoreState(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class StoreNotifier extends StateNotifier<StoreState> {
  StoreNotifier() : super(const StoreState()) {
    fetchStore();
  }

  Future<void> fetchStore() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final itemsData = await apiService.getStoreItems();
      final items = itemsData.map<StoreItem>((item) {
        return StoreItem(
          id: item['_id']?.toString() ?? '',
          name: item['name'] ?? 'Unknown',
          description: item['description'] ?? '',
          price: (item['price'] ?? 0).toDouble(),
          category: item['category'] ?? 'badge',
          imageUrl: item['imageUrl'],
          rarity: item['rarity'] ?? 'common',
          isPurchasable: item['isPurchasable'] ?? true,
        );
      }).toList();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      logApiError('StoreNotifier', e);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> buyItem(String itemId) async {
    try {
      await apiService.buyStoreItem(itemId);
      await fetchStore();
    } catch (e) {
      logApiError('buyItem', e);
      rethrow;
    }
  }

  Future<void> refresh() => fetchStore();
}

final storeProvider = StateNotifierProvider<StoreNotifier, StoreState>((ref) {
  return StoreNotifier();
});

// =============================================================================
// Achievements
// =============================================================================
class AchievementData {
  final String id;
  final String title;
  final String description;
  final String metric;
  final int targetValue;
  final int rewardCoins;
  final int rewardOrbs;
  final bool isUnlocked;

  const AchievementData({
    required this.id,
    required this.title,
    required this.description,
    required this.metric,
    required this.targetValue,
    required this.rewardCoins,
    required this.rewardOrbs,
    required this.isUnlocked,
  });
}

class AchievementState {
  final List<AchievementData> achievements;
  final bool isLoading;

  const AchievementState({this.achievements = const [], this.isLoading = false});

  AchievementState copyWith({List<AchievementData>? achievements, bool? isLoading}) =>
      AchievementState(
        achievements: achievements ?? this.achievements,
        isLoading: isLoading ?? this.isLoading,
      );
}

class AchievementNotifier extends StateNotifier<AchievementState> {
  AchievementNotifier() : super(const AchievementState()) {
    fetchAchievements();
  }

  Future<void> fetchAchievements() async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await apiService.fetchAchievements();
      final list = data['achievements'] as List? ?? [];
      final achievements = list.map<AchievementData>((item) {
        return AchievementData(
          id: item['_id']?.toString() ?? '',
          title: item['title'] ?? 'Unknown',
          description: item['description'] ?? '',
          metric: item['metric'] ?? 'STEPS',
          targetValue: (item['targetValue'] ?? 0).toInt(),
          rewardCoins: (item['rewardCoins'] ?? 0).toInt(),
          rewardOrbs: (item['rewardOrbs'] ?? 0).toInt(),
          isUnlocked: item['isUnlocked'] ?? false,
        );
      }).toList();
      state = state.copyWith(achievements: achievements, isLoading: false);
    } catch (e) {
      logApiError('AchievementNotifier', e);
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refresh() => fetchAchievements();
}

final achievementProvider = StateNotifierProvider<AchievementNotifier, AchievementState>((ref) {
  return AchievementNotifier();
});
