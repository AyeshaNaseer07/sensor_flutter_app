import Foundation
import AVFoundation
import Network
import Flutter

class WifiAlarmManager {
    
    // MARK: - Properties
    private var alarmPlayer: AVAudioPlayer?
    private var silentPlayer: AVAudioPlayer?
    private let wifiMonitor = NWPathMonitor()
    private var alarmEnabled = false
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
            case "activateAlarm":
                self?.activateAlarm()
                result("Wi‑Fi Alarm Activated")
                
            case "deactivateAlarm":
                self?.deactivateAlarm()
                result("Wi‑Fi Alarm Deactivated")
                
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
    
    // MARK: - Public Methods
    func setup() {
        startWifiMonitoring()
        startSilentAudio()
    }
    
    func activateAlarm() {
        alarmEnabled = true
        startSilentAudio()
        print("✅ Wi-Fi Alarm Activated")
    }
    
    func deactivateAlarm() {
        alarmEnabled = false
        stopAlarm()
        stopSilentAudio()
        print("✅ Wi-Fi Alarm Deactivated")
    }
    
    func handleBackground() {
        if alarmEnabled {
            startSilentAudio()
        }
    }
    
    func handleForeground() {
        if alarmEnabled {
            startSilentAudio()
        }
    }
    
    // MARK: - Wi-Fi Monitoring
    private func startWifiMonitoring() {
        wifiMonitor.pathUpdateHandler = { [weak self] path in
            if self?.alarmEnabled == true && path.status != .satisfied {
                self?.playAlarm()
            } else {
                self?.stopAlarm()
            }
        }
        wifiMonitor.start(queue: DispatchQueue.global(qos: .background))
        print("✅ Wi-Fi Monitoring Started")
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
            print("🚨 Wi-Fi Alarm Playing!")
        } catch {
            print("❌ Wi-Fi alarm error: \(error)")
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
    
    private func stopSilentAudio() {
        silentPlayer?.stop()
        silentPlayer = nil
    }
}