import AVFoundation
import Flutter

class AudioDetectorService {
    
    // MARK: - Properties
    private var audioEngine: AVAudioEngine?
    private var silentPlayer: AVAudioPlayer?
    private let methodChannel: FlutterMethodChannel
    private var isListening = false
    
    // Detection parameters
    private var sensitivity: Double = 0.5
    private let baseClapThreshold: Float = 0.9
    private let baseWhistleAmplitude: Float = 0.5
    private let whistleFreqMin: Float = 1000.0
    private let whistleFreqMax: Float = 3000.0
    
    // Clap/Whistle state
    private var lastClapTime: Date?
    private var lastWhistleTime: Date?
    private var consecutiveWhistleCount = 0
    
    // MARK: - Init
    init(methodChannel: FlutterMethodChannel) {
        self.methodChannel = methodChannel
        setupMethodChannel()
    }
    
    // MARK: - Method Channel Setup
    private func setupMethodChannel() {
        methodChannel.setMethodCallHandler { [weak self] call, result in
            switch call.method {
            case "startBackgroundDetection":
                if let args = call.arguments as? [String: Any],
                   let sensitivity = args["sensitivity"] as? Double {
                    self?.sensitivity = sensitivity
                }
                self?.startBackgroundDetection()
                result(true)
                
            case "stopBackgroundDetection":
                self?.stopBackgroundDetection()
                result(true)
                
            case "updateSensitivity":
                if let args = call.arguments as? [String: Any],
                   let sensitivity = args["sensitivity"] as? Double {
                    self?.sensitivity = sensitivity
                }
                result(true)
                
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
    
    // MARK: - Public Methods
    func startBackgroundDetection() {
        setupAudioSession()
        startSilentAudio()
        startMicrophoneListening()
        isListening = true
        print("✅ Background detection started")
    }
    
    func stopBackgroundDetection() {
        stopMicrophoneListening()
        stopSilentAudio()
        isListening = false
        print("✅ Background detection stopped")
    }
    
    // MARK: - Audio Session Configuration
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(
                .playAndRecord,
                mode: .default,
                options: [.mixWithOthers, .allowBluetooth, .defaultToSpeaker]
            )
            try audioSession.setActive(true)
            print("✅ Audio session configured for background")
        } catch {
            print("❌ Failed to setup audio session: \(error)")
        }
    }
    
    // MARK: - Silent Audio (Keeps session alive)
    private func startSilentAudio() {
        let silentAudioURL = generateSilentAudio()
        
        do {
            silentPlayer = try AVAudioPlayer(contentsOf: silentAudioURL)
            silentPlayer?.numberOfLoops = -1
            silentPlayer?.volume = 0.0
            silentPlayer?.play()
            print("✅ Silent audio started")
        } catch {
            print("❌ Failed to start silent audio: \(error)")
        }
    }
    
    private func stopSilentAudio() {
        silentPlayer?.stop()
        silentPlayer = nil
    }
    
    private func generateSilentAudio() -> URL {
        let silenceURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("silence.m4a")
        
        if FileManager.default.fileExists(atPath: silenceURL.path) {
            return silenceURL
        }
        
        let sampleRate: Double = 44100.0
        let duration: Double = 1.0
        let frameCount = Int(sampleRate * duration)
        
        let audioFormat = AVAudioFormat(
            standardFormatWithSampleRate: sampleRate,
            channels: 1
        )!
        
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: audioFormat,
            frameCapacity: AVAudioFrameCount(frameCount)
        ) else {
            fatalError("Could not create audio buffer")
        }
        
        buffer.frameLength = AVAudioFrameCount(frameCount)
        
        do {
            let audioFile = try AVAudioFile(
                forWriting: silenceURL,
                settings: audioFormat.settings
            )
            try audioFile.write(from: buffer)
        } catch {
            print("❌ Error creating silent audio: \(error)")
        }
        
        return silenceURL
    }
    
    // MARK: - Microphone Listening
    private func startMicrophoneListening() {
        audioEngine = AVAudioEngine()
        
        guard let audioEngine = audioEngine else { return }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(
            onBus: 0,
            bufferSize: 4096,
            format: recordingFormat
        ) { [weak self] (buffer, time) in
            self?.processAudioBuffer(buffer)
        }
        
        do {
            try audioEngine.start()
            print("✅ Microphone listening started")
        } catch {
            print("❌ Failed to start audio engine: \(error)")
        }
    }
    
    private func stopMicrophoneListening() {
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
    }
    
    // MARK: - Audio Processing
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        
        let frameLength = Int(buffer.frameLength)
        let samples = Array(UnsafeBufferPointer(start: channelData[0], count: frameLength))
        let maxAmplitude = samples.map { abs($0) }.max() ?? 0.0
        
        detectClap(amplitude: maxAmplitude)
        detectWhistle(samples: samples, amplitude: maxAmplitude)
    }
    
    // MARK: - Clap Detection
    private func detectClap(amplitude: Float) {
        let adjustedThreshold = baseClapThreshold * Float(1.0 - 0.5 * sensitivity)
        
        if amplitude > adjustedThreshold {
            let now = Date()
            if let lastClap = lastClapTime, now.timeIntervalSince(lastClap) < 0.5 { return }
            lastClapTime = now
            
            print("👏 CLAP DETECTED! Amplitude: \(amplitude)")
            
            DispatchQueue.main.async { [weak self] in
                self?.methodChannel.invokeMethod("onClapDetected", arguments: nil)
            }
        }
    }
    
    // MARK: - Whistle Detection
    private func detectWhistle(samples: [Float], amplitude: Float) {
        let adjustedAmplitude = baseWhistleAmplitude * Float(1.0 - 0.5 * sensitivity)
        
        if amplitude < adjustedAmplitude {
            consecutiveWhistleCount = 0
            return
        }
        
        let dominantFreq = findDominantFrequency(samples: samples)
        
        if dominantFreq >= whistleFreqMin && dominantFreq <= whistleFreqMax {
            consecutiveWhistleCount += 1
            if consecutiveWhistleCount >= 3 {
                let now = Date()
                if let lastWhistle = lastWhistleTime, now.timeIntervalSince(lastWhistle) < 1.0 { return }
                lastWhistleTime = now
                consecutiveWhistleCount = 0
                
                print("🎵 WHISTLE DETECTED! Frequency: \(dominantFreq) Hz")
                
                DispatchQueue.main.async { [weak self] in
                    self?.methodChannel.invokeMethod("onWhistleDetected", arguments: nil)
                }
            }
        } else {
            consecutiveWhistleCount = 0
        }
    }
    
    // MARK: - Frequency Detection
    private func findDominantFrequency(samples: [Float]) -> Float {
        guard samples.count > 1 else { return 0 }
        
        var zeroCrossings = 0
        
        for i in 1..<samples.count {
            if (samples[i] >= 0 && samples[i-1] < 0) ||
               (samples[i] < 0 && samples[i-1] >= 0) {
                zeroCrossings += 1
            }
        }
        
        let sampleRate: Float = 44100.0
        let frequency = (Float(zeroCrossings) * sampleRate) / (2.0 * Float(samples.count))
        
        return frequency
    }
    
    // MARK: - Cleanup
    deinit {
        stopBackgroundDetection()
    }
}