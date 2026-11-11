enum PhaseKind { warmup, run, recovery, cooldown }

extension PhaseLabel on PhaseKind {
  String get label => switch (this) {
    PhaseKind.warmup => 'Aquecimento',
    PhaseKind.run => 'Corrida',
    PhaseKind.recovery => 'Recuperação',
    PhaseKind.cooldown => 'Desaquecimento',
  };
}

class WorkoutPhase {
  final PhaseKind kind;
  final Duration duration;
  final int? repetition;
  const WorkoutPhase(this.kind, this.duration, [this.repetition]);
}

class Workout {
  final String id;
  final String name;
  final int warmupSeconds,
      runSeconds,
      recoverySeconds,
      cooldownSeconds,
      repeats;
  Workout({
    required this.id,
    required this.name,
    this.warmupSeconds = 300,
    this.runSeconds = 60,
    this.recoverySeconds = 90,
    this.cooldownSeconds = 300,
    this.repeats = 8,
  }) {
    if (name.trim().isEmpty ||
        name.length > 80 ||
        runSeconds < 1 ||
        repeats < 1 ||
        repeats > 100 ||
        warmupSeconds < 0 ||
        recoverySeconds < 0 ||
        cooldownSeconds < 0 ||
        [
          warmupSeconds,
          runSeconds,
          recoverySeconds,
          cooldownSeconds,
        ].any((v) => v > 3600)) {
      throw ArgumentError('Treino inválido');
    }
  }
  List<WorkoutPhase> get phases => [
    if (warmupSeconds > 0)
      WorkoutPhase(PhaseKind.warmup, Duration(seconds: warmupSeconds)),
    for (var i = 1; i <= repeats; i++) ...[
      WorkoutPhase(PhaseKind.run, Duration(seconds: runSeconds), i),
      // Recuperação somente entre corridas; a última leva ao desaquecimento.
      if (i < repeats && recoverySeconds > 0)
        WorkoutPhase(PhaseKind.recovery, Duration(seconds: recoverySeconds), i),
    ],
    if (cooldownSeconds > 0)
      WorkoutPhase(PhaseKind.cooldown, Duration(seconds: cooldownSeconds)),
  ];
  Duration get total =>
      phases.fold(Duration.zero, (sum, p) => sum + p.duration);
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'warmup': warmupSeconds,
    'run': runSeconds,
    'recovery': recoverySeconds,
    'cooldown': cooldownSeconds,
    'repeats': repeats,
  };
  factory Workout.fromJson(Map<String, dynamic> json) => Workout(
    id: json['id'] as String,
    name: json['name'] as String,
    warmupSeconds: json['warmup'] as int,
    runSeconds: json['run'] as int,
    recoverySeconds: json['recovery'] as int,
    cooldownSeconds: json['cooldown'] as int,
    repeats: json['repeats'] as int,
  );
}

String clockText(Duration duration) {
  final seconds = (duration.inMilliseconds / 1000).ceil().clamp(0, 999999);
  final h = seconds ~/ 3600;
  final m = (seconds ~/ 60 % 60).toString().padLeft(2, '0');
  final s = (seconds % 60).toString().padLeft(2, '0');
  return h > 0 ? '$h:$m:$s' : '$m:$s';
}
