import SwiftUI

struct DashboardStatsView: View {
    let stats: [Date: Int] // Number of transcriptions per day
    @ObservedObject var transcriptionService: TranscriptionService
    
    var lastTranscription: Transcription? {
        transcriptionService.transcriptions.first
    }

    var body: some View {
        ZStack {
            // Белый фон для секции Statistics
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
            
            VStack(alignment: .leading, spacing: 24) {
                // Title
                Text("Statistics")
                    .font(.title2.bold())
                    .foregroundColor(.primary)
                
                // Info about quantity
                HStack(spacing: 20) {
                    StatInfoCard(
                        title: "Sessions",
                        value: "\(stats.count)",
                        icon: "calendar",
                        color: .blue
                    )
                    
                    StatInfoCard(
                        title: "Transcriptions",
                        value: "\(stats.values.reduce(0, +))",
                        icon: "text.bubble",
                        color: .purple
                    )
                }
                
                // Last transcription and feedback
                if let last = lastTranscription {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Last Activity")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "text.quote")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                                    .frame(width: 28, height: 28)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.green)
                                    )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Transcription")
                                        .font(.subheadline.bold())
                                        .foregroundColor(.secondary)
                                    
                                    Text(last.text)
                                        .font(.title3)
                                        .foregroundColor(.primary)
                                        .lineLimit(2)
                                }
                            }
                            
                            if !last.feedback.isEmpty {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "person.fill.checkmark")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                        .frame(width: 28, height: 28)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.blue)
                                        )
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Coach Feedback")
                                            .font(.subheadline.bold())
                                            .foregroundColor(.secondary)
                                        
                                        Text(last.feedback)
                                            .font(.body.bold())
                                            .foregroundColor(.primary)
                                            .lineLimit(3)
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white) // Белый фон для карточки последней транскрипции
                        )
                    }
                } else {
                    // If no activity - show placeholder
                    VStack(spacing: 12) {
                        Image(systemName: "waveform")
                            .font(.system(size: 32))
                            .foregroundColor(.gray)
                        
                        Text("No activity yet")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("Start recording to see your transcriptions and feedback")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(height: 150)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(24)
        }
        .padding(.horizontal, 16)
    }

    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }
}

struct StatInfoCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(color)
                    )
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
        )
    }
}

#Preview {
    DashboardStatsView(
        stats: [
            Calendar.current.date(byAdding: .day, value: -3, to: Date())!: 2,
            Calendar.current.date(byAdding: .day, value: -2, to: Date())!: 3,
            Calendar.current.date(byAdding: .day, value: -1, to: Date())!: 1,
            Date(): 4
        ],
        transcriptionService: {
            let service = TranscriptionService()
            service.addTranscription(Transcription(text: "This is a sample transcription text for testing purposes.", feedback: "Speak more clearly and try to maintain a steady pace."))
            return service
        }()
    )
} 