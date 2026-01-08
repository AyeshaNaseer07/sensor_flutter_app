import Flutter
import AVFoundation

class PermissionHandler: NSObject, FlutterPlugin {
    
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "flutter.baseflow.com/permissions/methods",
            binaryMessenger: registrar.messenger()
        )
        let instance = PermissionHandler()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    func dummyMethodToEnforceBundling() {}
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "requestPermissions":
            handleRequestPermissions(call, result: result)
        case "checkPermissionStatus":
            handleCheckPermissionStatus(call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func handleRequestPermissions(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let permissions = args["permissions"] as? [Int] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }
        
        var results: [Int: Int] = [:]
        
        for permission in permissions {
            if permission == 6 { // Microphone permission (RECORD_AUDIO)
                requestMicrophonePermission { granted in
                    results[permission] = granted ? 1 : 2 // 1 = granted, 2 = denied
                }
            }
        }
        
        // Return results after a short delay to ensure async completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            result(results)
        }
    }
    
    private func handleCheckPermissionStatus(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let permissions = args["permissions"] as? [Int] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }
        
        var results: [Int: Int] = [:]
        
        for permission in permissions {
            if permission == 6 { // Microphone permission
                let status = checkMicrophonePermission()
                results[permission] = status
            }
        }
        
        result(results)
    }
    
    private func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    private func checkMicrophonePermission() -> Int {
        let status = AVAudioSession.sharedInstance().recordPermission
        switch status {
        case .granted:
            return 1 // Permission granted
        case .denied:
            return 2 // Permission denied
        case .undetermined:
            return 0 // Permission undetermined
        @unknown default:
            return 0
        }
    }
}
