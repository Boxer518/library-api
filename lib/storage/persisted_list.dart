import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'storage_keys.dart';
import 'storage_notice.dart';

/// Готовит localStorage до создания репозиториев.
/// Чужой номер версии или ключи без суффикса `_v1` не читаются.
Future<void> prepareStorage(
  SharedPreferences prefs,
  StorageNotice notice,
) async {
  final stored = prefs.getInt(schemaVersionKey);
  final legacy = legacyKeys.any(prefs.containsKey);
  if ((stored != null && stored != schemaVersion) ||
      (stored == null && legacy)) {
    for (final key in [...collectionKeys, ...legacyKeys]) {
      await prefs.remove(key);
    }
    notice.report(storageResetMessage);
  }
  await prefs.setInt(schemaVersionKey, schemaVersion);
}

class PersistedList<T> {
  PersistedList({
    required this.prefs,
    required this.key,
    required this.seed,
    required this.fromJson,
    required this.toJson,
    required this.notice,
  });

  final SharedPreferences prefs;
  final String key;
  final List<T> seed;
  final T Function(Map<String, dynamic> json) fromJson;
  final Map<String, dynamic> Function(T item) toJson;
  final StorageNotice notice;

  ({List<T> items, bool shouldPersist}) load() {
    final raw = prefs.getString(key);
    if (raw == null) {
      return (items: List<T>.of(seed), shouldPersist: true);
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        throw const FormatException('ожидался список');
      }
      final items = <T>[];
      for (final entry in decoded) {
        if (entry is! Map) {
          throw const FormatException('ожидался объект');
        }
        items.add(fromJson(Map<String, dynamic>.from(entry)));
      }
      return (items: items, shouldPersist: false);
    } catch (_) {
      notice.report(
        'Сохранённые данные повреждены. Каталог заменён начальным набором.',
      );
      return (items: List<T>.of(seed), shouldPersist: true);
    }
  }

  Future<void> save(List<T> items) async {
    await prefs.setString(
      key,
      jsonEncode([for (final item in items) toJson(item)]),
    );
  }
}
