import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import '../domain/repository.dart';

class DeviceAudio implements AudioService {
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _player = AudioPlayer();
  bool _initialized = false;
  int _generation = 0;
  @override
  Future<void> announce(String text, Preferences preferences) async {
    final generation = _generation;
    if (!preferences.voice && !preferences.sound && !preferences.haptics) {
      return;
    }
    if (preferences.haptics) await HapticFeedback.mediumImpact();
    // Cada saída é independente: indisponibilidade de voz não remove o bip.
    Object? failure;
    if (preferences.sound) {
      try {
        await _player.setAsset('assets/audio/interval.wav');
        if (generation != _generation) return;
        await _player.play().timeout(const Duration(seconds: 3));
      } catch (error) {
        failure = error;
      }
    }
    if (generation != _generation) return;
    if (preferences.voice) {
      try {
        if (!_initialized) {
          await _tts.setLanguage('pt-BR');
          await _tts.setSpeechRate(0.48);
          await _tts.awaitSpeakCompletion(true);
          _initialized = true;
        }
        if (generation != _generation) return;
        await _tts.speak(text).timeout(const Duration(seconds: 8));
      } catch (error) {
        failure = error;
      }
    }
    if (failure != null) {
      throw StateError('Saída de áudio indisponível: $failure');
    }
  }

  @override
  Future<void> stop() async {
    _generation++;
    try {
      await _tts.stop();
    } finally {
      await _player.stop();
    }
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _player.dispose();
  }
}
