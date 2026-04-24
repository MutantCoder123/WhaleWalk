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
  const WalletData({
    this.campusCoins = 10000,
    this.orbs = 14,
    this.actualSteps = 0,
    this.availableSteps = 0,
    this.stats = const FitnessStats(),
    this.activeZone,
    this.userLat,
    this.userLng,
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
    for (var zone in liveZones) {
       double distance = Geolocator.distanceBetween(
           _currentPos!.latitude, _currentPos!.longitude,
           zone.latitude, zone.longitude);
       if (distance <= zone.radiusMeters) {
          newZone = zone.name;
          break;
       }
    }
    if (_activeZone != newZone) {
      _activeZone = newZone;
      state = state.copyWith(activeZone: newZone);
    }
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
      state = WalletData(
        campusCoins: (data['campusCoins'] ?? 0).toDouble(),
        actualSteps: (data['actualSteps'] ?? data['stepsCount'] ?? 0).toInt(),
        availableSteps:
            (data['availableSteps'] ?? data['stepsCount'] ?? 0).toInt(),
        orbs: (data['orbs'] ?? 14).toInt(),
        stats: FitnessStats(
          distanceKm: (data['distanceKm'] ?? 0).toDouble(),
          kcal: (data['kcal'] ?? 0).toDouble(),
          activeMin: (data['activeMin'] ?? 0).toInt(),
        ),
      );

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

          if (_activeZone != null) {
            int delta = actualSteps - _lastOrbFarmBaseline;
            if (delta >= 50) {
               _lastOrbFarmBaseline = actualSteps;
               apiService.farmOrbs(delta).then((res) {
                  state = state.copyWith(orbs: (res['newOrbs'] ?? state.orbs).toInt());
               }).catchError((e) => logApiError('farmOrbs', e));
            }
          } else {
            _lastOrbFarmBaseline = actualSteps;
          }
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
}

final walletProvider = StateNotifierProvider<WalletNotifier, WalletData>(
    (ref) => WalletNotifier(ref));

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

final challengesProvider =
    StateNotifierProvider<ChallengesNotifier, List<Challenge>>((ref) {
  return ChallengesNotifier();
});
