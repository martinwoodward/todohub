//
//  Repository.swift
//  TodoHub
//
//  Copyright (c) 2025 Martin Woodward
//  Licensed under MIT License
//

import Foundation

struct Repository: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let owner: String
    let isPrivate: Bool
    let description: String?
    
    var fullName: String {
        "\(owner)/\(name)"
    }
}
