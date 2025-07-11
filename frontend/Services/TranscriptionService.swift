import Foundation

class TranscriptionService: ObservableObject {
    @Published var transcriptions: [Transcription] = []
    private let saveKey = "savedTranscriptions"
    
    init() {
        loadTranscriptions()
    }
    
    func addTranscription(_ transcription: Transcription) {
        transcriptions.insert(transcription, at: 0)
        saveTranscriptions()
    }
    
    func updateFeedback(for transcriptionId: UUID, feedback: String) {
        if let index = transcriptions.firstIndex(where: { $0.id == transcriptionId }) {
            let updatedTranscription = Transcription(
                text: transcriptions[index].text,
                feedback: feedback
            )
            transcriptions[index] = updatedTranscription
            saveTranscriptions()
        }
    }
    
    private func saveTranscriptions() {
        if let encoded = try? JSONEncoder().encode(transcriptions) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func loadTranscriptions() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Transcription].self, from: data) {
            transcriptions = decoded
        }
    }
} 