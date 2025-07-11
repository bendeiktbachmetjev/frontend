//
//  frontendApp.swift
//  frontend
//
//  Created by Benedikt Bachmetjev on 03/05/2025.
//

import SwiftUI
import FirebaseCore

@main
struct frontendApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
