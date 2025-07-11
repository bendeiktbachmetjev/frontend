import SwiftUI
import Foundation

struct OnboardingMessage: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var text: String
    var isUser: Bool
}

/// Chat view for onboarding with the coach agent.
/// Displays message history, input field, send button, and progress indicator.
/// AuthService is injected via OnboardingManager for backend authorization.
struct OnboardingChatView: View {
    @ObservedObject var manager: OnboardingManager
    @State private var inputText: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var messages: [OnboardingMessage] = [] // (text, isUser)
    private let saveKey = "onboardingChatHistory"
    @State private var showStateModal: Bool = false // Controls state modal visibility
    @State private var isStateLoading: Bool = false // Controls loading indicator for state modal
    @State private var latestState: [String: Any]? = nil // Stores the latest fetched state for modal
    @State private var lastSessionID: String? = nil

    private var shouldDisableInput: Bool {
        manager.phase == "week1"
    }

    private func saveKey(for sessionID: String?) -> String {
        guard let sessionID = sessionID else { return "onboardingChatHistory_noSession" }
        return "onboardingChatHistory_\(sessionID)"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Chat header with avatar, mentor label, and info button
            HStack(spacing: 12) {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 36, height: 36)
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text("Mentor")
                        .font(.headline)
                    Text("You are chatting with your mentor")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
                // Info button to show state
                Button(action: {
                    isStateLoading = true
                    showStateModal = true
                    manager.fetchSessionState { success in
                        isStateLoading = false
                        if success {
                            latestState = manager.sessionState
                        } else {
                            latestState = ["error": "Failed to fetch state"]
                        }
                    }
                }) {
                    Image(systemName: "info.circle")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.blue)
                        .accessibilityLabel("Show State")
                }
            }
            .padding([.top, .horizontal])
            .padding(.bottom, 8)

            Divider()

            // Chat history
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(messages.indices, id: \.self) { idx in
                            let msg = messages[idx]
                            ChatMessageView(text: msg.text, isUser: msg.isUser)
                        }
                        // Show typing indicator if waiting for mentor's reply
                        if isLoading {
                            TypingIndicatorView()
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) { _ in
                    withAnimation { proxy.scrollTo(messages.count - 1, anchor: .bottom) }
                }
            }

            // Show error if any
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }

            // Input field and send button
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                        .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
                    HStack {
                        TextField("Type your message...", text: $inputText)
                            .padding(.vertical, 12)
                            .padding(.leading, 18)
                            .padding(.trailing, 8)
                            .disabled(isLoading || shouldDisableInput)
                            .foregroundColor(.primary)
                        Button(action: sendMessage) {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading || shouldDisableInput ? .gray : .blue)
                                .frame(width: 28, height: 28)
                        }
                        .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading || shouldDisableInput)
                        .padding(.trailing, 8)
                    }
                }
                .frame(height: 44)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .onAppear(perform: setup)
        .onChange(of: messages) { _ in
            saveMessages()
        }
        .onChange(of: manager.sessionID) { newSessionID in
            loadMessages(for: newSessionID)
        }
        .navigationBarTitle("Onboarding", displayMode: .inline)
        .background(Color(.systemBackground))
        .sheet(isPresented: $showStateModal) {
            StateModalView(state: latestState, isLoading: isStateLoading, dismiss: { showStateModal = false })
        }
    }

    /// Helper to pretty-print JSON
    private func jsonString(from dict: [String: Any]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted),
              let str = String(data: data, encoding: .utf8) else { return "{}" }
        return str
    }

    /// Initial setup: fetch state and optionally load previous messages.
    private func setup() {
        loadMessages(for: manager.sessionID)
        if messages.isEmpty {
            messages.append(OnboardingMessage(text: "Hi there! 👋 This is your onboarding chat. Feel free to introduce yourself. May I ask your name?", isUser: false))
        }
        if manager.sessionID == nil {
            isLoading = true
            manager.createSession { success in
                isLoading = false
                if !success {
                    errorMessage = "Failed to create session. Please try again."
                } else {
                    fetchState()
                }
            }
        } else {
            fetchState()
        }
    }

    private func loadMessages(for sessionID: String?) {
        let key = saveKey(for: sessionID)
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([OnboardingMessage].self, from: data) {
            messages = decoded
        } else {
            messages = []
        }
    }

    /// Fetches the current session state and updates phase.
    private func fetchState() {
        isLoading = true
        manager.fetchSessionState { success in
            isLoading = false
            if !success {
                errorMessage = "Failed to fetch session state."
            } else {
                errorMessage = nil
                // Restore chat history from sessionState if available
                if let messagesArray = manager.sessionState["messages"] as? [[String: Any]] {
                    messages = messagesArray.compactMap { dict in
                        guard let text = dict["text"] as? String else { return nil }
                        // Try to detect user/mentor by 'is_user' (Bool) or 'role' (String)
                        if let isUser = dict["is_user"] as? Bool {
                            return OnboardingMessage(text: text, isUser: isUser)
                        } else if let role = dict["role"] as? String {
                            return OnboardingMessage(text: text, isUser: (role == "user"))
                        } else {
                            return OnboardingMessage(text: text, isUser: false) // Default to mentor
                        }
                    }
                }
            }
        }
    }

    /// Sends a message to the coach agent.
    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        messages.append(OnboardingMessage(text: text, isUser: true))
        inputText = ""
        isLoading = true
        errorMessage = nil
        manager.sendMessage(text) { reply in
            isLoading = false
            if let reply = reply {
                messages.append(OnboardingMessage(text: reply, isUser: false))
            } else {
                errorMessage = "Failed to send message."
            }
        }
    }

    /// Manually refreshes session state from backend
    private func refreshState() {
        isLoading = true
        manager.fetchSessionState { success in
            isLoading = false
            if !success {
                errorMessage = "Failed to fetch session state."
            } else {
                errorMessage = nil
            }
        }
    }

    private func saveMessages() {
        let key = saveKey(for: manager.sessionID)
        if let encoded = try? JSONEncoder().encode(messages) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }

    private func clearLocalHistory() {
        UserDefaults.standard.removeObject(forKey: saveKey)
    }
}

