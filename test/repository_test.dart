import 'dart:io';
import 'dart:convert';
import 'package:corre_alonga/domain/location.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:corre_alonga/data/local_repository.dart';
import 'package:corre_alonga/domain/repository.dart';
import 'package:corre_alonga/domain/session.dart';
import 'session_test.dart' show fixture;

void main() {
  test(
    'SQLite reabre treinos, preferências e checkpoint após reinício',
    () async {
      final dir = await Directory.systemTemp.createTemp('corre-test-');
      final file = File('${dir.path}/app.sqlite');
      var repo = LocalRepository(AppDatabase(NativeDatabase(file)));
      await repo.saveWorkout(fixture());
      await repo.savePreferences(
        const Preferences(voice: false, theme: 'dark'),
      );
      await repo.saveCheckpoint(
        SessionCheckpoint('session', fixture(), 5000, DateTime.utc(2026)),
      );
      await repo.close();
      repo = LocalRepository(AppDatabase(NativeDatabase(file)));
      expect((await repo.workouts()).single.total, fixture().total);
      expect((await repo.preferences()).voice, false);
      expect((await repo.checkpoint())!.elapsedMs, 5000);
      final activity = Activity(
        id: 'session',
        name: fixture().name,
        elapsedMs: 5000,
        startedAt: DateTime.utc(2026),
        completed: false,
      );
      await repo.finish(activity);
      await repo.finish(activity);
      expect(await repo.checkpoint(), null);
      expect((await repo.activities()).length, 1);
      await repo.deleteWorkout(fixture().id);
      expect(await repo.workouts(), isEmpty);
      expect((await repo.activities()).length, 1);
      await repo.close();
      await dir.delete(recursive: true);
    },
  );
  test(
    'checkpoint incremental preserva ordem, evita regravar pontos e limpa ao encerrar',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      final repo = LocalRepository(db);
      final now = DateTime.utc(2026);
      final points = [
        for (var i = 0; i < 12; i++)
          TrackPoint(
            0,
            i * .0001,
            5,
            now.add(Duration(seconds: i * 5)),
            segmentStart: i == 0,
          ),
      ];
      await repo.saveCheckpoint(
        SessionCheckpoint(
          's',
          fixture(),
          1000,
          now,
          points: points.take(10).toList(),
          meters: 100,
        ),
      );
      await db.customStatement(
        "CREATE TRIGGER immutable_points BEFORE INSERT ON documents WHEN NEW.kind = 'routePoint' AND EXISTS (SELECT 1 FROM documents WHERE kind = 'routePoint' AND id = NEW.id) BEGIN SELECT RAISE(ABORT, 'Point rewritten'); END",
      );
      await repo.saveCheckpoint(
        SessionCheckpoint(
          's',
          fixture(),
          2000,
          now,
          points: points,
          meters: 120,
        ),
      );
      await repo.saveCheckpoint(
        SessionCheckpoint(
          's',
          fixture(),
          3000,
          now,
          points: points,
          meters: 120,
        ),
      );
      final cp = (await repo.checkpoint())!;
      expect(cp.elapsedMs, 3000);
      expect(cp.points.map((p) => p.longitude), points.map((p) => p.longitude));
      final stored = await db
          .customSelect("SELECT body FROM documents WHERE kind = 'checkpoint'")
          .getSingle();
      expect(
        jsonDecode(stored.read<String>('body')),
        isNot(contains('points')),
      );
      await repo.finish(
        Activity(
          id: 's',
          name: 's',
          elapsedMs: 3000,
          startedAt: now,
          completed: false,
          points: points,
          meters: 120,
        ),
      );
      expect((await repo.activities()).single.points.length, 12);
      expect(
        await db
            .customSelect("SELECT * FROM documents WHERE kind = 'routePoint'")
            .get(),
        isEmpty,
      );
      await repo.close();
    },
  );
  test(
    'checkpoint antigo com percurso completo é lido e convertido sem perda',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      final repo = LocalRepository(db);
      final now = DateTime.utc(2026);
      final original = SessionCheckpoint(
        'legacy',
        fixture(),
        1000,
        now,
        points: [TrackPoint(0, 0, 5, now)],
        meters: 0,
      );
      await db.customStatement(
        "INSERT INTO documents VALUES ('checkpoint','active',?)",
        [jsonEncode(original.toJson())],
      );
      expect((await repo.checkpoint())!.points.length, 1);
      await repo.saveCheckpoint(original);
      expect((await repo.checkpoint())!.points.length, 1);
      await repo.close();
    },
  );
  test(
    'falha no checkpoint desfaz também pontos anexados na mesma transação',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      final repo = LocalRepository(db);
      final now = DateTime.utc(2026);
      final first = TrackPoint(0, 0, 5, now);
      await repo.saveCheckpoint(
        SessionCheckpoint('s', fixture(), 1000, now, points: [first]),
      );
      await db.customStatement(
        "CREATE TRIGGER fail_progress BEFORE INSERT ON documents WHEN NEW.kind = 'checkpoint' BEGIN SELECT RAISE(ABORT, 'Disk write failed'); END",
      );
      await expectLater(
        repo.saveCheckpoint(
          SessionCheckpoint(
            's',
            fixture(),
            2000,
            now,
            points: [
              first,
              TrackPoint(0, .0001, 5, now.add(const Duration(seconds: 5))),
            ],
          ),
        ),
        throwsA(isA<Exception>()),
      );
      final recovered = (await repo.checkpoint())!;
      expect(recovered.elapsedMs, 1000);
      expect(recovered.points.length, 1);
      await repo.close();
    },
  );
}
