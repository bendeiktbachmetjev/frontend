import SwiftUI

struct DashboardView: View {
    @StateObject private var transcriptionService = TranscriptionService()
    let authService: AuthService
    
    private func statsByDay() -> [Date: Int] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: transcriptionService.transcriptions) { transcript in
            calendar.startOfDay(for: transcript.timestamp)
        }
        return grouped.mapValues { $0.count }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                // Pass transcriptionService and authService to the recording section
                RecordingToggleSection(transcriptionService: transcriptionService, authService: authService)
                
                // And to statistics
                DashboardStatsView(
                    stats: statsByDay(),
                    transcriptionService: transcriptionService
                )
                
                // Add space at the bottom for floating elements
                Spacer()
                    .frame(height: 140)
            }
            .padding(.top, 16)
        }
        .background(Color.white) // Белый фон для всего экрана
    }
}

#Preview {
    // For preview, use a dummy auth service
    DashboardView(authService: AuthService())
}
