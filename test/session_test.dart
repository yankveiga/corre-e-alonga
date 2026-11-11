import 'package:flutter_test/flutter_test.dart';
import 'package:corre_alonga/domain/session.dart';
import 'package:corre_alonga/domain/workout.dart';

class FakeClock implements MonotonicClock {
  @override
  Duration elapsed = Duration.zero;
  void advance(int seconds) => elapsed += Duration(seconds: seconds);
}

Workout fixture() => Workout(
  id: 'one',
  name: 'Intervalado',
  warmupSeconds: 10,
  runSeconds: 20,
  recoverySeconds: 5,
  cooldownSeconds: 10,
  repeats: 2,
);

void main() {
  test('ordem de fases e recuperação somente entre corridas', () {
    final workout = fixture();
    expect(workout.total, const Duration(seconds: 65));
    expect(workout.phases.map((p) => p.kind), [
      PhaseKind.warmup,
      PhaseKind.run,
      PhaseKind.recovery,
      PhaseKind.run,
      PhaseKind.cooldown,
    ]);
    expect(workout.phases[3].repetition, 2);
  });
  test('limites exatos e atraso de atualização não acumulam desvio', () {
    final clock = FakeClock();
    final engine = SessionEngine(fixture(), clock)..resume();
    clock.advance(10);
    expect(engine.phase.kind, PhaseKind.run);
    expect(engine.remaining, const Duration(seconds: 20));
    clock.advance(29); // sem ticks: pula diretamente à segunda corrida.
    expect(engine.phaseIndex, 3);
    expect(engine.remaining, const Duration(seconds: 16));
    clock.advance(1000);
    engine.synchronize();
    expect(engine.elapsed, fixture().total);
    expect(engine.status, SessionStatus.completed);
    expect(engine.remaining, Duration.zero);
  });
  test('pausa e retomada ignoram tempo passado em pausa', () {
    final clock = FakeClock();
    final engine = SessionEngine(fixture(), clock)..resume();
    clock.advance(7);
    engine.pause();
    clock.advance(10000);
    expect(engine.elapsed, const Duration(seconds: 7));
    engine.resume();
    clock.advance(3);
    expect(engine.phase.kind, PhaseKind.run);
  });
  test('checkpoint restaura pausado sem depender da hora de parede', () {
    final checkpoint = SessionCheckpoint(
      's',
      fixture(),
      31000,
      DateTime.utc(2026),
    );
    final restored = SessionCheckpoint.fromJson(checkpoint.toJson());
    final clock = FakeClock()..advance(1000000);
    final engine = SessionEngine(
      restored.workout,
      clock,
      elapsed: Duration(milliseconds: restored.elapsedMs),
    );
    expect(engine.status, SessionStatus.paused);
    expect(engine.phase.kind, PhaseKind.recovery);
    engine.resume();
    clock.advance(4);
    expect(engine.phase.kind, PhaseKind.run);
  });
  test('valida duração, repetições e nome', () {
    expect(() => Workout(id: 'a', name: ' ', repeats: 0), throwsArgumentError);
    expect(
      () => Workout(id: 'a', name: 'a', runSeconds: 0),
      throwsArgumentError,
    );
    expect(
      () => Workout(id: 'a', name: 'a', recoverySeconds: -1),
      throwsArgumentError,
    );
    expect(
      () => SessionEngine(
        fixture(),
        FakeClock(),
        elapsed: const Duration(days: 1),
      ),
      throwsArgumentError,
    );
  });
  test('fases opcionais e término idempotente', () {
    final workout = Workout(
      id: 'a',
      name: 'a',
      warmupSeconds: 0,
      cooldownSeconds: 0,
      recoverySeconds: 0,
      repeats: 1,
    );
    final engine = SessionEngine(workout, FakeClock())
      ..resume()
      ..stop()
      ..resume();
    expect(workout.phases.length, 1);
    expect(engine.status, SessionStatus.stopped);
    expect(clockText(const Duration(milliseconds: 1001)), '00:02');
  });
}
