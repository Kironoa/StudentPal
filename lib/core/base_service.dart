import 'package:flutter/foundation.dart';
import 'package:mobile_app/core/base_mixins.dart';


abstract class BaseService<T extends Identifiable> extends ChangeNotifier {
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
    final index = _items.indexWhere((e) => e.id == item.id);
    if (index != -1) {
      _items[index] = item;
      notifyListeners();
    }
  }

  void removeItem(int id) {
    _items = _items.where((e) => e.id != id).toList();
    notifyListeners();
  }
}