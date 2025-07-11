import SwiftUI

struct RecordingToggleSection: View {
    @ObservedObject var transcriptionService: TranscriptionService
    let authService: AuthService
    @StateObject private var audioService: AudioService

    init(transcriptionService: TranscriptionService, authService: AuthService) {
        // TODO: Insert your OpenAI API key securely, e.g., from environment or secure storage
        let gptService = GPTService(apiKey: "")
        _audioService = StateObject(wrappedValue: AudioService(transcriptionService: transcriptionService, gptService: gptService, authService: authService))
        self.transcriptionService = transcriptionService
        self.authService = authService
    }
    
    var body: some View {
        ZStack {
            // Glassmorphism background
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
            
            VStack(spacing: 20) {
                HStack {
                    Image(systemName: audioService.isRecording ? "mic.fill" : "mic.slash")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(audioService.isRecording ? .red : .gray)
                        .padding(.trailing, 8)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(audioService.isRecording ? "Recording..." : "OFF")
                            .font(.headline)
                            .foregroundColor(.primary)
                        if audioService.isRecording {
                            Text("\(Int(audioService.currentRecordingTime))s")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        } else {
                            Text("Tap to enable recording")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                    Spacer()
                    // Toggle
                    Toggle(isOn: Binding(
                        get: { audioService.isRecording },
                        set: { isOn in
                            audioService.toggleRecording()
                        })
                    ) {
                        EmptyView()
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Color.blue.opacity(0.7)))
                    .frame(width: 60)
                }
                .padding(.horizontal, 8)
                
                if audioService.isBluetoothAvailable {
                    HStack(spacing: 6) {
                        Image(systemName: "dot.radiowaves.left.and.right")
                            .foregroundColor(.blue)
                        Text("Bluetooth mic available")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
                
                if !audioService.lastError.isEmpty {
                    Text(audioService.lastError)
                        .font(.caption2)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
            }
            .padding(20)
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, minHeight: 120)
    }
}

#Preview {
    RecordingToggleSection(transcriptionService: TranscriptionService(), authService: AuthService())
} 