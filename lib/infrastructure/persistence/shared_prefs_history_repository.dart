import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/viewing_history.dart';
import '../../domain/ports/history_repository.dart';

/// Adaptateur : l'historique dans SharedPreferences (une liste d'identifiants vus, un JSON par jour).
class SharedPrefsHistoryRepository implements HistoryRepository {
  const SharedPrefsHistoryRepository(this._prefs);
  final SharedPreferences _prefs;

  static const _kWatched = 'watched';
  static const _kHistory = 'history';

  @override
  Future<ViewingHistory> load() async {
    final watched = _prefs.getStringList(_kWatched) ?? const [];
    final starts = <String, List<String>>{};
    final raw = _prefs.getString(_kHistory);
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        decoded.forEach((day, ids) => starts[day] = List<String>.from(ids as List));
      } on FormatException {
        // Historique illisible : on repart d'une semaine vide plutôt que de bloquer l'appli.
      }
    }
    return ViewingHistory(startsByDay: starts, watched: watched.toSet());
  }

  @override
  Future<void> save(ViewingHistory h) => Future.wait([
        _prefs.setStringList(_kWatched, h.watched.toList()..sort()),
        _prefs.setString(_kHistory, jsonEncode(h.startsByDay)),
      ]);

  @override
  Future<void> clear() => Future.wait([_prefs.remove(_kWatched), _prefs.remove(_kHistory)]);
}
