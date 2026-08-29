import 'package:flutter/foundation.dart';

enum BlackoutPhase {
  none,
  detecting,
  restoring,
  recovered,
}

class SyncStatus extends ChangeNotifier {
  static final SyncStatus instance = SyncStatus._();
  SyncStatus._();

  bool _online = true;
  bool _syncing = false;
  int _pending = 0;
  String? _lastError;

  BlackoutPhase _blackoutPhase = BlackoutPhase.none;
  int _recoveredCount = 0;
  String? _blackoutMessage;

  bool get isOnline => _online;
  bool get isSyncing => _syncing;
  int get pendingCount => _pending;
  String? get lastError => _lastError;

  BlackoutPhase get blackoutPhase => _blackoutPhase;
  int get recoveredCount => _recoveredCount;
  String? get blackoutMessage => _blackoutMessage;
  bool get isBlackoutActive => _blackoutPhase != BlackoutPhase.none;

  void setOnline(bool value) {
    if (_online == value) return;
    _online = value;
    notifyListeners();
  }

  void setSyncing(bool value) {
    if (_syncing == value) return;
    _syncing = value;
    notifyListeners();
  }

  void setPending(int count, {String? error}) {
    _pending = count;
    _lastError = error;
    notifyListeners();
  }

  void setBlackout({
    required BlackoutPhase phase,
    int recoveredCount = 0,
    String? message,
  }) {
    _blackoutPhase = phase;
    _recoveredCount = recoveredCount;
    _blackoutMessage = message;
    notifyListeners();
  }

  void clearBlackout() {
    if (_blackoutPhase == BlackoutPhase.none) return;
    _blackoutPhase = BlackoutPhase.none;
    _recoveredCount = 0;
    _blackoutMessage = null;
    notifyListeners();
  }
}
