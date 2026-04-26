import 'package:flutter/foundation.dart';

/// ChangeNotifier for class list update notifications.
class ClassUpdateNotifier extends ChangeNotifier {
  bool _shouldRefresh = false;
  int _updateCount = 0;

  bool get shouldRefresh => _shouldRefresh;
  int get updateCount => _updateCount;

  void triggerUpdate() {
    _shouldRefresh = true;
    _updateCount++;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 100), () {
      _shouldRefresh = false;
    });
  }

  void resetUpdate() {
    _shouldRefresh = false;
    notifyListeners();
  }
}

class ClassUpdateProvider {
  static final ClassUpdateNotifier instance = ClassUpdateNotifier();
  ClassUpdateProvider._();
}

extension ClassUpdateNotifierExtension on ClassUpdateNotifier {
  void notifyClassUpdate() => triggerUpdate();
}