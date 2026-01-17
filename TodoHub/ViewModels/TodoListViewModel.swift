//
//  TodoListViewModel.swift
//  TodoHub
//
//  Copyright (c) 2025 Martin Woodward
//  Licensed under MIT License
//

import SwiftUI

@MainActor
class TodoListViewModel: ObservableObject {
    @Published var todos: [Todo] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let keychainService = KeychainService.shared
    private let apiService = GitHubAPIService.shared
    
    // MARK: - Computed Properties
    
    var overdueTodos: [Todo] {
        todos.filter { $0.isOverdue && !$0.isCompleted }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }
    
    var todayTodos: [Todo] {
        todos.filter { $0.isDueToday && !$0.isCompleted && !$0.isOverdue }
            .sorted { $0.priority.sortOrder < $1.priority.sortOrder }
    }
    
    var upcomingTodos: [Todo] {
        todos.filter { todo in
            guard let dueDate = todo.dueDate else { return false }
            return !todo.isCompleted && !todo.isDueToday && !todo.isOverdue && dueDate > Date()
        }
        .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }
    
    var noDueDateTodos: [Todo] {
        todos.filter { $0.dueDate == nil && !$0.isCompleted }
            .sorted { $0.priority.sortOrder < $1.priority.sortOrder }
    }
    
    // MARK: - Actions
    
    func loadTodos() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            todos = try await apiService.fetchTodos()
        } catch {
            self.error = error
            // For demo purposes, load sample data
            loadSampleData()
        }
    }
    
    func refresh() async {
        await loadTodos()
    }
    
    func createTodo(title: String, dueDate: Date?, priority: Priority) async {
        do {
            let newTodo = try await apiService.createTodo(
                title: title,
                body: nil,
                dueDate: dueDate,
                priority: priority
            )
            todos.append(newTodo)
        } catch {
            self.error = error
            // For demo, add locally
            let todo = Todo(
                id: UUID().uuidString,
                issueId: "local_\(UUID().uuidString)",
                issueNumber: todos.count + 1,
                title: title,
                body: nil,
                isCompleted: false,
                dueDate: dueDate,
                priority: priority,
                assignees: [],
                repositoryFullName: "local/todos",
                projectItemId: nil,
                createdAt: Date(),
                updatedAt: Date()
            )
            todos.append(todo)
        }
    }
    
    func toggleComplete(_ todo: Todo) async {
        guard let index = todos.firstIndex(where: { $0.id == todo.id }) else { return }
        
        todos[index].isCompleted.toggle()
        todos[index].updatedAt = Date()
        
        do {
            if todos[index].isCompleted {
                try await apiService.closeIssue(issueId: todo.issueId)
            } else {
                try await apiService.reopenIssue(issueId: todo.issueId)
            }
        } catch {
            // Revert on failure
            todos[index].isCompleted.toggle()
            self.error = error
        }
    }
    
    func deleteTodo(_ todo: Todo) async {
        guard let index = todos.firstIndex(where: { $0.id == todo.id }) else { return }
        
        let removed = todos.remove(at: index)
        
        do {
            try await apiService.closeIssue(issueId: todo.issueId)
        } catch {
            // Restore on failure
            todos.insert(removed, at: min(index, todos.count))
            self.error = error
        }
    }
    
    func updateTodo(_ todo: Todo) async {
        guard let index = todos.firstIndex(where: { $0.id == todo.id }) else { return }
        
        let original = todos[index]
        todos[index] = todo
        
        do {
            try await apiService.updateIssue(
                issueId: todo.issueId,
                title: todo.title,
                body: todo.body
            )
            
            if let projectItemId = todo.projectItemId {
                try await apiService.updateProjectItemFields(
                    itemId: projectItemId,
                    dueDate: todo.dueDate,
                    priority: todo.priority
                )
            }
        } catch {
            todos[index] = original
            self.error = error
        }
    }
    
    // MARK: - Sample Data
    
    private func loadSampleData() {
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let nextWeek = Calendar.current.date(byAdding: .day, value: 5, to: today)!
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        
        todos = [
            Todo(
                id: "1",
                issueId: "I_1",
                issueNumber: 1,
                title: "Review PR for auth fix",
                body: "Check the OAuth implementation",
                isCompleted: false,
                dueDate: today,
                priority: .high,
                assignees: ["martinwoodward"],
                repositoryFullName: "martinwoodward/todos",
                projectItemId: "PVI_1",
                createdAt: yesterday,
                updatedAt: yesterday
            ),
            Todo(
                id: "2",
                issueId: "I_2",
                issueNumber: 2,
                title: "Update documentation",
                body: nil,
                isCompleted: false,
                dueDate: today,
                priority: .medium,
                assignees: ["martinwoodward"],
                repositoryFullName: "martinwoodward/todos",
                projectItemId: "PVI_2",
                createdAt: yesterday,
                updatedAt: yesterday
            ),
            Todo(
                id: "3",
                issueId: "I_3",
                issueNumber: 3,
                title: "Plan sprint goals",
                body: "Define objectives for Q1",
                isCompleted: false,
                dueDate: nextWeek,
                priority: .low,
                assignees: ["martinwoodward"],
                repositoryFullName: "martinwoodward/todos",
                projectItemId: "PVI_3",
                createdAt: yesterday,
                updatedAt: yesterday
            ),
            Todo(
                id: "4",
                issueId: "I_4",
                issueNumber: 4,
                title: "Write blog post",
                body: nil,
                isCompleted: false,
                dueDate: tomorrow,
                priority: .medium,
                assignees: ["martinwoodward"],
                repositoryFullName: "martinwoodward/todos",
                projectItemId: "PVI_4",
                createdAt: yesterday,
                updatedAt: yesterday
            ),
            Todo(
                id: "5",
                issueId: "I_5",
                issueNumber: 5,
                title: "Research new frameworks",
                body: nil,
                isCompleted: false,
                dueDate: nil,
                priority: .none,
                assignees: ["martinwoodward"],
                repositoryFullName: "martinwoodward/todos",
                projectItemId: "PVI_5",
                createdAt: yesterday,
                updatedAt: yesterday
            ),
            Todo(
                id: "6",
                issueId: "I_6",
                issueNumber: 6,
                title: "Fix overdue bug",
                body: "This should show as overdue",
                isCompleted: false,
                dueDate: yesterday,
                priority: .high,
                assignees: ["martinwoodward"],
                repositoryFullName: "martinwoodward/todos",
                projectItemId: "PVI_6",
                createdAt: yesterday,
                updatedAt: yesterday
            )
        ]
    }
}
