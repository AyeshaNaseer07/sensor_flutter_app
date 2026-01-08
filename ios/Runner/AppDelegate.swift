import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {

    // MARK: - Manager References
    private var wifiAlarmManager: WifiAlarmManager?
    private var bluetoothAlarmManager: BluetoothAlarmManager?
    private var chargerAlarmManager: ChargerAlarmManager?
    private var audioDetectorService: AudioDetectorService?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        GeneratedPluginRegistrant.register(with: self)
        
        let controller = window?.rootViewController as! FlutterViewController

        // MARK: - Initialize Managers
        initializeWifiManager(controller: controller)
        initializeBluetoothManager(controller: controller)
        initializeChargerManager(controller: controller)
        initializeAudioDetector(controller: controller)

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // MARK: - Wi-Fi Manager Initialization
    private func initializeWifiManager(controller: FlutterViewController) {
        let wifiChannel = FlutterMethodChannel(
            name: "wifi.alarm/channel",
            binaryMessenger: controller.binaryMessenger
        )
        
        wifiAlarmManager = WifiAlarmManager(methodChannel: wifiChannel)
        wifiAlarmManager?.setup()
    }

    // MARK: - Bluetooth Manager Initialization
    private func initializeBluetoothManager(controller: FlutterViewController) {
        let bluetoothChannel = FlutterMethodChannel(
            name: "bluetooth.alarm/channel",
            binaryMessenger: controller.binaryMessenger
        )
        
        bluetoothAlarmManager = BluetoothAlarmManager(methodChannel: bluetoothChannel)
        bluetoothAlarmManager?.setup()
    }

    // MARK: - Charger Manager Initialization
    private func initializeChargerManager(controller: FlutterViewController) {
        let chargerChannel = FlutterMethodChannel(
            name: "charger.alarm/channel",
            binaryMessenger: controller.binaryMessenger
        )
        
        chargerAlarmManager = ChargerAlarmManager(methodChannel: chargerChannel)
        chargerAlarmManager?.setup()
    }

    // MARK: - Audio Detector Initialization
  private func initializeAudioDetector(controller: FlutterViewController) {
    let detectorChannel = FlutterMethodChannel(
        name: "com.clapwhistle.alarm/detector",
        binaryMessenger: controller.binaryMessenger
    )
    
    audioDetectorService = AudioDetectorService(methodChannel: detectorChannel)
    audioDetectorService?.startBackgroundDetection()
}

    // MARK: - Background Handling
    override func applicationDidEnterBackground(_ application: UIApplication) {
        wifiAlarmManager?.handleBackground()
        bluetoothAlarmManager?.handleBackground()
    }

    override func applicationWillEnterForeground(_ application: UIApplication) {
        wifiAlarmManager?.handleForeground()
        bluetoothAlarmManager?.handleForeground()
    }

   deinit {
    audioDetectorService?.stopBackgroundDetection()
}
}
