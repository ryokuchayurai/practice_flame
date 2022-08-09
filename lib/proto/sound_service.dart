import 'package:flame_audio/audio_pool.dart';

class SoundService {
  static final SoundService _instance = SoundService._();

  final Map<String, AudioPool> _poolMap = {};

  SoundService._() {
    _init();
  }

  Future<void> _init() async {
    _poolMap['talk_1'] = await AudioPool.create('audio/sfx/talk_1.mp3',
        minPlayers: 3, maxPlayers: 60);
    _poolMap['fire_1'] = await AudioPool.create('audio/sfx/fire_1.mp3',
        minPlayers: 3, maxPlayers: 10);
    _poolMap['fire_2'] = await AudioPool.create('audio/sfx/fire_2.mp3',
        minPlayers: 3, maxPlayers: 10);
  }

  factory SoundService() {
    return _instance;
  }

  void play(String sound, {double volume = 1.0}) {
    _poolMap[sound]?.start(volume: volume);
  }
}
