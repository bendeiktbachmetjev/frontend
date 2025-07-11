import SwiftUI

struct TranscriptionList: View {
    @ObservedObject var transcriptionService: TranscriptionService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Transcriptions")
                .font(.headline)
                .foregroundColor(.gray)
            
            if transcriptionService.transcriptions.isEmpty {
                Text("No transcriptions yet")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(transcriptionService.transcriptions) { transcription in
                            TranscriptionCard(transcription: transcription)
                        }
                    }
                }
            }
        }
        .padding()
    }
}

struct TranscriptionCard: View {
    let transcription: Transcription
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(transcription.text)
                .font(.body)
            
            if !transcription.feedback.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Coach Feedback:")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Text(transcription.feedback)
                        .font(.caption2)
                        .foregroundColor(.primary)
                }
                .padding(.top, 4)
            }

            Text(transcription.timestamp, style: .time)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.systemGroupedBackground))
        .cornerRadius(12)
    }
}

#Preview {
    TranscriptionList(transcriptionService: TranscriptionService())
} 