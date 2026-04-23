import 'dart:async';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'api_service.dart';

class PedometerService {
  StreamSubscription<StepCount>? _stepSubscription;
  Timer? _syncTimer;
  int _lastSyncedSteps = -1;
  int _currentSteps = -1;
  int _baselineSteps = -1;
  int _backendSteps = 0;
  bool _isInitialized = false;

  Future<void> init(int initialBackendSteps) async {
    if (_isInitialized) return;
    _isInitialized = true;
    _backendSteps = initialBackendSteps;
    _currentSteps = initialBackendSteps;
    _lastSyncedSteps = initialBackendSteps;
    
    if (await Permission.activityRecognition.request().isGranted) {
      _stepSubscription = Pedometer.stepCountStream.listen(_onStepCount, onError: _onStepCountError);
      
      _syncTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_currentSteps > 0 && _currentSteps != _lastSyncedSteps) {
           _lastSyncedSteps = _currentSteps;
           apiService.updateSteps(_currentSteps);
        }
      });
    } else {
      _isInitialized = false; // allow retry if denied
    }
  }

  void _onStepCount(StepCount event) {
    if (_baselineSteps == -1) {
      _baselineSteps = event.steps;
    }
    final sessionSteps = event.steps - _baselineSteps;
    _currentSteps = _backendSteps + sessionSteps;
  }

  void _onStepCountError(error) {
    print('Pedometer Error: $error');
  }

  void dispose() {
    _stepSubscription?.cancel();
    _syncTimer?.cancel();
    _isInitialized = false;
  }
}

final pedometerService = PedometerService();
