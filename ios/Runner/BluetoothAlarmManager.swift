import Foundation
import AVFoundation
import CoreBluetooth
import Flutter

class BluetoothAlarmManager: NSObject, CBCentralManagerDelegate {
    
    // MARK: - Properties
    private var alarmPlayer: AVAudioPlayer?
    private var silentPlayer: AVAudioPlayer?
    private var alarmEnabled = false
    private var centralManager: CBCentralManager?
    private var connectedPeripheralCount = 0
    private let methodChannel: FlutterMethodChannel
    
    // MARK: - Init
    init(methodChannel: FlutterMethodChannel) {
        self.methodChannel = methodChannel
        super.init()
        setupMethodChannel()
    }
    
    // MARK: - Method Channel Setup
    private func setupMethodChannel() {
        methodChannel.setMethodCallHandler { [weak self] call, result in
            switch call.method {
            case "activateAlarm":
                self?.activateAlarm()
                result("Bluetooth Alarm Activated")
                
            case "deactivateAlarm":
                self?.deactivateAlarm()
                result("Bluetooth Alarm Deactivated")
                
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
    
    // MARK: - Public Methods
    func setup() {
        startSilentAudio()
        print("✅ Bluetooth Manager Setup Complete")
    }
    
    func activateAlarm() {
        alarmEnabled = true
        startBluetoothMonitoring()
        startSilentAudio()
        print("✅ Bluetooth Alarm Activated")
    }
    
    func deactivateAlarm() {
        alarmEnabled = false
        stopAlarm()
        stopBluetoothMonitoring()
        stopSilentAudio()
        print("✅ Bluetooth Alarm Deactivated")
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
    
    // MARK: - Bluetooth Monitoring
    private func startBluetoothMonitoring() {
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.global(qos: .background))
    }
    
    private func stopBluetoothMonitoring() {
        centralManager?.stopScan()
        centralManager = nil
    }
    
    // MARK: - CBCentralManagerDelegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            central.scanForPeripherals(
                withServices: nil,
                options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
            )
            print("✅ Bluetooth powered on, scanning started...")
            
            let connectedPeripherals = central.retrieveConnectedPeripherals(withServices: [])
            for peripheral in connectedPeripherals {
                print("🔗 Already connected: \(peripheral.name ?? "Unknown")")
                if alarmEnabled { playAlarm() }
                central.connect(peripheral, options: nil)
            }
            
        default:
            print("ℹ️ Bluetooth state changed: \(central.state.rawValue)")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectedPeripheralCount += 1
        print("🔗 Device Connected: \(peripheral.name ?? "Unknown")")
        if alarmEnabled { playAlarm() }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connectedPeripheralCount = max(connectedPeripheralCount - 1, 0)
        print("🔌 Device Disconnected: \(peripheral.name ?? "Unknown")")
        if alarmEnabled { playAlarm() }
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
            print("🚨 Bluetooth Alarm Playing!")
        } catch {
            print("❌ Bluetooth alarm error: \(error)")
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