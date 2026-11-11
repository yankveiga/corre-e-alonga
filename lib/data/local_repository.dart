import 'dart:convert';
import 'package:drift/drift.dart';
import '../domain/repository.dart';
import '../domain/session.dart';
import '../domain/workout.dart';

// Drift gerencia conexão, parâmetros, transações e versão. SQL explícito evita
// geração para este pequeno esquema de documentos locais versionados.
class AppDatabase extends GeneratedDatabase {
  AppDatabase(super.executor);
  @override
  int get schemaVersion => 1;
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await customStatement(
        'CREATE TABLE documents (kind TEXT NOT NULL, id TEXT NOT NULL, body TEXT NOT NULL, PRIMARY KEY(kind, id))',
      );
    },
  );
}

class LocalRepository implements WorkoutRepository {
  final AppDatabase db;
  LocalRepository(this.db);
  Future<List<Map<String, dynamic>>> _read(String kind) async =>
      (await db
              .customSelect(
                'SELECT body FROM documents WHERE kind = ? ORDER BY id DESC',
                variables: [Variable.withString(kind)],
              )
              .get())
          .map(
            (row) =>
                jsonDecode(row.read<String>('body')) as Map<String, dynamic>,
          )
          .toList();
  Future<void> _put(String kind, String id, Map<String, dynamic> body) =>
      db.customStatement(
        'INSERT OR REPLACE INTO documents(kind,id,body) VALUES (?,?,?)',
        [kind, id, jsonEncode(body)],
      );
  @override
  Future<List<Workout>> workouts() async =>
      (await _read('workout')).map(Workout.fromJson).toList();
  @override
  Future<void> saveWorkout(Workout workout) =>
      _put('workout', workout.id, workout.toJson());
  @override
  Future<void> deleteWorkout(String id) => db.customStatement(
    'DELETE FROM documents WHERE kind = ? AND id = ?',
    ['workout', id],
  );
  @override
  Future<Preferences> preferences() async {
    final rows = await _read('preferences');
    return rows.isEmpty
        ? const Preferences()
        : Preferences.fromJson(rows.first);
  }

  @override
  Future<void> savePreferences(Preferences preferences) =>
      _put('preferences', 'user', preferences.toJson());
  @override
  Future<SessionCheckpoint?> checkpoint() async {
    final rows = await _read('checkpoint');
    if (rows.isEmpty) return null;
    final data = rows.first;
    if (data['pointCount'] case final int count) {
      final points = (await _read('routePoint')).reversed.toList();
      if (points.length != count) {
        throw StateError('Percurso incompleto no armazenamento');
      }
      data['points'] = points;
    }
    return SessionCheckpoint.fromJson(data);
  }

  @override
  Future<void> saveCheckpoint(
    SessionCheckpoint checkpoint,
  ) => db.transaction(() async {
    final previous = await _read('checkpoint');
    var count = previous.isNotEmpty && previous.first['id'] == checkpoint.id
        ? previous.first['pointCount'] as int? ?? -1
        : -1;
    if (count < 0 || count > checkpoint.points.length) {
      await db.customStatement('DELETE FROM documents WHERE kind = ?', [
        'routePoint',
      ]);
      count = 0;
    }
    // Só novos pontos são escritos. O tempo é pequeno e independente do tamanho da rota.
    for (var i = count; i < checkpoint.points.length; i++) {
      await _put(
        'routePoint',
        i.toString().padLeft(8, '0'),
        checkpoint.points[i].toJson(),
      );
    }
    await _put(
      'checkpoint',
      'active',
      checkpoint.toJson(includePoints: false)
        ..['pointCount'] = checkpoint.points.length,
    );
  });
  @override
  Future<void> finish(Activity activity) => db.transaction(() async {
    await _put('activity', activity.id, activity.toJson());
    await db.customStatement('DELETE FROM documents WHERE kind IN (?, ?)', [
      'checkpoint',
      'routePoint',
    ]);
  });
  @override
  Future<List<Activity>> activities() async =>
      (await _read('activity')).map(Activity.fromJson).toList()
        ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
  @override
  Future<void> close() => db.close();
}
