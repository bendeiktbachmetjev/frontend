import Foundation
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import SwiftUI

class AuthService: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    
    init() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.user = user
                self?.isAuthenticated = user != nil
            }
        }
    }
    
    // MARK: - Email Authentication
    
    func signUp(email: String, password: String) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        DispatchQueue.main.async {
            self.user = result.user
            self.isAuthenticated = true
        }
    }
    
    func signIn(email: String, password: String) async throws {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        DispatchQueue.main.async {
            self.user = result.user
            self.isAuthenticated = true
        }
    }
    
    // MARK: - Google Sign In
    
    func signInWithGoogle() async throws {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            throw AuthError.noRootViewController
        }
        
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
        
        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthError.noIdToken
        }
        
        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )
        
        let authResult = try await Auth.auth().signIn(with: credential)
        DispatchQueue.main.async {
            self.user = authResult.user
            self.isAuthenticated = true
        }
    }
    
    // MARK: - Firebase ID Token
    /// Returns the current user's Firebase ID token, or nil if not authenticated.
    func getIdToken(completion: @escaping (String?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(nil)
            return
        }
        user.getIDToken { token, error in
            if let token = token {
                completion(token)
            } else {
                print("Error getting idToken: \(error?.localizedDescription ?? "unknown error")")
                completion(nil)
            }
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() throws {
        try Auth.auth().signOut()
        DispatchQueue.main.async {
            self.user = nil
            self.isAuthenticated = false
        }
    }
}

// MARK: - Errors

enum AuthError: Error {
    case noRootViewController
    case noIdToken
    case signInFailed
} 
