import 'workout.dart';
import 'location.dart';

abstract interface class MonotonicClock {
  Duration get elapsed;
}

class StopwatchClock implements MonotonicClock {
  final Stopwatch _watch = Stopwatch()..start();
  @override
  Duration get elapsed => _watch.elapsed;
}

enum SessionStatus { running, paused, completed, stopped }

class SessionEngine {
  final Workout workout;
  final MonotonicClock clock;
  Duration _accumulated;
  Duration? _anchor;
  SessionStatus status = SessionStatus.paused;
  SessionEngine(this.workout, this.clock, {Duration elapsed = Duration.zero})
    : _accumulated = elapsed {
    if (elapsed < Duration.zero || elapsed > workout.total) {
      throw ArgumentError('Tempo inválido');
    }
    if (elapsed == workout.total) status = SessionStatus.completed;
  }
  Duration get elapsed {
    final value =
        _accumulated +
        (_anchor == null ? Duration.zero : clock.elapsed - _anchor!);
    return value > workout.total ? workout.total : value;
  }

  bool get terminal =>
      status == SessionStatus.completed || status == SessionStatus.stopped;
  int get phaseIndex {
    var end = Duration.zero;
    for (var i = 0; i < workout.phases.length; i++) {
      end += workout.phases[i].duration;
      if (elapsed < end) return i;
    }
    return workout.phases.length - 1;
  }

  WorkoutPhase get phase => workout.phases[phaseIndex];
  Duration get remaining {
    if (elapsed >= workout.total) return Duration.zero;
    final end = workout.phases
        .take(phaseIndex + 1)
        .fold(Duration.zero, (sum, p) => sum + p.duration);
    return end - elapsed;
  }

  void resume() {
    if (status != SessionStatus.paused) return;
    _anchor = clock.elapsed;
    status = SessionStatus.running;
  }

  void synchronize() {
    if (status == SessionStatus.running && elapsed >= workout.total) {
      _accumulated = workout.total;
      _anchor = null;
      status = SessionStatus.completed;
    }
  }

  void pause() {
    synchronize();
    if (status != SessionStatus.running) return;
    _accumulated = elapsed;
    _anchor = null;
    status = SessionStatus.paused;
  }

  void stop() {
    pause();
    if (!terminal) status = SessionStatus.stopped;
  }
}

class SessionCheckpoint {
  final String id;
  final Workout workout;
  final int elapsedMs;
  final DateTime startedAt;
  final List<TrackPoint> points;
  final double meters;
  const SessionCheckpoint(
    this.id,
    this.workout,
    this.elapsedMs,
    this.startedAt, {
    this.points = const [],
    this.meters = 0,
  });
  Map<String, dynamic> toJson({bool includePoints = true}) => {
    'id': id,
    'workout': workout.toJson(),
    'elapsedMs': elapsedMs,
    'startedAt': startedAt.toUtc().toIso8601String(),
    if (includePoints) 'points': points.map((p) => p.toJson()).toList(),
    'meters': meters,
  };
  factory SessionCheckpoint.fromJson(Map<String, dynamic> json) =>
      SessionCheckpoint(
        json['id'] as String,
        Workout.fromJson(json['workout'] as Map<String, dynamic>),
        json['elapsedMs'] as int,
        DateTime.parse(json['startedAt'] as String),
        points: (json['points'] as List? ?? [])
            .map((p) => TrackPoint.fromJson(p as Map<String, dynamic>))
            .toList(),
        meters: (json['meters'] as num?)?.toDouble() ?? 0,
      );
}

class Activity {
  final String id, name;
  final int elapsedMs;
  final DateTime startedAt;
  final List<TrackPoint> points;
  final double meters;
  final bool completed;
  const Activity({
    required this.id,
    required this.name,
    required this.elapsedMs,
    required this.startedAt,
    required this.completed,
    this.points = const [],
    this.meters = 0,
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'elapsedMs': elapsedMs,
    'startedAt': startedAt.toUtc().toIso8601String(),
    'points': points.map((p) => p.toJson()).toList(),
    'meters': meters,
    'completed': completed,
  };
  factory Activity.fromJson(Map<String, dynamic> json) => Activity(
    id: json['id'] as String,
    name: json['name'] as String,
    elapsedMs: json['elapsedMs'] as int,
    startedAt: DateTime.parse(json['startedAt'] as String),
    completed: json['completed'] as bool,
    points: (json['points'] as List? ?? [])
        .map((p) => TrackPoint.fromJson(p as Map<String, dynamic>))
        .toList(),
    meters: (json['meters'] as num?)?.toDouble() ?? 0,
  );
}
