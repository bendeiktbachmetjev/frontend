import SwiftUI

struct ContentView: View {
    @StateObject private var authService = AuthService()
    @StateObject private var onboardingManager: OnboardingManager
    @State private var selectedTab = 0
    
    init() {
        let authService = AuthService()
        _authService = StateObject(wrappedValue: authService)
        _onboardingManager = StateObject(wrappedValue: OnboardingManager(authService: authService))
    }
    
    var body: some View {
        Group {
            if authService.isAuthenticated {
                VStack(spacing: 0) {
                    // Градиентный заголовок
                    Text("Mentor.ai")
                        .font(.largeTitle.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.top, 12)
                        .padding(.bottom, 4)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    ZStack(alignment: .bottom) {
                        TabView(selection: $selectedTab) {
                            DashboardView(authService: authService)
                                .tag(0)
                            
                            MyCoachView(onboardingManager: onboardingManager, authService: authService)
                                .tag(1)
                            
                            SettingsView()
                                .tag(2)
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        
                        FloatingTabBar(selectedTab: $selectedTab)
                            .padding(.horizontal)
                            .padding(.bottom, 28)
                    }
                    .background(Color.white)
                    .ignoresSafeArea(.container, edges: .bottom)
                }
            } else {
                AuthView()
            }
        }
    }
}

#Preview {
    ContentView()
}
