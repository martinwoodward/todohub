//
//  KeychainService.swift
//  TodoHub
//
//  Copyright (c) 2025 Martin Woodward
//  Licensed under MIT License
//

import Foundation
import Security

actor KeychainService {
    static let shared = KeychainService()
    
    private let service = "com.martinwoodward.todohub"
    
    private enum Keys {
        static let accessToken = "github_access_token"
        static let refreshToken = "github_refresh_token"
        static let user = "github_user"
    }
    
    // MARK: - Access Token
    
    func saveAccessToken(_ token: String) throws {
        try save(key: Keys.accessToken, data: Data(token.utf8))
    }
    
    func getAccessToken() throws -> String? {
        guard let data = try get(key: Keys.accessToken) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    func deleteAccessToken() throws {
        try delete(key: Keys.accessToken)
    }
    
    // MARK: - Refresh Token
    
    func saveRefreshToken(_ token: String) throws {
        try save(key: Keys.refreshToken, data: Data(token.utf8))
    }
    
    func getRefreshToken() throws -> String? {
        guard let data = try get(key: Keys.refreshToken) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    func deleteRefreshToken() throws {
        try delete(key: Keys.refreshToken)
    }
    
    // MARK: - User
    
    func saveUser(_ user: User) throws {
        let data = try JSONEncoder().encode(user)
        try save(key: Keys.user, data: data)
    }
    
    func getUser() throws -> User? {
        guard let data = try get(key: Keys.user) else { return nil }
        return try JSONDecoder().decode(User.self, from: data)
    }
    
    func deleteUser() throws {
        try delete(key: Keys.user)
    }
    
    // MARK: - Clear All
    
    func clearAll() throws {
        try deleteAccessToken()
        try deleteRefreshToken()
        try deleteUser()
    }
    
    // MARK: - Private Helpers
    
    private func save(key: String, data: Data) throws {
        // Delete existing item first
        try? delete(key: key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unableToSave(status)
        }
    }
    
    private func get(key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecItemNotFound {
            return nil
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.unableToRead(status)
        }
        
        return result as? Data
    }
    
    private func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unableToDelete(status)
        }
    }
}

enum KeychainError: LocalizedError {
    case unableToSave(OSStatus)
    case unableToRead(OSStatus)
    case unableToDelete(OSStatus)
    
    var errorDescription: String? {
        switch self {
        case .unableToSave(let status):
            return "Unable to save to Keychain: \(status)"
        case .unableToRead(let status):
            return "Unable to read from Keychain: \(status)"
        case .unableToDelete(let status):
            return "Unable to delete from Keychain: \(status)"
        }
    }
}
