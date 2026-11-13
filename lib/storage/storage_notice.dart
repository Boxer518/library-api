import 'package:flutter/foundation.dart';

/// Сообщение о смене формата или повреждённых данных в localStorage.
class StorageNotice extends ChangeNotifier {
  String? _message;

  String? get message => _message;

  void report(String message) {
    if (_message != null) {
      return;
    }
    _message = message;
    notifyListeners();
  }

  void dismiss() {
    if (_message == null) {
      return;
    }
    _message = null;
    notifyListeners();
  }
}
