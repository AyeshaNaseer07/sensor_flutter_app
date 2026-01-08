import UIKit
import AVFoundation
import Flutter

class ChargerAlarmManager {
    
    // MARK: - Properties
    private var alarmPlayer: AVAudioPlayer?
    private var silentPlayer: AVAudioPlayer?
    private var isAlarmArmed = false
    private var isCharging = true
    private let methodChannel: FlutterMethodChannel
    
    // MARK: - Init
    init(methodChannel: FlutterMethodChannel) {
        self.methodChannel = methodChannel
        setupMethodChannel()
    }
    
    // MARK: - Method Channel Setup
    private func setupMethodChannel() {
        methodChannel.setMethodCallHandler { [weak self] call, result in
            switch call.method {
            case "armAlarm":
                self?.armAlarm()
                result("Charger Alarm Armed")
                
            case "disarmAlarm":
                self?.disarmAlarm()
                result("Charger Alarm Disarmed")
                
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
    
    // MARK: - Public Methods
    func setup() {
        enableBatteryMonitoring()
        startSilentAudio()
    }
    
    func armAlarm() {
        isAlarmArmed = true
        startSilentAudio()
        print("✅ Charger Alarm Armed")
    }
    
    func disarmAlarm() {
        isAlarmArmed = false
        stopAlarm()
        print("✅ Charger Alarm Disarmed")
    }
    
    // MARK: - Battery Monitoring
    private func enableBatteryMonitoring() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(batteryStateChanged),
            name: UIDevice.batteryStateDidChangeNotification,
            object: nil
        )
        print("✅ Battery Monitoring Enabled")
    }
    
    @objc private func batteryStateChanged() {
        let state = UIDevice.current.batteryState
        let wasCharging = isCharging
        isCharging = (state == .charging || state == .full)
        
        if isAlarmArmed {
            if wasCharging && !isCharging {
                // Unplugged from charger
                playAlarm()
            } else if !wasCharging && isCharging {
                // Plugged into charger
                stopAlarm()
            }
        }
        
        print("🔋 Battery State: \(state.rawValue), Charging: \(isCharging)")
    }
    
    // MARK: - Audio Playback
    private func playAlarm() {
        guard alarmPlayer?.isPlaying != true else { return }
        guard let url = Bundle.main.url(forResource: "fire_alarm", withExtension: "mp3") else {
            print("❌ Fire alarm audio file not found")
            return
        }
        
        do {
            alarmPlayer = try AVAudioPlayer(contentsOf: url)
            alarmPlayer?.numberOfLoops = -1
            alarmPlayer?.volume = 1.0
            alarmPlayer?.play()
            print("⚡ Charger Alarm Playing!")
        } catch {
            print("❌ Charger alarm error: \(error)")
        }
    }
    
    private func stopAlarm() {
        alarmPlayer?.stop()
        alarmPlayer = nil
    }
    
    private func startSilentAudio() {
        guard silentPlayer?.isPlaying != true else { return }
        guard let url = Bundle.main.url(forResource: "silent_alarm", withExtension: "mp3") else {
            print("❌ Silent audio file not found")
            return
        }
        
        do {
            silentPlayer = try AVAudioPlayer(contentsOf: url)
            silentPlayer?.numberOfLoops = -1
            silentPlayer?.volume = 0.01
            silentPlayer?.play()
            print("✅ Silent audio started")
        } catch {
            print("❌ Silent audio error: \(error)")
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        stopAlarm()
    }
}