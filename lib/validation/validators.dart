import '../models/json_values.dart';
import '../models/normalizers.dart';

/// Общие проверки полей. Формы вызывают их из `validator`,
/// чтобы текст ошибки появился под конкретным полем.
abstract final class Validators {
  static String? requiredText(
    String? value, {
    required String emptyMessage,
    int max = 200,
    int min = 1,
  }) {
    final text = value?.trim() ?? '';
    if (text.length < min) {
      return emptyMessage;
    }
    if (text.length > max) {
      return 'Не длиннее $max символов';
    }
    return null;
  }

  static String? optionalText(String? value, {int max = 80}) {
    final text = value?.trim() ?? '';
    if (text.length > max) {
      return 'Не длиннее $max символов';
    }
    return null;
  }

  static String? intInRange(
    String? value, {
    required String label,
    required int min,
    required int max,
  }) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Укажите $label';
    }
    final number = int.tryParse(text);
    if (number == null) {
      return '$label — целое число';
    }
    if (number < min || number > max) {
      return '$label от $min до $max';
    }
    return null;
  }

  static String? isbn(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Укажите ISBN';
    }
    if (text.length > 20) {
      return 'ISBN не длиннее 20 символов';
    }
    if (!RegExp(r'^[0-9Xx\-\s]+$').hasMatch(text)) {
      return 'ISBN состоит из цифр и дефисов';
    }
    final digits = normalizeIsbn(text);
    if (digits.length < 10 || digits.length > 17) {
      return 'В ISBN должно быть от 10 до 17 цифр';
    }
    return null;
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Укажите почту';
    }
    if (text.length > 120) {
      return 'Почта не длиннее 120 символов';
    }
    final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!pattern.hasMatch(text)) {
      return 'Почта вида name@example.com';
    }
    return null;
  }

  static String? phone(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Укажите телефон';
    }
    if (text.length > 20) {
      return 'Телефон не длиннее 20 символов';
    }
    if (!RegExp(r'^[0-9+\-()\s]+$').hasMatch(text)) {
      return 'Телефон содержит только цифры и +-()';
    }
    final digits = text.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10 || digits.length > 15) {
      return 'В телефоне от 10 до 15 цифр';
    }
    return null;
  }

  static String? date(String? value, {required String label}) {
    if (parseDate(value) == null) {
      return '$label в формате ГГГГ-ММ-ДД';
    }
    return null;
  }

  static String? requiredId(int? value, String message) {
    if (value == null) {
      return message;
    }
    return null;
  }

  static String? nonEmptyIds(List<int>? value, String message) {
    if (value == null || value.isEmpty) {
      return message;
    }
    return null;
  }
}
