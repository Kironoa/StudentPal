import 'package:flutter_riverpod/flutter_riverpod.dart';

final globalLoadingProvider = NotifierProvider<GlobalLoadingNotifier, bool>(
  GlobalLoadingNotifier.new,
);

class GlobalLoadingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void show() => state = true;
  void hide() => state = false;
}
