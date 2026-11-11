import 'dart:async';
import 'package:corre_alonga/domain/location.dart';
import 'package:corre_alonga/domain/workout.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:corre_alonga/data/local_repository.dart';
import 'package:corre_alonga/domain/repository.dart';
import 'package:corre_alonga/domain/session.dart';
import 'package:corre_alonga/services/training_controller.dart';
import 'session_test.dart' show FakeClock, fixture;

class SilentAudio implements AudioService {
  @override
  Future<void> announce(String text, Preferences preferences) async {}
  @override
  Future<void> dispose() async {}
  @override
  Future<void> stop() async {}
}

void main() {
  test('criar, iniciar, pausar em background, recuperar e finalizar', () async {
    final repository = LocalRepository(AppDatabase(NativeDatabase.memory()));
    final clock = FakeClock();
    var controller = TrainingController(
      repository,
      SilentAudio(),
      clock: clock,
      automaticTicks: false,
    );
    await controller.initialize();
    await controller.saveWorkout(fixture());
    expect(await controller.start(fixture()), true);
    expect(await controller.start(fixture()), false);
    clock.advance(12);
    controller.tick();
    await controller.onBackground();
    clock.advance(100);
    expect(controller.session!.elapsed.inSeconds, 12);
    expect(controller.session!.status, SessionStatus.paused);
    controller.dispose();
    controller = TrainingController(
      repository,
      SilentAudio(),
      clock: clock,
      automaticTicks: false,
    );
    await controller.initialize();
    expect(controller.recovered, true);
    expect(controller.session!.elapsed.inSeconds, 12);
    await controller.resume();
    clock.advance(100);
    controller.tick();
    // A finalização é assíncrona e transacional.
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(controller.session, null);
    expect(controller.activities.single.completed, true);
    expect(await repository.checkpoint(), null);
    controller.dispose();
    await repository.close();
  });
  test(
    'falha de gravação impede início e permite repetir finalização',
    () async {
      final repo = FailingRepository();
      final controller = TrainingController(
        repo,
        SilentAudio(),
        automaticTicks: false,
      );
      await controller.initialize();
      expect(await controller.start(fixture()), false);
      expect(controller.session, null);
      expect(controller.error, contains('Não foi possível salvar'));
      repo.failCheckpoint = false;
      expect(await controller.start(fixture()), true);
      repo.failFinish = true;
      expect(await controller.finish(), false);
      expect(controller.session, isNotNull);
      repo.failFinish = false;
      expect(await controller.finish(), true);
      expect((await repo.activities()).length, 1);
      controller.dispose();
      await repo.close();
    },
  );
  test(
    'permissão negada mantém sessão e GPS pode ser ativado e pausado',
    () async {
      final repo = LocalRepository(AppDatabase(NativeDatabase.memory()));
      final gps = FakeLocation();
      final controller = TrainingController(
        repo,
        SilentAudio(),
        location: gps,
        automaticTicks: false,
      );
      await controller.initialize();
      await controller.start(fixture());
      await controller.enableGps();
      expect(controller.gpsEnabled, false);
      expect(controller.session!.status, SessionStatus.running);
      gps.denied = false;
      await controller.enableGps();
      final now = DateTime.now();
      gps.stream.add(
        TrackPoint(0, 0, 5, now.subtract(const Duration(seconds: 5))),
      );
      gps.stream.add(TrackPoint(0, .0001, 5, now));
      await Future<void>.delayed(Duration.zero);
      expect(controller.route.meters, greaterThan(10));
      await controller.pause();
      gps.stream.add(
        TrackPoint(0, .0002, 5, now.add(const Duration(seconds: 1))),
      );
      await Future<void>.delayed(Duration.zero);
      expect(controller.route.points.length, 2);
      await controller.finish();
      expect((await repo.activities()).single.meters, greaterThan(10));
      controller.dispose();
      await gps.stream.close();
      await repo.close();
    },
  );
  test(
    'fases curtas substituem voz anterior sem perder o alerta novo',
    () async {
      final repo = LocalRepository(AppDatabase(NativeDatabase.memory()));
      final clock = FakeClock();
      final audio = HoldingAudio();
      final controller = TrainingController(
        repo,
        audio,
        clock: clock,
        automaticTicks: false,
      );
      await controller.initialize();
      await controller.start(
        Workout(
          id: 'short',
          name: 'Curto',
          warmupSeconds: 0,
          runSeconds: 1,
          recoverySeconds: 1,
          cooldownSeconds: 0,
          repeats: 2,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      clock.advance(1);
      controller.tick();
      await Future<void>.delayed(Duration.zero);
      clock.advance(1);
      controller.tick();
      await Future<void>.delayed(Duration.zero);
      expect(audio.spoken, ['Corrida', 'Recuperação', 'Corrida']);
      await controller.pause();
      controller.dispose();
      await repo.close();
    },
  );
  test('falha de áudio não impede o temporizador', () async {
    final repo = LocalRepository(AppDatabase(NativeDatabase.memory()));
    final clock = FakeClock();
    final controller = TrainingController(
      repo,
      BrokenAudio(),
      clock: clock,
      automaticTicks: false,
    );
    await controller.initialize();
    await controller.start(fixture());
    await Future<void>.delayed(Duration.zero);
    expect(controller.error, contains('Áudio indisponível'));
    clock.advance(11);
    controller.tick();
    expect(controller.session!.phase.kind.name, 'run');
    await controller.pause();
    controller.dispose();
    await repo.close();
  });
}

class BrokenAudio extends SilentAudio {
  @override
  Future<void> announce(String text, Preferences preferences) async =>
      throw StateError('indisponível');
}

class FailingRepository extends LocalRepository {
  bool failCheckpoint = true, failFinish = false;
  FailingRepository() : super(AppDatabase(NativeDatabase.memory()));
  @override
  Future<void> saveCheckpoint(SessionCheckpoint checkpoint) async {
    if (failCheckpoint) throw StateError('disk full');
    await super.saveCheckpoint(checkpoint);
  }

  @override
  Future<void> finish(Activity activity) async {
    if (failFinish) throw StateError('disk full');
    await super.finish(activity);
  }
}

class FakeLocation implements LocationService {
  bool denied = true;
  final stream = StreamController<TrackPoint>.broadcast();
  @override
  Future<void> requestAccess() async {
    if (denied) throw StateError('Permissão negada');
  }

  @override
  Stream<TrackPoint> positions() => stream.stream;
}

class HoldingAudio extends SilentAudio {
  final spoken = <String>[];
  Completer<void>? pending;
  @override
  Future<void> announce(String text, Preferences preferences) {
    spoken.add(text);
    pending = Completer<void>();
    return pending!.future;
  }

  @override
  Future<void> stop() async {
    if (pending != null && !pending!.isCompleted) pending!.complete();
  }
}
