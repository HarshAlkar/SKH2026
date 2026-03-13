import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  // Stream controller to broadcast boolean states easily
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();
  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  bool _isOnline = false;
  bool get isOnline => _isOnline;

  ConnectivityService() {
    _initialize();
  }

  Future<void> _initialize() async {
    // Check initial connection status
    List<ConnectivityResult> results = await _connectivity.checkConnectivity();
    _updateStatus(results);

    // Subscribe to ongoing changes
    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.mobile) ||
        results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.ethernet)) {
      _isOnline = true;
    } else {
      _isOnline = false;
    }

    _connectionStatusController.add(_isOnline);
  }

  void dispose() {
    _subscription?.cancel();
    _connectionStatusController.close();
  }
}
