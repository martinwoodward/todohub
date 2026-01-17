//
//  GitHubAuthService.swift
//  TodoHub
//
//  Copyright (c) 2025 Martin Woodward
//  Licensed under MIT License
//

import Foundation
import AuthenticationServices

final class GitHubAuthService: Sendable {
    static let shared = GitHubAuthService()
    
    private let clientId: String
    private let clientSecret: String
    private let redirectUri = "todohub://oauth-callback"
    private let scopes = ["repo", "read:user", "read:org", "project"]
    
    init() {
        // Load from environment or config
        // In production, these should be in a gitignored Config file
        self.clientId = ProcessInfo.processInfo.environment["GITHUB_CLIENT_ID"] ?? Config.githubClientId
        self.clientSecret = ProcessInfo.processInfo.environment["GITHUB_CLIENT_SECRET"] ?? Config.githubClientSecret
    }
    
    var authorizationURL: URL {
        var components = URLComponents(string: "https://github.com/login/oauth/authorize")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "scope", value: scopes.joined(separator: " ")),
            URLQueryItem(name: "state", value: UUID().uuidString)
        ]
        return components.url!
    }
    
    func exchangeCodeForToken(code: String) async throws -> TokenResponse {
        var request = URLRequest(url: URL(string: "https://github.com/login/oauth/access_token")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "client_id": clientId,
            "client_secret": clientSecret,
            "code": code,
            "redirect_uri": redirectUri
        ]
        
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AuthError.tokenExchangeFailed
        }
        
        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        
        if let error = tokenResponse.error {
            throw AuthError.oauthError(error, tokenResponse.errorDescription)
        }
        
        guard tokenResponse.accessToken != nil else {
            throw AuthError.noAccessToken
        }
        
        return tokenResponse
    }
    
    func fetchCurrentUser(accessToken: String) async throws -> User {
        var request = URLRequest(url: URL(string: "https://api.github.com/user")!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AuthError.userFetchFailed
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        struct GitHubUser: Decodable {
            let id: Int
            let login: String
            let name: String?
            let avatarUrl: String?
            let email: String?
        }
        
        let ghUser = try decoder.decode(GitHubUser.self, from: data)
        
        return User(
            id: String(ghUser.id),
            login: ghUser.login,
            name: ghUser.name,
            avatarUrl: ghUser.avatarUrl,
            email: ghUser.email
        )
    }
}

struct TokenResponse: Codable {
    let accessToken: String?
    let tokenType: String?
    let scope: String?
    let error: String?
    let errorDescription: String?
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case scope
        case error
        case errorDescription = "error_description"
    }
}

enum AuthError: LocalizedError {
    case tokenExchangeFailed
    case noAccessToken
    case oauthError(String, String?)
    case userFetchFailed
    case cancelled
    
    var errorDescription: String? {
        switch self {
        case .tokenExchangeFailed:
            return "Failed to exchange authorization code for access token"
        case .noAccessToken:
            return "No access token received from GitHub"
        case .oauthError(let error, let description):
            return description ?? error
        case .userFetchFailed:
            return "Failed to fetch user information from GitHub"
        case .cancelled:
            return "Authentication was cancelled"
        }
    }
}
