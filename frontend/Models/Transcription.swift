import Foundation

struct Transcription: Identifiable, Codable {
    let id: UUID
    let text: String
    let feedback: String
    let timestamp: Date
    
    init(text: String, feedback: String = "") {
        self.id = UUID()
        self.text = text
        self.feedback = feedback
        self.timestamp = Date()
    }
} 