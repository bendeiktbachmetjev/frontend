import Foundation
import Combine

/// Manages onboarding session state and API integration with LangGraph backend.
/// Handles session creation, message sending, state fetching, and onboarding completion logic.
class OnboardingManager: ObservableObject {
    /// The current session ID for the onboarding flow.
    @Published var sessionID: String?
    /// The current phase of the onboarding session (e.g., "incomplete", "plan_ready").
    @Published var phase: String = "incomplete"
    /// The full state object returned from the backend.
    @Published var sessionState: [String: Any] = [:]
    /// Indicates whether onboarding is complete (phase == "week1").
    var isOnboardingComplete: Bool { phase == "week1" }
    /// Indicates whether plan is ready (phase == "plan_ready").
    var isPlanReady: Bool { phase == "plan_ready" }
    /// Stores cancellables for Combine publishers.
    private var cancellables = Set<AnyCancellable>()
    /// UserDefaults key for session ID persistence.
    private let sessionIDKey = "onboarding_session_id"
    /// The base URL of the LangGraph backend.
    private let baseURL = "https://spotted-mom-production.up.railway.app"
    private let authService: AuthService

    init(authService: AuthService) {
        self.authService = authService
        loadSessionID()
    }

    /// Loads session ID from UserDefaults if available.
    private func loadSessionID() {
        if let savedID = UserDefaults.standard.string(forKey: sessionIDKey) {
            sessionID = savedID
        }
    }

    /// Saves session ID to UserDefaults.
    private func saveSessionID(_ id: String) {
        UserDefaults.standard.set(id, forKey: sessionIDKey)
    }

    /// Clears session ID from UserDefaults and resets state.
    func clearSession() {
        UserDefaults.standard.removeObject(forKey: sessionIDKey)
        sessionID = nil
        phase = "incomplete"
        sessionState = [:]
    }

    /// Creates a new onboarding session by calling the backend.
    func createSession(completion: @escaping (Bool) -> Void) {
        authService.getIdToken { [weak self] idToken in
            guard let self = self, let idToken = idToken,
                  let url = URL(string: "\(self.baseURL)/session") else {
                completion(false)
                return
            }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
            URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let sessionID = json["session_id"] as? String else {
                    DispatchQueue.main.async { completion(false) }
                    return
                }
                DispatchQueue.main.async {
                    self.sessionID = sessionID
                    self.saveSessionID(sessionID)
                    completion(true)
                }
            }.resume()
        }
    }

    /// Fetches the current session state and phase from the backend.
    func fetchSessionState(completion: @escaping (Bool) -> Void) {
        authService.getIdToken { [weak self] idToken in
            guard let self = self, let idToken = idToken, let sessionID = self.sessionID,
                  let url = URL(string: "\(self.baseURL)/state/\(sessionID)") else {
                completion(false)
                return
            }
            var request = URLRequest(url: url)
            request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
            URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let state = json["state"] as? [String: Any],
                      let phase = state["phase"] as? String else {
                    DispatchQueue.main.async { completion(false) }
                    return
                }
                DispatchQueue.main.async {
                    self.sessionState = state
                    self.phase = phase
                    completion(true)
                }
            }.resume()
        }
    }

    /// Sends a message to the onboarding chat and updates state.
    func sendMessage(_ message: String, completion: @escaping (String?) -> Void) {
        authService.getIdToken { [weak self] idToken in
            guard let self = self, let idToken = idToken, let sessionID = self.sessionID,
                  let url = URL(string: "\(self.baseURL)/chat/\(sessionID)") else {
                completion(nil)
                return
            }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
            let body: [String: Any] = ["message": message]
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let reply = json["reply"] as? String else {
                    DispatchQueue.main.async { completion(nil) }
                    return
                }
                // Update state and phase if present
                if let state = json["state"] as? [String: Any], let phase = state["phase"] as? String {
                    DispatchQueue.main.async {
                        self.sessionState = state
                        self.phase = phase
                        completion(reply)
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(reply)
                    }
                }
            }.resume()
        }
    }
} 