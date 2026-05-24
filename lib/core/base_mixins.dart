
mixin Identifiable {
  int? get id;
}

mixin DateParserMixin {
  DateTime? parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    return DateTime.tryParse(dateStr);
  }

  String formatDate(DateTime? date) {
    if (date == null) return '';
    return date.toIso8601String();
  }

  bool isOverdue(String? deadline) {
    final date = parseDate(deadline);
    if (date == null) return false;
    return date.isBefore(DateTime.now());
  }

  bool isDueToday(String? deadline) {
    final date = parseDate(deadline);
    if (date == null) return false;
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

mixin ValidationMixin {
  String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  String? validateMinLength(String? value, int minLength, String fieldName) {
    if (value == null || value.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Invalid email format';
    }
    return null;
  }
}