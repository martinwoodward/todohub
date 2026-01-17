//
//  AuthViewModel.swift
//  TodoHub
//
//  Copyright (c) 2025 Martin Woodward
//  Licensed under MIT License
//

import SwiftUI
import AuthenticationServices

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: Error?
    @Published var currentUser: User?
    @Published var selectedRepository: Repository?
    
    @AppStorage("selectedRepositoryId") private var selectedRepositoryId: String?
    @AppStorage("selectedRepositoryData") private var selectedRepositoryData: Data?
    
    private let authService = GitHubAuthService.shared
    private let keychainService = KeychainService.shared
    
    private var webAuthSession: ASWebAuthenticationSession?
    
    init() {
        Task {
            await checkExistingAuth()
        }
    }
    
    func checkExistingAuth() async {
        do {
            if let token = try await keychainService.getAccessToken(),
               let user = try await keychainService.getUser() {
                self.currentUser = user
                self.isAuthenticated = true
                
                // Save user login for issue assignment
                UserDefaults.standard.set(user.login, forKey: "currentUserLogin")
                
                // Restore selected repository
                if let data = selectedRepositoryData {
                    self.selectedRepository = try? JSONDecoder().decode(Repository.self, from: data)
                }
            }
        } catch {
            self.error = error
        }
    }
    
    func signIn() {
        isLoading = true
        error = nil
        
        let authURL = authService.authorizationURL
        
        webAuthSession = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: Config.appScheme
        ) { [weak self] callbackURL, error in
            Task { @MainActor in
                await self?.handleAuthCallback(callbackURL: callbackURL, error: error)
            }
        }
        
        webAuthSession?.presentationContextProvider = WebAuthPresentationContext.shared
        webAuthSession?.prefersEphemeralWebBrowserSession = false
        webAuthSession?.start()
    }
    
    private func handleAuthCallback(callbackURL: URL?, error: Error?) async {
        defer { isLoading = false }
        
        if let error = error as? ASWebAuthenticationSessionError,
           error.code == .canceledLogin {
            self.error = AuthError.cancelled
            return
        }
        
        if let error = error {
            self.error = error
            return
        }
        
        guard let callbackURL = callbackURL,
              let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            self.error = AuthError.tokenExchangeFailed
            return
        }
        
        do {
            // Exchange code for token
            let tokenResponse = try await authService.exchangeCodeForToken(code: code)
            
            guard let accessToken = tokenResponse.accessToken else {
                throw AuthError.noAccessToken
            }
            
            // Save token
            try await keychainService.saveAccessToken(accessToken)
            
            // Fetch user info
            let user = try await authService.fetchCurrentUser(accessToken: accessToken)
            try await keychainService.saveUser(user)
            
            // Save user login for issue assignment
            UserDefaults.standard.set(user.login, forKey: "currentUserLogin")
            
            self.currentUser = user
            self.isAuthenticated = true
            
        } catch {
            self.error = error
        }
    }
    
    func signOut() async {
        do {
            try await keychainService.clearAll()
            selectedRepositoryId = nil
            selectedRepositoryData = nil
            currentUser = nil
            selectedRepository = nil
            isAuthenticated = false
        } catch {
            self.error = error
        }
    }
    
    func selectRepository(_ repository: Repository) {
        selectedRepository = repository
        selectedRepositoryId = repository.id
        selectedRepositoryData = try? JSONEncoder().encode(repository)
    }
    
    func clearError() {
        error = nil
    }
}

// MARK: - Web Auth Presentation Context

class WebAuthPresentationContext: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = WebAuthPresentationContext()
    
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            return ASPresentationAnchor()
        }
        return window
    }
}
