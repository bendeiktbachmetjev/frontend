import Foundation

/// Chat message model for chat views (CoachChatView, etc.)
struct Message: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var content: String
    var isFromUser: Bool
    var timestamp: Date
    
    init(id: UUID = UUID(), content: String, isFromUser: Bool, timestamp: Date) {
        self.id = id
        self.content = content
        self.isFromUser = isFromUser
        self.timestamp = timestamp
    }
} 