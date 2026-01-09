import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ui_design/App/modules/sensors/clap_whistle_detect/audio_detector.dart';
import 'package:ui_design/App/service/alarm_service.dart';

class ClapDetectView extends StatefulWidget {
  const ClapDetectView({super.key});

  @override
  State<ClapDetectView> createState() => ClapDetectViewState();
}

class ClapDetectViewState extends State<ClapDetectView> {
  final AudioDetector _audioDetector = AudioDetector();
  final AlarmService _alarmService = AlarmService();

  bool _isListening = false;
  bool _isAlarmRinging = false;
  String _lastDetected = 'None';
  double _sensitivity = 0.5;

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    await _alarmService.init();

    _audioDetector.onClapDetected = () {
      setState(() => _lastDetected = 'Clap');
      _triggerAlarm();
    };

    _audioDetector.onWhistleDetected = () {
      setState(() => _lastDetected = 'Whistle');
      _triggerAlarm();
    };
  }

  void _triggerAlarm() {
    setState(() => _isAlarmRinging = true);
    _alarmService.playAlarm();
  }

  void _stopAlarm() {
    setState(() => _isAlarmRinging = false);
    _alarmService.stopAlarm();
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _audioDetector.stopListening();
      setState(() => _isListening = false);
    } else {
      final hasPermission = await _audioDetector.requestPermission();
      if (hasPermission) {
        await _audioDetector.startListening(_sensitivity);
        setState(() => _isListening = true);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission denied')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _audioDetector.dispose();
    _alarmService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clap & Whistle Alarm'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isListening ? Icons.mic : Icons.mic_off,
                size: 100,
                color: _isListening ? Colors.green : Colors.grey,
              ),
              SizedBox(height: 20.h),

              Text(
                _isListening ? 'Listening...' : 'Not Listening',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 20.h),

              Text(
                'Last Detected: $_lastDetected',
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),

              SizedBox(height: 20.h),

              if (!_isAlarmRinging) ...[
                ElevatedButton(
                  onPressed: _toggleListening,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 50,
                      vertical: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    _isListening ? 'Stop Detection' : 'Start Detection',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                SizedBox(height: 20.h),
                const Text('Sensitivity', style: TextStyle(fontSize: 16)),
                Slider(
                  value: _sensitivity,
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  label: '${(_sensitivity * 100).round()}%',
                  onChanged: (value) {
                    setState(() => _sensitivity = value);
                    if (_isListening) {
                      _audioDetector.updateSensitivity(value);
                    }
                  },
                ),
              ] else ...[
                const Icon(Icons.alarm, size: 100, color: Colors.red),
                const SizedBox(height: 20),
                const Text(
                  'ALARM RINGING!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _stopAlarm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 50,
                      vertical: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Stop Alarm',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ],

              SizedBox(height: 20.h),

              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'How it works:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text('👏 Clap detection: Sharp, loud sounds'),
                      Text('🎵 Whistle detection: Sustained tones (1-3kHz)'),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }
}
