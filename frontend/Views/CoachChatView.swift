import SwiftUI
import Foundation
// import Models // Раскомментируйте, если требуется явный импорт Models
import Combine

struct WeekChatView: View {
    let unitTitle: String
    @ObservedObject var onboardingManager: OnboardingManager
    @Environment(\.presentationMode) var presentationMode
    @State private var inputText: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var messages: [Message] = []
    @State private var scrollToBottom: Bool = false
    @StateObject private var keyboard = KeyboardResponder()
    @State private var lastSessionID: String? = nil

    private func saveKey(for sessionID: String?) -> String {
        guard let sessionID = sessionID else { return "coachChatHistory_noSession" }
        return "coachChatHistory_\(sessionID)"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .center, spacing: 12) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.12))
                                .frame(width: 36, height: 36)
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.blue)
                        }
                        Text("Back")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                    .padding(.leading, 2)
                    .contentShape(Rectangle())
                }
                Spacer(minLength: 0)
                HStack(spacing: 10) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Coach")
                    .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        Text("You are chatting with your coach")
                    .font(.caption)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
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
                            ChatMessageBubble(text: msg.content, isUser: msg.isFromUser)
                        }
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
            // Error message
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
                            .disabled(isLoading)
                            .foregroundColor(.primary)
                        Button(action: sendMessage) {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading ? .gray : .blue)
                                .frame(width: 28, height: 28)
                        }
                        .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                        .padding(.trailing, 8)
                    }
                }
                .frame(height: 44)
        }
        .padding(.horizontal)
            .padding(.bottom, keyboard.currentHeight > 0 ? keyboard.currentHeight + 16 : 32)
        }
        .onAppear(perform: setup)
        .onChange(of: messages) { _ in
            saveMessages()
        }
        .onChange(of: onboardingManager.sessionID) { newSessionID in
            loadMessages(for: newSessionID)
        }
        .background(Color(.systemBackground))
        .navigationBarHidden(true)
        .edgesIgnoringSafeArea(.bottom)
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    private func setup() {
        loadMessages(for: onboardingManager.sessionID)
        if messages.isEmpty {
            // Send greeting only if chat is empty and no saved history
            isLoading = true
            onboardingManager.sendMessage("Hi") { reply in
                isLoading = false
                if let reply = reply {
                    let coachMessage = Message(content: reply, isFromUser: false, timestamp: Date())
                    messages.append(coachMessage)
                }
            }
        }
    }

    private func loadMessages(for sessionID: String?) {
        let key = saveKey(for: sessionID)
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([Message].self, from: data) {
            messages = decoded
        } else {
            messages = []
        }
    }

    private func saveMessages() {
        let key = saveKey(for: onboardingManager.sessionID)
        if let encoded = try? JSONEncoder().encode(messages) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
    
    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        let userMessage = Message(content: text, isFromUser: true, timestamp: Date())
        messages.append(userMessage)
        inputText = ""
        isLoading = true
        errorMessage = nil
        onboardingManager.sendMessage(text) { reply in
            isLoading = false
            if let reply = reply {
                let coachMessage = Message(content: reply, isFromUser: false, timestamp: Date())
        messages.append(coachMessage)
            } else {
                errorMessage = "Failed to send message."
            }
        }
    }
    
    private func loadMessagesFromState() {
        if let messagesArray = onboardingManager.sessionState["messages"] as? [[String: Any]] {
            let loaded = messagesArray.compactMap { dict -> Message? in
                guard let text = dict["text"] as? String else { return nil }
                let isUser: Bool
                if let isUserVal = dict["is_user"] as? Bool {
                    isUser = isUserVal
                } else if let role = dict["role"] as? String {
                    isUser = (role == "user")
                } else {
                    isUser = false
                }
                return Message(content: text, isFromUser: isUser, timestamp: Date())
            }
            if !loaded.isEmpty {
                messages = loaded
            }
        }
    }
}

// Message bubble styled like OnboardingChatView
struct ChatMessageBubble: View {
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
                Text(isUser ? "You" : "Coach")
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

// Keyboard responder for lifting input above keyboard
class KeyboardResponder: ObservableObject {
    @Published var currentHeight: CGFloat = 0
    private var cancellable: AnyCancellable?
    init() {
        cancellable = NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
            .merge(with: NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification))
            .sink { notification in
                if let value = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    let screenHeight = UIScreen.main.bounds.height
                    let keyboardTop = value.origin.y
                    if keyboardTop >= screenHeight {
                        self.currentHeight = 0
                    } else {
                        self.currentHeight = screenHeight - keyboardTop
                    }
                } else {
                    self.currentHeight = 0
                }
            }
    }
    deinit {
        cancellable?.cancel()
    }
}


