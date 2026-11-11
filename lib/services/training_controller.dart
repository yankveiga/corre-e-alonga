import 'dart:async';
import 'package:flutter/foundation.dart';
import '../domain/repository.dart';
import '../domain/session.dart';
import '../domain/workout.dart';
import '../domain/location.dart';

class TrainingController extends ChangeNotifier {
  final WorkoutRepository repository;
  final AudioService audio;
  final MonotonicClock clock;
  final bool automaticTicks;
  final LocationService? location;
  RouteTracker route = RouteTracker();
  bool gpsEnabled = false, gpsBusy = false;
  String gpsStatus = 'GPS desligado';
  StreamSubscription<TrackPoint>? _positions;
  DateTime? _lastFix;
  List<Workout> workouts = [];
  List<Activity> activities = [];
  Preferences preferences = const Preferences();
  SessionEngine? session;
  String? sessionId;
  DateTime? startedAt;
  bool loaded = false, busy = false, recovered = false;
  String? error;
  Timer? _timer;
  Future<void> _writes = Future.value();
  int _lastCheckpointMs = 0;
  int _audioGeneration = 0;
  bool _foreground = true;
  bool _disposed = false;
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  TrainingController(
    this.repository,
    this.audio, {
    MonotonicClock? clock,
    this.automaticTicks = true,
    this.location,
  }) : clock = clock ?? StopwatchClock();

  Future<bool> _write(Future<void> Function() action) async {
    var success = true;
    final operation = _writes.then((_) => action());
    _writes = operation.catchError((Object e) {
      success = false;
      error =
          'Não foi possível salvar. Verifique o armazenamento e tente novamente.';
      notifyListeners();
    });
    await _writes;
    return success;
  }

  Future<void> initialize() async {
    try {
      workouts = await repository.workouts();
      preferences = await repository.preferences();
      activities = await repository.activities();
      final saved = await repository.checkpoint();
      if (saved != null) {
        session = SessionEngine(
          saved.workout,
          clock,
          elapsed: Duration(milliseconds: saved.elapsedMs),
        );
        sessionId = saved.id;
        startedAt = saved.startedAt;
        route = RouteTracker(points: saved.points, meters: saved.meters);
        recovered = true;
      }
      loaded = true;
    } catch (_) {
      error = 'Não foi possível abrir os dados locais. Tente novamente.';
    }
    notifyListeners();
    if (automaticTicks && loaded) {
      _timer ??= Timer.periodic(
        const Duration(milliseconds: 100),
        (_) => tick(),
      );
    }
  }

  Future<bool> saveWorkout(Workout workout) async {
    if (!await _write(() => repository.saveWorkout(workout))) return false;
    workouts = await repository.workouts();
    notifyListeners();
    return true;
  }

