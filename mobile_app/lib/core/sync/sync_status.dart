import 'package:flutter/foundation.dart';

class SyncStatus extends ChangeNotifier {
  static final SyncStatus instance = SyncStatus._();
  SyncStatus._();

  bool _online = true;
  bool _syncing = false;
  int _pending = 0;
  String? _lastError;

  bool get isOnline => _online;
  bool get isSyncing => _syncing;
  int get pendingCount => _pending;
  String? get lastError => _lastError;

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
}
