import 'session.dart';
import 'workout.dart';

class Preferences {
  final bool voice, sound, haptics;
  final String theme, unit;
  const Preferences({
    this.voice = true,
    this.sound = true,
    this.haptics = true,
    this.theme = 'system',
    this.unit = 'km',
  });
  Map<String, dynamic> toJson() => {
    'voice': voice,
    'sound': sound,
    'haptics': haptics,
    'theme': theme,
    'unit': unit,
  };
  factory Preferences.fromJson(Map<String, dynamic> json) => Preferences(
    voice: json['voice'] as bool,
    sound: json['sound'] as bool,
    haptics: json['haptics'] as bool,
    theme: json['theme'] as String,
    unit: json['unit'] as String? ?? 'km',
  );
}

abstract interface class WorkoutRepository {
  Future<List<Workout>> workouts();
  Future<void> saveWorkout(Workout workout);
  Future<void> deleteWorkout(String id);
  Future<Preferences> preferences();
  Future<void> savePreferences(Preferences preferences);
  Future<SessionCheckpoint?> checkpoint();
  Future<void> saveCheckpoint(SessionCheckpoint checkpoint);
  Future<void> finish(Activity activity);
  Future<List<Activity>> activities();
  Future<void> close();
}

abstract interface class AudioService {
  Future<void> announce(String text, Preferences preferences);
  Future<void> stop();
  Future<void> dispose();
}
