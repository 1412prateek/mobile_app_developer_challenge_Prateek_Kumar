import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum AppPlaybackState { idle, preparing, playing, finished, error }

class StoryAudioNotifier extends Notifier<AppPlaybackState> {
  final FlutterTts _flutterTts = FlutterTts();
  Timer? _safetyTimer;

  @override
  AppPlaybackState build() {
    _initTts();
    ref.onDispose(() {
      _safetyTimer?.cancel();
      _flutterTts.stop();
    });
    return AppPlaybackState.idle;
  }

  void _initTts() {
    _flutterTts.setStartHandler(() {
      _safetyTimer?.cancel();
      // Start a safety timeout: if TTS doesn't finish or error within 25 seconds, force-complete or error.
      _safetyTimer = Timer(const Duration(seconds: 25), () {
        if (state == AppPlaybackState.playing) {
          state = AppPlaybackState.finished;
        }
      });
      state = AppPlaybackState.playing;
    });

    _flutterTts.setCompletionHandler(() {
      _safetyTimer?.cancel();
      state = AppPlaybackState.finished;
    });

    _flutterTts.setErrorHandler((message) {
      _safetyTimer?.cancel();
      state = AppPlaybackState.error;
    });

    _flutterTts.setCancelHandler(() {
      _safetyTimer?.cancel();
      state = AppPlaybackState.idle;
    });
  }

  Future<void> speak(String text) async {
    if (state == AppPlaybackState.playing || state == AppPlaybackState.preparing) {
      return;
    }

    state = AppPlaybackState.preparing;
    _safetyTimer?.cancel();

    // Safety timeout during preparation: if TTS fails to start within 5 seconds
    _safetyTimer = Timer(const Duration(seconds: 5), () {
      if (state == AppPlaybackState.preparing) {
        state = AppPlaybackState.error;
      }
    });

    try {
      // Set child-friendly voice settings (moderately slow speech rate, higher pitch for a friendly tone)
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.4); // slightly slower for kids
      await _flutterTts.setPitch(1.3);      // slightly higher pitch for Buddy character

      final result = await _flutterTts.speak(text);
      if (result != 1) {
        // Speak call failed directly
        _safetyTimer?.cancel();
        state = AppPlaybackState.error;
      }
    } catch (e) {
      _safetyTimer?.cancel();
      state = AppPlaybackState.error;
    }
  }

  Future<void> stop() async {
    _safetyTimer?.cancel();
    await _flutterTts.stop();
    state = AppPlaybackState.idle;
  }

  void reset() {
    _safetyTimer?.cancel();
    state = AppPlaybackState.idle;
  }
}

final storyAudioProvider = NotifierProvider<StoryAudioNotifier, AppPlaybackState>(() {
  return StoryAudioNotifier();
});
