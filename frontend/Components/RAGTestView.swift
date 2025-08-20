import SwiftUI

struct RAGTestView: View {
    @StateObject private var ragService = RAGTestService()
    @State private var searchQuery = ""
    @State private var showingResults = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.blue)
                Text("RAG Knowledge Test")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 16)
            
            // Search input
            VStack(spacing: 8) {
                TextField("Enter search query (e.g., 'coaching techniques', 'goal setting')", text: $searchQuery)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal, 16)
                
                HStack {
                    Button(action: {
                        performSearch()
                    }) {
                        HStack {
                            if ragService.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "magnifyingglass")
                            }
                            Text("Search Knowledge Base")
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                    .disabled(searchQuery.isEmpty || ragService.isLoading)
                    
                    Button(action: {
                        performMockSearch()
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Test Mock")
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .cornerRadius(8)
                    }
                    .disabled(ragService.isLoading)
                }
                .padding(.horizontal, 16)
            }
            
            // Error display
            if !ragService.lastError.isEmpty {
                Text(ragService.lastError)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal, 16)
            }
            
            // Results
            if let result = ragService.lastResult {
                ScrollView {
                    VStack(spacing: 16) {
                        // Query info
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Query: \(result.query)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            Text("Found \(result.snippets.count) snippets from \(result.sources.count) sources")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text("Timestamp: \(formatDate(result.timestamp))")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 16)
                        
                        // Snippets
                        ForEach(Array(result.snippets.enumerated()), id: \.offset) { index, snippet in
                            RAGSnippetView(snippet: snippet, index: index + 1)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 16)
    }
    
    private func performSearch() {
        guard !searchQuery.isEmpty else { return }
        
        ragService.testRAGSearch(query: searchQuery) { result in
            // Result is handled by the @Published property
        }
    }
    
    private func performMockSearch() {
        let mockQuery = searchQuery.isEmpty ? "coaching techniques" : searchQuery
        ragService.testRAGSearchMock(query: mockQuery) { result in
            // Result is handled by the @Published property
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}

struct RAGSnippetView: View {
    let snippet: RAGSnippet
    let index: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("#\(index)")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue)
                    .cornerRadius(4)
                
                Text(snippet.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Spacer()
                
                Text(String(format: "%.2f", snippet.score))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Text(snippet.content)
                .font(.body)
                .lineLimit(4)
                .multilineTextAlignment(.leading)
            
            HStack {
                Image(systemName: "doc.text")
                    .foregroundColor(.gray)
                Text(snippet.source)
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }
}

#Preview {
    RAGTestView()
}
