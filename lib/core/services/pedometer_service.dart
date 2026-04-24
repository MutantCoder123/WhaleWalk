import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:health/health.dart';
import 'api_service.dart';

class PedometerService with WidgetsBindingObserver {
  Timer? _syncTimer;
  int _lastSyncedSteps = -1;
  bool _isInitialized = false;
  bool _isSyncInProgress = false;
  bool _isAppInForeground = true;

  // HealthFactory instance
  final Health _health = Health();

  Future<void> init({
    required int initialActualSteps,
    required void Function(int actualSteps, int? availableSteps, double distance, double kcal, int activeMin) onStatsSynced,
  }) async {
    if (kIsWeb || !Platform.isAndroid) {
      print("PedometerService: Health Connect is only supported on Android.");
      return;
    }
    if (_isInitialized) return;
    _isInitialized = true;
    _lastSyncedSteps = initialActualSteps;
    _isAppInForeground = true;
    WidgetsBinding.instance.addObserver(this);

    // Request permissions for extended health trackers
    final types = [
      HealthDataType.STEPS,
      HealthDataType.DISTANCE_DELTA,
    ];

    // First, check if we have permissions
    bool? hasPermissions = await _health.hasPermissions(types);
    if (hasPermissions != true) {
      // Request permission
      bool authorized = await _health.requestAuthorization(types);
      if (!authorized) {
        _isInitialized = false;
        print("Health Connect authorization denied");
        return;
      }
    }

    // Poll Health Connect periodically and keep the UI in sync.
    _syncTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (_isSyncInProgress || !_isAppInForeground) return;
      final now = DateTime.now();
      // Start of the day
      final startOfDay = DateTime(now.year, now.month, now.day);

      try {
        _isSyncInProgress = true;
        final stepsToday =
            await _health.getTotalStepsInInterval(startOfDay, now);

        if (stepsToday != null && stepsToday >= 0) {
          double distanceKm = 0.0;
          double kcal = 0.0;
          int activeMin = 0;
          
              try {
             List<HealthDataPoint> healthData = await _health.getHealthDataFromTypes(
               types: [
                 HealthDataType.DISTANCE_DELTA,
               ],
               startTime: startOfDay,
               endTime: now,
             );
             
             for (var dataPoint in healthData) {
               final value = dataPoint.value;
               if (value is NumericHealthValue) {
                 final numVal = value.numericValue.toDouble();
                 if (dataPoint.type == HealthDataType.DISTANCE_DELTA) {
                   distanceKm += numVal / 1000.0;
                 }
               }
             }
             
             // Since EXERCISE_TIME is not supported on all devices natively, 
             // we calculate active moving time mathematically across the day.
             // Average walking pace is ~100 steps per minute.
             activeMin = (stepsToday / 100).floor();

             // Calculate Kcal algorithmically (roughly 0.04 - 0.05 kcal per step)
             kcal = stepsToday * 0.04;
             
          } catch (e) {
             print("Could not fetch extended health metrics: $e");
          }

          if (stepsToday != _lastSyncedSteps) {
            final synced = await apiService.updateSteps(
              stepsToday,
              distanceKm: distanceKm,
              kcal: kcal,
              activeMin: activeMin,
            );
            final actualSteps =
                ((synced['actualSteps'] ?? stepsToday) as num).toInt();
            final availableSteps =
                ((synced['availableSteps'] ?? synced['stepsCount'] ?? 0) as num)
                    .toInt();
            _lastSyncedSteps = actualSteps;
            onStatsSynced(actualSteps, availableSteps, distanceKm, kcal, activeMin);
          } else {
            // Even if steps didn't change, metrics might have
            onStatsSynced(_lastSyncedSteps, null, distanceKm, kcal, activeMin);
          }
        }
      } catch (e) {
        print("Error fetching Health Connect steps: $e");
      } finally {
        _isSyncInProgress = false;
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isAppInForeground = true;
    } else {
      _isAppInForeground = false;
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _syncTimer?.cancel();
    _isInitialized = false;
  }
}

final pedometerService = PedometerService();
