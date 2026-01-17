//
//  TodoHubTests.swift
//  TodoHubTests
//
//  Copyright (c) 2025 Martin Woodward
//  Licensed under MIT License
//

import XCTest
@testable import TodoHub

final class TodoHubTests: XCTestCase {
    
    func testTodoIsOverdue() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let todo = Todo(
            id: "1",
            issueId: "I_1",
            issueNumber: 1,
            title: "Test",
            body: nil,
            isCompleted: false,
            dueDate: yesterday,
            priority: .high,
            assignees: [],
            repositoryFullName: "test/repo",
            projectItemId: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        XCTAssertTrue(todo.isOverdue)
    }
    
    func testTodoIsNotOverdueWhenCompleted() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let todo = Todo(
            id: "1",
            issueId: "I_1",
            issueNumber: 1,
            title: "Test",
            body: nil,
            isCompleted: true,
            dueDate: yesterday,
            priority: .high,
            assignees: [],
            repositoryFullName: "test/repo",
            projectItemId: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        XCTAssertFalse(todo.isOverdue)
    }
    
    func testTodoIsDueToday() {
        let today = Date()
        let todo = Todo(
            id: "1",
            issueId: "I_1",
            issueNumber: 1,
            title: "Test",
            body: nil,
            isCompleted: false,
            dueDate: today,
            priority: .medium,
            assignees: [],
            repositoryFullName: "test/repo",
            projectItemId: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        XCTAssertTrue(todo.isDueToday)
    }
    
    func testPrioritySortOrder() {
        XCTAssertLessThan(Priority.high.sortOrder, Priority.medium.sortOrder)
        XCTAssertLessThan(Priority.medium.sortOrder, Priority.low.sortOrder)
        XCTAssertLessThan(Priority.low.sortOrder, Priority.none.sortOrder)
    }
}
