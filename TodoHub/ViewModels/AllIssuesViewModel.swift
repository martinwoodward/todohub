//
//  AllIssuesViewModel.swift
//  TodoHub
//
//  Copyright (c) 2025 Martin Woodward
//  Licensed under MIT License
//

import SwiftUI

@MainActor
class AllIssuesViewModel: ObservableObject {
    @Published var issues: [Todo] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let keychainService = KeychainService.shared
    private let apiService = GitHubAPIService.shared
    
    var organizations: [String] {
        let orgs = Set(issues.map { $0.repositoryFullName.components(separatedBy: "/").first ?? "" })
        return Array(orgs).sorted()
    }
    
    func loadIssues() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            guard let user = try await keychainService.getUser() else {
                throw AuthError.userFetchFailed
            }
            
            issues = try await apiService.fetchAssignedIssues(login: user.login)
        } catch {
            self.error = error
            // Load sample data for demo
            loadSampleData()
        }
    }
    
    func refresh() async {
        await loadIssues()
    }
    
    func markAsDone(_ issue: Todo) async {
        do {
            try await apiService.closeIssue(issueId: issue.issueId)
            issues.removeAll { $0.id == issue.id }
        } catch {
            self.error = error
        }
    }
    
    func addToTodoList(_ issue: Todo) async {
        // TODO: Add to the user's todo project
        // For now, just show feedback
    }
    
    private func loadSampleData() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        
        issues = [
            Todo(
                id: "ext_1",
                issueId: "I_ext_1",
                issueNumber: 23,
                title: "Fix login bug",
                body: nil,
                isCompleted: false,
                dueDate: nil,
                priority: .none,
                assignees: ["martinwoodward"],
                repositoryFullName: "martinwoodward/project-alpha",
                projectItemId: nil,
                createdAt: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
                updatedAt: yesterday
            ),
            Todo(
                id: "ext_2",
                issueId: "I_ext_2",
                issueNumber: 45,
                title: "Add unit tests for auth module",
                body: nil,
                isCompleted: false,
                dueDate: nil,
                priority: .none,
                assignees: ["martinwoodward"],
                repositoryFullName: "martinwoodward/project-alpha",
                projectItemId: nil,
                createdAt: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
                updatedAt: yesterday
            ),
            Todo(
                id: "ext_3",
                issueId: "I_ext_3",
                issueNumber: 89,
                title: "Review documentation PR",
                body: nil,
                isCompleted: false,
                dueDate: nil,
                priority: .none,
                assignees: ["martinwoodward"],
                repositoryFullName: "github/copilot-cli",
                projectItemId: nil,
                createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
                updatedAt: yesterday
            ),
            Todo(
                id: "ext_4",
                issueId: "I_ext_4",
                issueNumber: 1234,
                title: "Investigate performance regression",
                body: nil,
                isCompleted: false,
                dueDate: nil,
                priority: .none,
                assignees: ["martinwoodward"],
                repositoryFullName: "microsoft/vscode",
                projectItemId: nil,
                createdAt: Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
                updatedAt: yesterday
            )
        ]
    }
}
