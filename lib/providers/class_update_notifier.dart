import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final classUpdateNotifierProvider = StreamProvider<int>((ref) {
  final controller = StreamController<int>.broadcast();
  void onUpdate() => controller.add(ClassUpdateProvider.instance.updateCount);
  ClassUpdateProvider.instance.addListener(onUpdate);
  ref.onDispose(() {
    ClassUpdateProvider.instance.removeListener(onUpdate);
    controller.close();
  });
  return controller.stream;
});

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