// Chat message bubble with sender label and avatar
struct ChatMessageView: View {
    let text: String
    let isUser: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if !isUser {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 28, height: 28)
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            } else {
                Spacer(minLength: 0)
            }
            VStack(alignment: isUser ? .trailing : .leading, spacing: 2) {
                HStack {
                    if isUser {
                        Spacer()
                    }
                    Text(text)
                        .padding(12)
                        .background(isUser ? Color.blue.opacity(0.15) : Color.gray.opacity(0.1))
                        .cornerRadius(16)
                        .frame(maxWidth: 260, alignment: isUser ? .trailing : .leading)
                    if !isUser {
                        Spacer()
                    }
                }
                Text(isUser ? "You" : "Mentor")
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(isUser ? .trailing : .leading, 8)
            }
            if isUser {
                Image(systemName: "person.crop.circle")
                    .resizable()
                    .frame(width: 28, height: 28)
                    .foregroundColor(.gray)
            } else {
                Spacer(minLength: 0)
            }
        }
        .padding(isUser ? .leading : .trailing, 40)
        .padding(.vertical, 2)
    }
}

// Typing indicator bubble with animated three dots, styled like iMessage
struct TypingIndicatorView: View {
    @State private var animate = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .frame(width: 28, height: 28)
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.gray.opacity(0.1))
                HStack(spacing: 4) {
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 8, height: 8)
                            .scaleEffect(animate ? 1 : 0.5)
                            .opacity(animate ? 1 : 0.5)
                            .animation(
                                Animation.easeInOut(duration: 0.6)
                                    .repeatForever()
                                    .delay(Double(i) * 0.2),
                                value: animate
                            )
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            }
            .frame(maxWidth: 60)
            Spacer(minLength: 0)
        }
        .padding(.trailing, 40)
        .padding(.vertical, 2)
        .onAppear { animate = true }
    }
}

// Add StateModalView for displaying state as pretty-printed JSON
struct StateModalView: View {
    let state: [String: Any]?
    let isLoading: Bool
    let dismiss: () -> Void

    var body: some View {
        NavigationView {
            ScrollView {
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Loading state...")
                            .foregroundColor(.gray)
                    }
                    .padding()
                } else {
                    Text(jsonString(from: state ?? [:]))
                        .font(.system(.body, design: .monospaced))
                        .padding()
                }
            }
            .navigationTitle("Session State")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
    // Helper to pretty-print JSON
    private func jsonString(from dict: [String: Any]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted),
              let str = String(data: data, encoding: .utf8) else { return "{}" }
        return str
    }
}

// Preview for SwiftUI canvas
struct OnboardingChatView_Previews: PreviewProvider {
    static var previews: some View {
        let authService = AuthService()
        OnboardingChatView(manager: OnboardingManager(authService: authService))
    }
} 