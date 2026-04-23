import 'dart:async';
import 'package:health/health.dart';
import 'api_service.dart';

class PedometerService {
  Timer? _syncTimer;
  int _lastSyncedSteps = -1;
  bool _isInitialized = false;
  
  // HealthFactory instance
  final Health _health = Health();

  Future<void> init(int initialBackendSteps) async {
    if (_isInitialized) return;
    _isInitialized = true;
    _lastSyncedSteps = initialBackendSteps;



    // Request permissions for HealthDataType.STEPS
    final types = [HealthDataType.STEPS];
    
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

    // Start 1-second polling timer
    _syncTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final now = DateTime.now();
      // Start of the day
      final startOfDay = DateTime(now.year, now.month, now.day);
      
      try {
        final stepsToday = await _health.getTotalStepsInInterval(startOfDay, now);
        
        if (stepsToday != null && stepsToday > 0) {
          // Typically Health Connect returns total steps for the day across all apps.
          // Since the user might have stepped BEFORE opening CampusExchange today,
          // we should be careful. To be safest with our logic, we will just sync 
          // the RAW steps today if it is greater than the _lastSyncedSteps we've pushed.
          if (stepsToday > _lastSyncedSteps) {
             _lastSyncedSteps = stepsToday;
             apiService.updateSteps(stepsToday);
          }
        }
      } catch (e) {
        print("Error fetching Health Connect steps: $e");
      }
    });
  }

  void dispose() {
    _syncTimer?.cancel();
    _isInitialized = false;
  }
}

final pedometerService = PedometerService();
