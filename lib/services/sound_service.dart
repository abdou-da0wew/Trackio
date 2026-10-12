import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'settings_service.dart';

/// Plays demo alarm sounds. All playback is fail-safe: on web, autoplay
/// policies or missing codecs must never crash the demo.
class SoundService {
  final AudioPlayer _player = AudioPlayer();
  AlertSound? _configured;

  AlertSound configured(AlertSound s) => _configured ??= s;

  Future<void> playAsset(String asset) async {
    if (kIsWeb) {
      try {
        await _player.stop();
        await _player.play(AssetSource(asset));
      } catch (_) {/* autoplay policies — ignore in demo */}
    } else {
      try {
        await _player.stop();
        await _player.play(AssetSource(asset));
      } catch (_) {}
    }
  }

  Future<void> playAlert(AlertSound s) => playAsset(s.asset);

  Future<void> playSuccess() => playAsset('sounds/gentle_chime.wav');

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
  }

  void dispose() => _player.dispose();
}
