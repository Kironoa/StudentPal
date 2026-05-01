import 'package:mobile_app/services/widget_update_service.dart';

class WidgetDataService {
  static final WidgetDataService _instance = WidgetDataService._internal();
  factory WidgetDataService() => _instance;
  WidgetDataService._internal();

  Future<void> refreshWidget({int? userId}) async {
    await WidgetUpdateService().refreshWidget(userId: userId);
  }
}
