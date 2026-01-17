//
//  Todo.swift
//  TodoHub
//
//  Copyright (c) 2025 Martin Woodward
//  Licensed under MIT License
//

import Foundation

struct Todo: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let issueId: String
    let issueNumber: Int
    let title: String
    var body: String?
    var isCompleted: Bool
    var dueDate: Date?
    var priority: Priority
    var assignees: [String]
    let repositoryFullName: String
    var projectItemId: String?
    let createdAt: Date
    var updatedAt: Date
    
    var isOverdue: Bool {
        guard let dueDate = dueDate else { return false }
        return dueDate < Date() && !isCompleted
    }
    
    var isDueToday: Bool {
        guard let dueDate = dueDate else { return false }
        return Calendar.current.isDateInToday(dueDate)
    }
    
    var isDueSoon: Bool {
        guard let dueDate = dueDate else { return false }
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let weekFromNow = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        return dueDate > tomorrow && dueDate <= weekFromNow
    }
}

extension Todo {
    static var preview: Todo {
        Todo(
            id: "1",
            issueId: "I_123",
            issueNumber: 42,
            title: "Review PR for auth fix",
            body: "Need to review the authentication refactor PR",
            isCompleted: false,
            dueDate: Date(),
            priority: .high,
            assignees: ["martinwoodward"],
            repositoryFullName: "martinwoodward/todos",
            projectItemId: "PVI_123",
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
