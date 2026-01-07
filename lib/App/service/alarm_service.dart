import 'package:audioplayers/audioplayers.dart';

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  Future<void> init() async {
    await _player.setReleaseMode(ReleaseMode.loop);
  }

  Future<void> playAlarm() async {
    if (_isPlaying) return;
    _isPlaying = true;
    await _player.play(AssetSource('alarms/fire_alarm.mp3'), volume: 1.0);
  }

  Future<void> stopAlarm() async {
    if (!_isPlaying) return;
    _isPlaying = false;
    await _player.stop();
  }

  bool get isPlaying => _isPlaying;
}
