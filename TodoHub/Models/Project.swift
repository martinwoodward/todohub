//
//  Project.swift
//  TodoHub
//
//  Copyright (c) 2025 Martin Woodward
//  Licensed under MIT License
//

import Foundation

struct Project: Codable, Identifiable, Sendable {
    let id: String
    let number: Int
    let title: String
    let url: String
    
    // Field IDs for custom fields
    var dueDateFieldId: String?
    var priorityFieldId: String?
    var priorityOptions: [PriorityOption]?
}

struct PriorityOption: Codable, Sendable {
    let id: String
    let name: String
}
