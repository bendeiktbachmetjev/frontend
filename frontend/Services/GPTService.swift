import Foundation

class GPTService: ObservableObject {
    private let apiKey: String
    private let apiUrl = "https://api.openai.com/v1/chat/completions"
    
    @Published var lastFeedback: String = ""
    @Published var lastError: String = ""
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func getFeedback(for transcription: String, completion: @escaping (String) -> Void) {
        let prompt = """
        First, check if the speech contains any references to suicide, self-harm, or thoughts of ending life. If it does, immediately respond with: "You are not alone, you matter, and support is available—please reach out."

        If no such references are found, continue with the following analysis:

        You are MentorAI, a 24/7 virtual coach that silently listens to the user's everyday conversations with others (e.g., colleagues) and sends ultra-concise feedback as phone notifications.  
        Examples (Few-Shot):   
        Conversation: "You're all idiots! I hate you all!"  
        Notification:  
        • "Insight: Your tone felt harsh."  
        • "Action: Pause and choose kinder words."  
        
        Conversation: "This is so stupid!"  
        Notification:  
        • "Insight: Frustration surfaced strongly."  
        • "Action: Breathe, then offer a constructive request."  
        Steps to follow: 
        1. Read the user's latest snippet within the delimiters.  
        2. Identify the core emotion or behavior directed at others.  
        3. Craft exactly two bullets:  
        – First bullet = concise insight or observation.  
        – Second bullet = actionable, behavior-focused tip.  
        4. Confirm both bullets reference the user's exact wording or topic.  
        5. Ensure compliance with all constraints before sending.  
        Constraints:  
        - Each bullet ≤ 12 words.  
        - Always reference the user's recent conversation.  
        - Maintain a positive, constructive tone.  
        Output Format (exactly):  
        • <Insight>  
        • <Action>     
        
        Speech: \(transcription)
        """
        
        let requestBody: [String: Any] = [
            "model": "gpt-4",
            "messages": [
                ["role": "system", "content": "You are a professional speech coach providing constructive feedback."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7,
            "top_p": 0.9
        ]
        
        guard let url = URL(string: apiUrl) else {
            lastError = "Invalid API URL"
            completion("")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            lastError = "Failed to create request: \(error.localizedDescription)"
            completion("")
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.lastError = "API request failed: \(error.localizedDescription)"
                    completion("")
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    self?.lastError = "No data received from API"
                    completion("")
                }
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    DispatchQueue.main.async {
                        self?.lastFeedback = content
                        completion(content)
                    }
                } else {
                    DispatchQueue.main.async {
                        self?.lastError = "Invalid API response format"
                        completion("")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self?.lastError = "Failed to parse API response: \(error.localizedDescription)"
                    completion("")
                }
            }
        }
        
        task.resume()
    }
}
