import SwiftUI

struct ArchiveView: View {
    @StateObject private var transcriptionService = TranscriptionService()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Archive")
                    .font(.largeTitle.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                
                // Transcriptions Section
                TranscriptionList(transcriptionService: transcriptionService)
                    .background(Color(UIColor.systemGroupedBackground))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                
                Spacer()
            }
            .padding(.top, 16)
        }
        .background(Color.white) // Белый фон для всего экрана
    }
} 