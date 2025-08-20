import SwiftUI

struct SettingsView: View {
    @State private var username = "John Doe"
    @State private var notificationsEnabled = true
    @State private var darkModeEnabled = false
    @State private var apiKey = ""
    @State private var showingRAGTest = false
    @StateObject private var authService = AuthService()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // User profile
                profileSection
                
                // App settings
                settingsSection
                
                // RAG Test section
                ragTestSection
                
                // About the app
                aboutSection
                
                // Logout section
                logoutSection
                
                // Space for fixed elements at the bottom
                Spacer()
                    .frame(height: 140)
            }
            .padding(.top, 16)
        }
        .background(Color.white) // White background for the whole screen
        .sheet(isPresented: $showingRAGTest) {
            RAGTestView()
        }
    }
    
    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Profile")
                .font(.headline)
                .padding(.horizontal, 16)
            
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    if let photoURL = authService.user?.photoURL {
                        AsyncImage(url: photoURL) { image in
                            image.resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "person.crop.circle")
                            .resizable()
                            .frame(width: 48, height: 48)
                            .foregroundColor(.gray)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(authService.user?.displayName ?? "No Name")
                            .font(.headline)
                        Text(authService.user?.email ?? "No Email")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
                .padding()
                .background(Color(UIColor.systemGray6))
            }
            .cornerRadius(12)
            .padding(.horizontal, 16)
        }
    }
    
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("App Settings")
                .font(.headline)
                .padding(.horizontal, 16)
            
            VStack(spacing: 0) {
                Button(action: {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Text("Notifications")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color(UIColor.systemGray6))
                
                Divider()
                
                Button(action: {
                    if let url = URL(string: "App-Prefs:root=General&path=LANGUAGE_AND_REGION") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Text("Language")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color(UIColor.systemGray6))
            }
            .cornerRadius(12)
            .padding(.horizontal, 16)
        }
    }
    
    private var ragTestSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Development Tools")
                .font(.headline)
                .padding(.horizontal, 16)
            
            VStack(spacing: 0) {
                Button(action: {
                    showingRAGTest = true
                }) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.blue)
                        Text("Test RAG Knowledge Base")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color(UIColor.systemGray6))
            }
            .cornerRadius(12)
            .padding(.horizontal, 16)
        }
    }
    
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("About")
                .font(.headline)
                .padding(.horizontal, 16)
            
            VStack(spacing: 0) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color(UIColor.systemGray6))
                
                Divider()
                
                Button(action: {
                    // Action for "Privacy Policy"
                }) {
                    HStack {
                        Text("Privacy Policy")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color(UIColor.systemGray6))
                
                Divider()
                
                Button(action: {
                    // Action for "Terms of Service"
                }) {
                    HStack {
                        Text("Terms of Service")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color(UIColor.systemGray6))
            }
            .cornerRadius(12)
            .padding(.horizontal, 16)
        }
    }
    
    private var logoutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Account")
                .font(.headline)
                .padding(.horizontal, 16)
            
            VStack(spacing: 0) {
                Button(action: {
                    do {
                        try authService.signOut()
                    } catch {
                        print("Error signing out: \(error)")
                    }
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)
                        
                        Text("Logout")
                            .foregroundColor(.red)
                        
                        Spacer()
                    }
                }
                .padding()
                .background(Color(UIColor.systemGray6))
            }
            .cornerRadius(12)
            .padding(.horizontal, 16)
        }
    }
}

#Preview {
    SettingsView()
} 