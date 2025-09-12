import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

class RadioService {
  RadioService._();
  static final RadioService instance = RadioService._();

  final AudioPlayer _player = AudioPlayer(); // single player app-wide
  bool _sessionConfigured = false;

  void init() {
    // Keep as a hook if you want to do more later.
  }

  Future<void> _ensureAudioSession() async {
    if (_sessionConfigured) return;
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    _sessionConfigured = true;
  }

  static const String liveUrl =
      'https://stream.voxx.pro/listen/radio_sangam/radio.mp3';

  Future<void> playLive() async {
    await _ensureAudioSession();
    try {
      final source = AudioSource.uri(
        Uri.parse(liveUrl),
        tag: const MediaItem(
          id: 'radio-sangam-live',
          album: 'Radio Sangam',
          title: 'Radio Sangam — Live',
          // artUri can be a https image; you can add later if you have one.
        ),
      );
      await _player.setAudioSource(source);
      await _player.play();
    } catch (e) {
      // Look at this in `flutter logs`
      // ignore: avoid_print
      print('playLive() failed: $e');
      rethrow;
    }
  }

  Future<void> playEpisode({
    required String id,
    required String title,
    required String url,
    String? artUrl,   // optional network image
    String? artAsset, // optional asset, e.g. 'assets/images/logo.png'
  }) async {
    await _ensureAudioSession();
    try {
      Uri? art;
      if (artUrl != null && artUrl.isNotEmpty) {
        art = Uri.parse(artUrl);
      } else if (artAsset != null && artAsset.isNotEmpty) {
        art = Uri.parse('asset:///$artAsset');
      }
      final source = AudioSource.uri(
        Uri.parse(url),
        tag: MediaItem(
          id: id,
          album: 'Radio Sangam • Podcasts',
          title: title,
          artUri: art,
        ),
      );
      await _player.setAudioSource(source);
      await _player.play();
    } catch (e) {
      // ignore: avoid_print
      print('playEpisode() failed: $e');
      rethrow;
    }
  }

  Future<void> pause() => _player.pause();
  Future<void> resume() => _player.play();
  Future<void> stop() => _player.stop();

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration?> get positionStream => _player.positionStream;

  AudioPlayer get player => _player;
}
