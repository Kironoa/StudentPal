import 'package:flutter/foundation.dart';

/// Abstract base service with ChangeNotifier for reactive state.
abstract class BaseService<T> extends ChangeNotifier {
  List<T> _items = [];
  bool _isLoading = false;
  String? _error;

  List<T> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void updateItems(List<T> items) {
    _items = items;
    notifyListeners();
  }

  void addItem(T item) {
    _items = [item, ..._items];
    notifyListeners();
  }

  void updateItem(T item) {
    final index = _items.indexWhere((e) => (e as dynamic).id == (item as dynamic).id);
    if (index != -1) {
      _items[index] = item;
      notifyListeners();
    }
  }

  void removeItem(int id) {
    _items = _items.where((e) => (e as dynamic).id != id).toList();
    notifyListeners();
  }
}