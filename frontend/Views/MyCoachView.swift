import SwiftUI

struct MyCoachView: View {
    @StateObject private var transcriptionService = TranscriptionService()
    @StateObject private var courseService = CourseService()
    /// Onboarding manager for controlling onboarding state and phase
    @ObservedObject var onboardingManager: OnboardingManager
    let authService: AuthService
    @State private var showOnboarding = false
    @State private var isLoadingState = false
    @State private var showStateAlert = false
    
    init(onboardingManager: OnboardingManager, authService: AuthService) {
        self.onboardingManager = onboardingManager
        self.authService = authService
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                if isLoadingState {
                    ProgressView("Loading your coach...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if onboardingManager.isOnboardingComplete {
                    // Get topics from state.plan
                    let plan = onboardingManager.sessionState["plan"] as? [String: Any] ?? [:]
                    let topics = (1...12).map { week in
                        plan["week_\(week)_topic"] as? String ?? "No topic"
                    }
                    ScrollView {
                        VStack(spacing: 24) {
                            // Coach profile
                            CoachProfileSection()
                            // Course structure with coach chat support (goal теперь передаётся внутрь)
                            let goalsArray = onboardingManager.sessionState["goals"] as? [String] ?? []
                            let goal = goalsArray.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                            CourseStructureSection(
                                courseName: courseService.courseName,
                                progress: courseService.progress,
                                units: courseService.courseUnits,
                                topics: topics,
                                goal: goal.isEmpty ? "Your goal is to find new goals" : goal,
                                onboardingManager: onboardingManager // Новый проп
                            )
                            // Button to start a new onboarding session, right after topics
                            if !showOnboarding {
                                Button(action: {
                                    onboardingManager.clearSession()
                                    onboardingManager.createSession { _ in }
                                }) {
                                    Text("Start New Session")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .padding(.horizontal, 40)
                            }
                            // Button to show current session state as JSON
                            if !showOnboarding {
                                Button(action: {
                                    showStateAlert = true
                                }) {
                                    Text("Show State")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .padding(.horizontal, 40)
                                .alert(isPresented: $showStateAlert) {
                                    Alert(
                                        title: Text("Session State"),
                                        message: Text(jsonString(from: onboardingManager.sessionState)),
                                        dismissButton: .default(Text("OK"))
                                    )
                                }
                            }
                            // Space for fixed elements at the bottom
                            Spacer(minLength: 140)
                        }
                        .padding(.top, 16)
                    }
                    .background(Color.white) // Белый фон для всего экрана
                } else {
                    // Onboarding stub overlay
                    VStack(spacing: 28) {
                        Spacer()
                        Text("To access your coach, please complete onboarding first.")
                            .multilineTextAlignment(.center)
                            .font(.title.bold())
                            .foregroundColor(.primary)
                            .padding(.horizontal, 32)
                        HStack(spacing: 18) {
                            Button(action: { showOnboarding = true }) {
                                Text("Start Onboarding")
                                    .font(.headline.weight(.semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, minHeight: 52)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(18)
                            }
                            Button(action: { onboardingManager.clearSession() }) {
                                Text("Cancel Session")
                                    .font(.headline.weight(.semibold))
                                    .foregroundColor(.blue)
                                    .frame(maxWidth: .infinity, minHeight: 52)
                                    .background(
                                        RoundedRectangle(cornerRadius: 18)
                                            .stroke(LinearGradient(
                                                gradient: Gradient(colors: [Color.blue, Color.purple]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            ), lineWidth: 2)
                                    )
                            }
                        }
                        .padding(.horizontal, 32)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground).opacity(0.98))
                }
            }
        }
        .sheet(isPresented: $showOnboarding, onDismiss: {
            onboardingManager.fetchSessionState { _ in }
        }) {
            OnboardingChatView(manager: onboardingManager)
        }
        .onAppear {
            if !onboardingManager.isOnboardingComplete {
                isLoadingState = true
                onboardingManager.fetchSessionState { _ in
                    isLoadingState = false
                }
            }
        }
        .background(Color.white) // Белый фон для всего экрана
    }
    
    private func jsonString(from dict: [String: Any]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted),
              let str = String(data: data, encoding: .utf8) else { return "{}" }
        return str
    }
}

// Extension for rounding only specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

#Preview {
    // For preview, use a dummy onboarding manager and auth service
    let authService = AuthService()
    MyCoachView(onboardingManager: OnboardingManager(authService: authService), authService: authService)
} 