  Future<bool> deleteWorkout(String id) async {
    if (await _write(() => repository.deleteWorkout(id))) {
      workouts = await repository.workouts();
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> setPreferences(Preferences value) async {
    if (await _write(() => repository.savePreferences(value))) {
      preferences = value;
    }
    notifyListeners();
  }

  SessionCheckpoint _checkpoint() => SessionCheckpoint(
    sessionId!,
    session!.workout,
    session!.elapsed.inMilliseconds,
    startedAt!,
    points: route.points,
    meters: route.meters,
  );
  Future<bool> persist() async {
    if (session == null || session!.terminal) return true;
    final snapshot = _checkpoint();
    _lastCheckpointMs = snapshot.elapsedMs;
    return _write(() => repository.saveCheckpoint(snapshot));
  }

  Future<bool> start(Workout workout) async {
    if (busy || session != null) return false;
    busy = true;
    sessionId = DateTime.now().microsecondsSinceEpoch.toString();
    startedAt = DateTime.now();
    session = SessionEngine(workout, clock);
    recovered = false;
    route = RouteTracker();
    gpsEnabled = false;
    gpsStatus = 'GPS desligado';
    _phaseAtLastTick = 0;
    _lastCheckpointMs = 0;
    final saved = await persist();
    if (!saved) {
      session = null;
      busy = false;
      notifyListeners();
      return false;
    }
    session!.resume();
    busy = false;
    _announce(session!.phase.kind.label);
    notifyListeners();
    return true;
  }

  void _announce(String text) {
    if (!_foreground || _disposed) return;
    final generation = ++_audioGeneration;
    unawaited(_deliverAnnouncement(text, generation));
  }

  Future<void> _deliverAnnouncement(String text, int generation) async {
    try {
      // Uma fase nova substitui a instrução anterior, sem formar uma fila atrasada.
      await audio.stop();
      if (generation != _audioGeneration || !_foreground || _disposed) return;
      await audio.announce(text, preferences);
    } catch (_) {
      if (generation == _audioGeneration) {
        error =
            'Áudio indisponível. O temporizador continua; confira os indicadores visuais.';
        notifyListeners();
      }
    }
  }

  void tick() {
    final active = session;
    if (active == null || busy || active.status != SessionStatus.running) {
      return;
    }
    if (gpsEnabled &&
        _lastFix != null &&
        DateTime.now().difference(_lastFix!).inSeconds > 15) {
      gpsStatus = 'Aguardando nova posição GPS';
      route.breakSegment();
    }
    final previous = _phaseAtLastTick;
    active.synchronize();
    final current = active.phaseIndex;
    _phaseAtLastTick = current;
    if (active.status == SessionStatus.completed) {
      unawaited(finish(completed: true));
      return;
    }
    if (current != previous) _announce(active.phase.kind.label);
    if (active.elapsed.inMilliseconds - _lastCheckpointMs >= 1000) {
      unawaited(persist());
    }
    notifyListeners();
  }

  int _phaseAtLastTick = 0;
  Future<void> pause() async {
    if (busy || session == null) return;
    session!.pause();
    _stopLocation();
    _audioGeneration++;
    unawaited(audio.stop().catchError((Object _) {}));
    await persist();
    notifyListeners();
  }

  Future<void> resume() async {
    if (busy || session == null || session!.terminal) return;
    if (!await persist()) return;
    recovered = false;
    session!.resume();
    _startLocation();
    _phaseAtLastTick = session!.phaseIndex;
    _announce(session!.phase.kind.label);
    notifyListeners();
  }

  Future<bool> finish({bool completed = false}) async {
    if (busy || session == null) return false;
    busy = true;
    session!.stop();
    _stopLocation();
    final value = Activity(
      id: sessionId!,
      name: session!.workout.name,
      elapsedMs: session!.elapsed.inMilliseconds,
      startedAt: startedAt!,
      points: route.points,
      meters: route.meters,
      completed: completed || session!.status == SessionStatus.completed,
    );
    _audioGeneration++;
    await audio.stop().catchError((Object _) {});
    final saved = await _write(() => repository.finish(value));
    if (saved) {
      session = null;
      recovered = false;
      activities = await repository.activities();
      if (value.completed) _announce('Treino concluído');
    }
    busy = false;
    notifyListeners();
    return saved;
  }

  Future<void> enableGps() async {
    if (gpsBusy || location == null || session == null) return;
    gpsBusy = true;
    final id = sessionId;
    notifyListeners();
    try {
      await location!.requestAccess();
      if (session == null || sessionId != id || _disposed) return;
      gpsEnabled = true;
      gpsStatus = 'Aguardando sinal GPS';
      _startLocation();
    } catch (e) {
      gpsStatus = e.toString().replaceFirst('Bad state: ', '');
      gpsEnabled = false;
    } finally {
      gpsBusy = false;
      notifyListeners();
    }
  }

  void disableGps() {
    gpsEnabled = false;
    _stopLocation();
    gpsStatus = 'GPS desligado';
    notifyListeners();
  }

  void _startLocation() {
    if (!gpsEnabled ||
        location == null ||
        _positions != null ||
        !_foreground ||
        session?.status != SessionStatus.running) {
      return;
    }
    route.breakSegment();
    _lastFix = DateTime.now();
    _positions = location!.positions().listen(
      (point) {
        if (!gpsEnabled ||
            !_foreground ||
            session?.status != SessionStatus.running) {
          return;
        }
        if (route.add(point, DateTime.now())) {
          _lastFix = DateTime.now();
          gpsStatus = 'GPS ativo · precisão ${point.accuracy.round()} m';
        } else {
          gpsStatus = 'Sinal impreciso: aguardando uma posição confiável';
        }
        notifyListeners();
      },
      onError: (Object e) {
        route.breakSegment();
        gpsStatus = 'GPS indisponível. Desative e ative para tentar novamente.';
        notifyListeners();
      },
    );
  }

  void _stopLocation() {
    final subscription = _positions;
    _positions = null;
    if (subscription != null) unawaited(subscription.cancel());
    route.breakSegment();
  }

  Future<void> onBackground() async {
    _foreground = false;
    // MVP sem scheduler nativo: pausa explícita evita falsa promessa sob bloqueio.
    await pause();
  }

  void onForeground() {
    _foreground = true;
    notifyListeners();
  }

  void clearError() {
    error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopLocation();
    _disposed = true;
    _audioGeneration++;
    _timer?.cancel();
    unawaited(audio.dispose().catchError((Object _) {}));
    super.dispose();
  }
}
