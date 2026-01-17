//
//  User.swift
//  TodoHub
//
//  Copyright (c) 2025 Martin Woodward
//  Licensed under MIT License
//

import Foundation

struct User: Codable, Identifiable, Sendable {
    let id: String
    let login: String
    let name: String?
    let avatarUrl: String?
    let email: String?
    
    var displayName: String {
        name ?? login
    }
}
