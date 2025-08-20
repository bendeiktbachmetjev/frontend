import Foundation

struct RAGTestResult {
    let query: String
    let snippets: [RAGSnippet]
    let sources: [String]
    let timestamp: Date
}

struct RAGSnippet {
    let title: String
    let content: String
    let source: String
    let score: Double
}

class RAGTestService: ObservableObject {
    // Use Railway URL in production, localhost for development
    private var baseURL: String {
        // Check if custom URL is set in UserDefaults
        if let customURL = UserDefaults.standard.string(forKey: "RAG_API_BASE_URL") {
            return customURL
        }
        
        #if DEBUG
        // Development: use local IP for iOS Simulator
        return "http://192.168.1.83:8000"
        #else
        // Production: use Railway URL - replace with your actual Railway URL
        return "https://your-railway-app-name.up.railway.app"
        #endif
    }
    
    @Published var isLoading = false
    @Published var lastError: String = ""
    @Published var lastResult: RAGTestResult?
    
    func testRAGSearch(query: String, completion: @escaping (RAGTestResult?) -> Void) {
        isLoading = true
        lastError = ""
        
        // Create a simple test request to the RAG system
        let requestBody: [String: Any] = [
            "query": query,
            "top_k": 3,
            "include_sources": true
        ]
        
        guard let url = URL(string: "\(baseURL)/api/rag/test/dev") else {
            lastError = "Invalid API URL"
            isLoading = false
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authorization header if needed
        if let token = UserDefaults.standard.string(forKey: "firebase_id_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            lastError = "Failed to create request: \(error.localizedDescription)"
            isLoading = false
            completion(nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.lastError = "API request failed: \(error.localizedDescription)"
                    completion(nil)
                    return
                }
                
                guard let data = data else {
                    self?.lastError = "No data received from API"
                    completion(nil)
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        let result = self?.parseRAGResponse(json: json, query: query)
                        self?.lastResult = result
                        completion(result)
                    } else {
                        self?.lastError = "Invalid API response format"
                        completion(nil)
                    }
                } catch {
                    self?.lastError = "Failed to parse API response: \(error.localizedDescription)"
                    completion(nil)
                }
            }
        }
        
        task.resume()
    }
    
    private func parseRAGResponse(json: [String: Any], query: String) -> RAGTestResult? {
        guard let snippets = json["snippets"] as? [[String: Any]] else {
            return nil
        }
        
        let ragSnippets = snippets.compactMap { snippet -> RAGSnippet? in
            guard let title = snippet["title"] as? String,
                  let content = snippet["content"] as? String,
                  let source = snippet["source"] as? String,
                  let score = snippet["score"] as? Double else {
                return nil
            }
            
            return RAGSnippet(title: title, content: content, source: source, score: score)
        }
        
        let sources = Array(Set(ragSnippets.map { $0.source }))
        
        return RAGTestResult(
            query: query,
            snippets: ragSnippets,
            sources: sources,
            timestamp: Date()
        )
    }
    
    // Fallback method for testing when API is not available
    func testRAGSearchMock(query: String, completion: @escaping (RAGTestResult?) -> Void) {
        isLoading = true
        
        // Simulate API delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.isLoading = false
            
            let mockSnippets = [
                RAGSnippet(
                    title: "Coaching Techniques",
                    content: "Effective coaching involves active listening and asking powerful questions that help clients discover their own solutions.",
                    source: "Coaching Handbook 2023",
                    score: 0.95
                ),
                RAGSnippet(
                    title: "Goal Setting",
                    content: "SMART goals are Specific, Measurable, Achievable, Relevant, and Time-bound. This framework helps ensure goals are clear and attainable.",
                    source: "Goal Setting Guide",
                    score: 0.87
                ),
                RAGSnippet(
                    title: "Communication Skills",
                    content: "Non-verbal communication accounts for 55% of how we convey meaning. Pay attention to body language and tone of voice.",
                    source: "Communication Best Practices",
                    score: 0.82
                )
            ]
            
            let result = RAGTestResult(
                query: query,
                snippets: mockSnippets,
                sources: ["Coaching Handbook 2023", "Goal Setting Guide", "Communication Best Practices"],
                timestamp: Date()
            )
            
            self?.lastResult = result
            completion(result)
        }
    }
}
