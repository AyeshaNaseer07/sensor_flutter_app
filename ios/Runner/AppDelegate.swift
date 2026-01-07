import UIKit
import Flutter
import Network
import CoreBluetooth
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate, CBCentralManagerDelegate {

    // MARK: - Wi-Fi
    var wifiAlarmPlayer: AVAudioPlayer?
    var wifiSilentPlayer: AVAudioPlayer?
    let wifiMonitor = NWPathMonitor()
    var wifiAlarmEnabled = false

// MARK: - Bluetooth
var bluetoothAlarmPlayer: AVAudioPlayer?
var bluetoothSilentPlayer: AVAudioPlayer?
var bluetoothAlarmEnabled = false
var centralManager: CBCentralManager?
var connectedPeripheralCount = 0

    // MARK: - Charger
    var chargerAlarmPlayer: AVAudioPlayer?
    var isAlarmArmed = false
    var isCharging = true

    // MARK: - Global Silent Audio
    var globalSilentPlayer: AVAudioPlayer?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        GeneratedPluginRegistrant.register(with: self)
        
        let controller = window?.rootViewController as! FlutterViewController

        // Enable battery monitoring
        UIDevice.current.isBatteryMonitoringEnabled = true
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(batteryStateChanged),
            name: UIDevice.batteryStateDidChangeNotification,
            object: nil
        )

        // MARK: - Wi-Fi Method Channel
        let wifiChannel = FlutterMethodChannel(name: "wifi.alarm/channel", binaryMessenger: controller.binaryMessenger)
        wifiChannel.setMethodCallHandler { call, result in
            switch call.method {
            case "activateAlarm":
                self.wifiAlarmEnabled = true
                self.startWifiSilentService()
                result("Wi‑Fi Alarm Activated")
            case "deactivateAlarm":
                self.wifiAlarmEnabled = false
                self.stopWifiAlarm()
                self.stopWifiSilentService()
                result("Wi‑Fi Alarm Deactivated")
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        // MARK: - Bluetooth Method Channel
        let bluetoothChannel = FlutterMethodChannel(name: "bluetooth.alarm/channel", binaryMessenger: controller.binaryMessenger)
        bluetoothChannel.setMethodCallHandler { call, result in
            switch call.method {
            case "activateAlarm":
                self.bluetoothAlarmEnabled = true
                self.startBluetoothSilentService()
                self.startBluetoothMonitoring()
                result("Bluetooth Alarm Activated")
            case "deactivateAlarm":
                self.bluetoothAlarmEnabled = false
                self.stopBluetoothAlarm()
                self.stopBluetoothSilentService()
                result("Bluetooth Alarm Deactivated")
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        // MARK: - Charger Method Channel
        let chargerChannel = FlutterMethodChannel(name: "charger.alarm/channel", binaryMessenger: controller.binaryMessenger)
        chargerChannel.setMethodCallHandler { call, result in
            switch call.method {
            case "armAlarm":
                self.isAlarmArmed = true
                self.startGlobalSilentAudio()
                result("Charger Alarm Armed")
            case "disarmAlarm":
                self.isAlarmArmed = false
                self.stopChargerAlarm()
                result("Charger Alarm Disarmed")
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        // Start Wi-Fi monitoring and global silent audio
        startWifiMonitoring()
        startGlobalSilentAudio()

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // MARK: - Global Silent Audio
    func startGlobalSilentAudio() {
        if globalSilentPlayer?.isPlaying == true { return }
        guard let url = Bundle.main.url(forResource: "silent_alarm", withExtension: "mp3") else { return }
        do {
            globalSilentPlayer = try AVAudioPlayer(contentsOf: url)
            globalSilentPlayer?.numberOfLoops = -1
            globalSilentPlayer?.volume = 0.01
            globalSilentPlayer?.play()
        } catch {
            print("Silent player error:", error)
        }
    }

    // MARK: - Wi-Fi
    func startWifiMonitoring() {
        wifiMonitor.pathUpdateHandler = { path in
            if self.wifiAlarmEnabled && path.status != .satisfied {
                self.playWifiAlarm()
            } else {
                self.stopWifiAlarm()
            }
        }
        wifiMonitor.start(queue: DispatchQueue.global(qos: .background))
    }

    func playWifiAlarm() {
        if wifiAlarmPlayer?.isPlaying == true { return }
        guard let url = Bundle.main.url(forResource: "fire_alarm", withExtension: "mp3") else { return }
        do {
            wifiAlarmPlayer = try AVAudioPlayer(contentsOf: url)
            wifiAlarmPlayer?.numberOfLoops = -1
            wifiAlarmPlayer?.volume = 1.0
            wifiAlarmPlayer?.play()
            print("🔥 Wi‑Fi Alarm Playing!")
        } catch {
            print("Wi‑Fi alarm error:", error)
        }
    }

    func stopWifiAlarm() { wifiAlarmPlayer?.stop() }
    func startWifiSilentService() { startGlobalSilentAudio() }
    func stopWifiSilentService() { wifiSilentPlayer?.stop() }

// MARK: - Bluetooth
    func startBluetoothMonitoring() {
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.global(qos: .background))
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            central.scanForPeripherals(withServices: nil,
                                       options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
            print("Bluetooth powered on, scanning started...")

            // Track already connected peripherals
            let connectedPeripherals = central.retrieveConnectedPeripherals(withServices: [])
            for peripheral in connectedPeripherals {
                print("Already connected: \(peripheral.name ?? "Unknown")")
                if bluetoothAlarmEnabled { playBluetoothAlarm() }
                central.connect(peripheral, options: nil)
            }

        default:
            print("Bluetooth state changed: \(central.state.rawValue)")
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectedPeripheralCount += 1
        print("Device Connected: \(peripheral.name ?? "Unknown")")
        if bluetoothAlarmEnabled { playBluetoothAlarm() }
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connectedPeripheralCount = max(connectedPeripheralCount - 1, 0)
        print("Device Disconnected: \(peripheral.name ?? "Unknown")")
        if bluetoothAlarmEnabled { playBluetoothAlarm() }
    }

    func playBluetoothAlarm() {
        if bluetoothAlarmPlayer?.isPlaying == true { return }
        guard let url = Bundle.main.url(forResource: "fire_alarm", withExtension: "mp3") else { return }
        do {
            bluetoothAlarmPlayer = try AVAudioPlayer(contentsOf: url)
            bluetoothAlarmPlayer?.numberOfLoops = -1
            bluetoothAlarmPlayer?.volume = 1.0
            bluetoothAlarmPlayer?.play()
            print("🔥 Bluetooth Alarm Playing!")
        } catch {
            print("Bluetooth alarm error:", error)
        }
    }

    func stopBluetoothAlarm() { bluetoothAlarmPlayer?.stop() }
    func startBluetoothSilentService() { startGlobalSilentAudio() }
    func stopBluetoothSilentService() { bluetoothSilentPlayer?.stop() }
    
    // MARK: - Charger
    @objc func batteryStateChanged() {
        let state = UIDevice.current.batteryState
        let wasCharging = isCharging
        isCharging = (state == .charging || state == .full)

        if isAlarmArmed {
            if wasCharging && !isCharging {
                playChargerAlarm()
            } else if !wasCharging && isCharging {
                stopChargerAlarm()
            }
        }
    }

    func playChargerAlarm() {
        if chargerAlarmPlayer?.isPlaying == true { return }
        guard let url = Bundle.main.url(forResource: "fire_alarm", withExtension: "mp3") else { return }
        do {
            chargerAlarmPlayer = try AVAudioPlayer(contentsOf: url)
            chargerAlarmPlayer?.numberOfLoops = -1
            chargerAlarmPlayer?.volume = 1.0
            chargerAlarmPlayer?.play()
            print("⚡ Charger Alarm Playing!")
        } catch {
            print("Charger alarm error:", error)
        }
    }

    func stopChargerAlarm() {
        chargerAlarmPlayer?.stop()
        chargerAlarmPlayer = nil
    }

    // MARK: - Background Handling
    override func applicationDidEnterBackground(_ application: UIApplication) {
        if wifiAlarmEnabled { startWifiSilentService() }
        if bluetoothAlarmEnabled { startBluetoothSilentService() }
    }

    override func applicationWillEnterForeground(_ application: UIApplication) {
        if wifiAlarmEnabled { startWifiSilentService() }
        if bluetoothAlarmEnabled { startBluetoothSilentService() }
    }
}
