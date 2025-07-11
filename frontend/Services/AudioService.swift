import Foundation
import AVFoundation

class AudioService: NSObject, ObservableObject {
    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?
    private let recordingDuration: TimeInterval = 15.0
    private let apiUrl = "https://voice-mentor-server.onrender.com/process-audio"
    
    @Published var isRecording = false
    @Published var currentRecordingTime: TimeInterval = 0
    @Published var isBluetoothAvailable = false
    @Published var lastTranscription: String = ""
    @Published var lastError: String = ""
    
    private let transcriptionService: TranscriptionService
    private let gptService: GPTService
    private let authService: AuthService
    private var currentRecordingURL: URL?
    private var isProcessingRecording = false
    
    init(transcriptionService: TranscriptionService = TranscriptionService(), gptService: GPTService, authService: AuthService) {
        self.transcriptionService = transcriptionService
        self.gptService = gptService
        self.authService = authService
        super.init()
        setupAudioSession()
        setupBluetoothMonitoring()
    }
    
    private func setupAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, 
                                  mode: .default,
                                  options: [.allowBluetooth, .allowBluetoothA2DP])
            try session.setActive(true)
            let availableInputs = session.availableInputs
            isBluetoothAvailable = availableInputs?.contains(where: { input in
                input.portType == .bluetoothHFP || 
                input.portType == .bluetoothA2DP ||
                input.portType == .bluetoothLE
            }) ?? false
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    private func setupBluetoothMonitoring() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
    }
    
    @objc private func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        switch reason {
        case .newDeviceAvailable, .oldDeviceUnavailable:
            let session = AVAudioSession.sharedInstance()
            let availableInputs = session.availableInputs
            isBluetoothAvailable = availableInputs?.contains(where: { input in
                input.portType == .bluetoothHFP || 
                input.portType == .bluetoothA2DP ||
                input.portType == .bluetoothLE
            }) ?? false
        default:
            break
        }
    }
    
    // Новый toggle: просто старт/стоп записи
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording-\(Date().timeIntervalSince1970).m4a")
        currentRecordingURL = audioFilename
        print("Starting recording to: \(audioFilename.path)")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            AVEncoderBitRateKey: 128000
        ]
        // Очищаем фидбэк у последнего транскрипта
        DispatchQueue.main.async { [weak self] in
            if let last = self?.transcriptionService.transcriptions.first, last.feedback != "" {
                self?.transcriptionService.updateFeedback(for: last.id, feedback: "")
            }
        }
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            DispatchQueue.main.async { [weak self] in
                self?.isRecording = true
                self?.currentRecordingTime = 0
            }
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                DispatchQueue.main.async { [weak self] in
                    self?.currentRecordingTime += 1
                    if self?.currentRecordingTime ?? 0 >= self?.recordingDuration ?? 15 {
                        self?.stopAndSendRecording()
                    }
                }
            }
        } catch {
            print("Could not start recording: \(error)")
            DispatchQueue.main.async { [weak self] in
                self?.lastError = "Failed to start recording: \(error.localizedDescription)"
            }
        }
    }
    
    private func stopAndSendRecording() {
        guard let recorder = audioRecorder, !isProcessingRecording else { return }
        isProcessingRecording = true
        recorder.stop()
        // Запись будет продолжена после обработки текущего фрагмента
    }
    
    private func stopRecording() {
        audioRecorder?.stop()
        recordingTimer?.invalidate()
        recordingTimer = nil
        DispatchQueue.main.async { [weak self] in
            self?.isRecording = false
            self?.currentRecordingTime = 0
        }
    }
    
    private func getFileSize(url: URL) -> Int64 {
        do {
            let resources = try url.resourceValues(forKeys: [.fileSizeKey])
            return Int64(resources.fileSize ?? 0)
        } catch {
            print("Error getting file size: \(error)")
            return 0
        }
    }
    
    private func sendAudioToServer(audioFileURL: URL) {
        print("Preparing to send file: \(audioFileURL.path)")
        guard let audioData = try? Data(contentsOf: audioFileURL) else {
            print("Failed to read audio file")
            lastError = "Failed to read audio file"
            isProcessingRecording = false
            if isRecording {
                startRecording() // Start new recording after error
            }
            return
        }
        authService.getIdToken { [weak self] idToken in
            guard let self = self, let idToken = idToken else {
                DispatchQueue.main.async {
                    self?.lastError = "Authorization failed: No idToken"
                    self?.isProcessingRecording = false
                }
                return
            }
            print("Sending audio file of size: \(audioData.count) bytes")
            let boundary = "Boundary-\(UUID().uuidString)"
            var request = URLRequest(url: URL(string: self.apiUrl)!)
            request.httpMethod = "POST"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
            var body = Data()
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"recording.m4a\"\r\n".data(using: .utf8)!)
            body.append("\r\n".data(using: .utf8)!)
            body.append(audioData)
            body.append("\r\n".data(using: .utf8)!)
            body.append("--\(boundary)--\r\n".data(using: .utf8)!)
            let task = URLSession.shared.uploadTask(with: request, from: body) { [weak self] data, response, error in
                if let error = error {
                    print("Error sending audio: \(error)")
                    DispatchQueue.main.async {
                        self?.lastError = "Failed to send audio: \(error.localizedDescription)"
                        self?.isProcessingRecording = false
                        if self?.isRecording == true {
                            self?.startRecording() // Начинаем новую запись после ошибки
                        }
                    }
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("Server response status code: \(httpResponse.statusCode)")
                    if let headers = httpResponse.allHeaderFields as? [String: String] {
                        print("Response headers: \(headers)")
                    }
                }
                
                if let data = data {
                    print("Received response data: \(String(data: data, encoding: .utf8) ?? "No data")")
                    if let transcription = String(data: data, encoding: .utf8) {
                        DispatchQueue.main.async {
                            self?.lastTranscription = transcription
                            let newTranscription = Transcription(text: transcription)
                            self?.transcriptionService.addTranscription(newTranscription)
                            // Получаем фидбэк от GPT
                            self?.gptService.getFeedback(for: transcription) { [weak self] feedback in
                                self?.transcriptionService.updateFeedback(for: newTranscription.id, feedback: feedback)
                            }
                        }
                    }
                }
                
                try? FileManager.default.removeItem(at: audioFileURL)
                
                DispatchQueue.main.async {
                    self?.isProcessingRecording = false
                    if self?.isRecording == true {
                        self?.startRecording() // Начинаем новую запись после успешной обработки
                    }
                }
            }
            task.resume()
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    func stopAll() {
        if isRecording {
            audioRecorder?.stop()
            recordingTimer?.invalidate()
            recordingTimer = nil
            return
        }
        DispatchQueue.main.async { [weak self] in
            self?.isRecording = false
            self?.currentRecordingTime = 0
        }
    }
}

extension AudioService: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        print("Recording finished successfully: \(flag)")
        if !flag {
            DispatchQueue.main.async { [weak self] in
                self?.lastError = "Recording failed to complete"
                self?.isProcessingRecording = false
                if self?.isRecording == true {
                    self?.startRecording() // Начинаем новую запись после ошибки
                }
            }
            return
        }
        
        if let url = currentRecordingURL {
            print("Sending file after recording completion: \(url.path)")
            sendAudioToServer(audioFileURL: url)
        }
    }
} 
 