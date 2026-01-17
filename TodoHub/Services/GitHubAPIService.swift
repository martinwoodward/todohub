//
//  GitHubAPIService.swift
//  TodoHub
//
//  Copyright (c) 2025 Martin Woodward
//  Licensed under MIT License
//

import Foundation

actor GitHubAPIService {
    static let shared = GitHubAPIService()
    
    private let baseURL = URL(string: "https://api.github.com")!
    private let graphqlURL = URL(string: "https://api.github.com/graphql")!
    private let keychainService = KeychainService.shared
    
    // MARK: - Fetch Todos
    
    func fetchTodos() async throws -> [Todo] {
        guard let token = try await keychainService.getAccessToken() else {
            throw APIError.notAuthenticated
        }
        
        // Try to fetch from project first
        if let projectId = UserDefaults.standard.string(forKey: "selectedProjectId") {
            let todos = try await fetchTodosFromProject(projectId: projectId, token: token)
            if !todos.isEmpty {
                return todos
            }
        }
        
        // Fall back to fetching issues directly from the repository
        guard let repoOwner = UserDefaults.standard.string(forKey: "selectedRepositoryOwner"),
              let repoName = UserDefaults.standard.string(forKey: "selectedRepositoryName") else {
            throw APIError.noRepositorySelected
        }
        
        return try await fetchIssuesFromRepository(owner: repoOwner, name: repoName, token: token)
    }
    
    private func fetchTodosFromProject(projectId: String, token: String) async throws -> [Todo] {
        let query = """
        query GetProjectItems($projectId: ID!) {
          node(id: $projectId) {
            ... on ProjectV2 {
              items(first: 100) {
                nodes {
                  id
                  content {
                    ... on Issue {
                      id
                      number
                      title
                      body
                      state
                      createdAt
                      updatedAt
                      repository {
                        nameWithOwner
                      }
                      assignees(first: 10) {
                        nodes {
                          login
                        }
                      }
                    }
                  }
                  fieldValues(first: 20) {
                    nodes {
                      ... on ProjectV2ItemFieldDateValue {
                        date
                        field {
                          ... on ProjectV2FieldCommon {
                            name
                          }
                        }
                      }
                      ... on ProjectV2ItemFieldSingleSelectValue {
                        name
                        field {
                          ... on ProjectV2FieldCommon {
                            name
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
        """
        
        let variables: [String: Any] = ["projectId": projectId]
        let responseData = try await executeGraphQL(query: query, variables: variables, token: token)
        
        return try parseProjectItems(from: responseData)
    }
    
    private func fetchIssuesFromRepository(owner: String, name: String, token: String) async throws -> [Todo] {
        let query = """
        query GetRepositoryIssues($owner: String!, $name: String!) {
          repository(owner: $owner, name: $name) {
            issues(first: 100, states: [OPEN], orderBy: {field: UPDATED_AT, direction: DESC}) {
              nodes {
                id
                number
                title
                body
                state
                createdAt
                updatedAt
                assignees(first: 10) {
                  nodes {
                    login
                  }
                }
              }
            }
          }
        }
        """
        
        let variables: [String: Any] = ["owner": owner, "name": name]
        let responseData = try await executeGraphQL(query: query, variables: variables, token: token)
        
        return try parseRepositoryIssues(from: responseData, repoFullName: "\(owner)/\(name)")
    }
    
    private func parseRepositoryIssues(from response: [String: Any], repoFullName: String) throws -> [Todo] {
        guard let data = response["data"] as? [String: Any],
              let repository = data["repository"] as? [String: Any],
              let issues = repository["issues"] as? [String: Any],
              let nodes = issues["nodes"] as? [[String: Any]] else {
            return []
        }
        
        return nodes.compactMap { issue -> Todo? in
            guard let issueId = issue["id"] as? String,
                  let number = issue["number"] as? Int,
                  let title = issue["title"] as? String else {
                return nil
            }
            
            let state = issue["state"] as? String ?? "OPEN"
            let body = issue["body"] as? String
            
            let assigneesData = issue["assignees"] as? [String: Any]
            let assigneeNodes = assigneesData?["nodes"] as? [[String: Any]] ?? []
            let assignees = assigneeNodes.compactMap { $0["login"] as? String }
            
            let createdAt = parseDate(issue["createdAt"] as? String) ?? Date()
            let updatedAt = parseDate(issue["updatedAt"] as? String) ?? Date()
            
            return Todo(
                id: issueId,
                issueId: issueId,
                issueNumber: number,
                title: title,
                body: body,
                isCompleted: state == "CLOSED",
                dueDate: nil,
                priority: .none,
                assignees: assignees,
                repositoryFullName: repoFullName,
                projectItemId: nil,
                createdAt: createdAt,
                updatedAt: updatedAt
            )
        }
    }
    
    // MARK: - Create Todo (Issue)
    
    func createTodo(title: String, body: String?, dueDate: Date?, priority: Priority) async throws -> Todo {
        guard let token = try await keychainService.getAccessToken() else {
            throw APIError.notAuthenticated
        }
        
        guard let repoId = UserDefaults.standard.string(forKey: "selectedRepositoryNodeId") else {
            throw APIError.noRepositorySelected
        }
        
        // Create issue
        let createIssueQuery = """
        mutation CreateIssue($repositoryId: ID!, $title: String!, $body: String) {
          createIssue(input: {
            repositoryId: $repositoryId
            title: $title
            body: $body
          }) {
            issue {
              id
              number
              title
              body
              state
              createdAt
              updatedAt
              repository {
                nameWithOwner
              }
            }
          }
        }
        """
        
        var variables: [String: Any] = [
            "repositoryId": repoId,
            "title": title
        ]
        if let body = body {
            variables["body"] = body
        }
        
        let responseData = try await executeGraphQL(query: createIssueQuery, variables: variables, token: token)
        
        guard let data = responseData["data"] as? [String: Any],
              let createIssue = data["createIssue"] as? [String: Any],
              let issue = createIssue["issue"] as? [String: Any] else {
            throw APIError.invalidResponse
        }
        
        // TODO: Add issue to project and set fields
        
        return Todo(
            id: UUID().uuidString,
            issueId: issue["id"] as? String ?? "",
            issueNumber: issue["number"] as? Int ?? 0,
            title: title,
            body: body,
            isCompleted: false,
            dueDate: dueDate,
            priority: priority,
            assignees: [],
            repositoryFullName: (issue["repository"] as? [String: Any])?["nameWithOwner"] as? String ?? "",
            projectItemId: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    // MARK: - Close/Reopen Issue
    
    func closeIssue(issueId: String) async throws {
        guard let token = try await keychainService.getAccessToken() else {
            throw APIError.notAuthenticated
        }
        
        let query = """
        mutation CloseIssue($issueId: ID!) {
          closeIssue(input: { issueId: $issueId }) {
            issue {
              id
              state
            }
          }
        }
        """
        
        _ = try await executeGraphQL(query: query, variables: ["issueId": issueId], token: token)
    }
    
    func reopenIssue(issueId: String) async throws {
        guard let token = try await keychainService.getAccessToken() else {
            throw APIError.notAuthenticated
        }
        
        let query = """
        mutation ReopenIssue($issueId: ID!) {
          reopenIssue(input: { issueId: $issueId }) {
            issue {
              id
              state
            }
          }
        }
        """
        
        _ = try await executeGraphQL(query: query, variables: ["issueId": issueId], token: token)
    }
    
    // MARK: - Update Issue
    
    func updateIssue(issueId: String, title: String?, body: String?) async throws {
        guard let token = try await keychainService.getAccessToken() else {
            throw APIError.notAuthenticated
        }
        
        let query = """
        mutation UpdateIssue($issueId: ID!, $title: String, $body: String) {
          updateIssue(input: { id: $issueId, title: $title, body: $body }) {
            issue {
              id
              title
              body
            }
          }
        }
        """
        
        var variables: [String: Any] = ["issueId": issueId]
        if let title = title { variables["title"] = title }
        if let body = body { variables["body"] = body }
        
        _ = try await executeGraphQL(query: query, variables: variables, token: token)
    }
    
    // MARK: - Update Project Item Fields
    
    func updateProjectItemFields(itemId: String, dueDate: Date?, priority: Priority) async throws {
        // TODO: Implement project field updates using GraphQL mutations
    }
    
    // MARK: - Fetch All Assigned Issues
    
    func fetchAssignedIssues(login: String) async throws -> [Todo] {
        guard let token = try await keychainService.getAccessToken() else {
            throw APIError.notAuthenticated
        }
        
        let query = """
        query GetAssignedIssues($query: String!) {
          search(query: $query, type: ISSUE, first: 100) {
            nodes {
              ... on Issue {
                id
                number
                title
                body
                state
                createdAt
                updatedAt
                repository {
                  nameWithOwner
                }
                assignees(first: 10) {
                  nodes {
                    login
                  }
                }
              }
            }
          }
        }
        """
        
        let searchQuery = "assignee:\(login) is:open is:issue"
        let responseData = try await executeGraphQL(query: query, variables: ["query": searchQuery], token: token)
        
        return try parseSearchResults(from: responseData)
    }
    
    // MARK: - Private Helpers
    
    private func executeGraphQL(query: String, variables: [String: Any], token: String) async throws -> [String: Any] {
        var request = URLRequest(url: graphqlURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "query": query,
            "variables": variables
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw APIError.invalidResponse
        }
        
        if let errors = json["errors"] as? [[String: Any]], !errors.isEmpty {
            let message = errors.first?["message"] as? String ?? "Unknown GraphQL error"
            throw APIError.graphqlError(message)
        }
        
        return json
    }
    
    private func parseProjectItems(from response: [String: Any]) throws -> [Todo] {
        guard let data = response["data"] as? [String: Any],
              let node = data["node"] as? [String: Any],
              let items = node["items"] as? [String: Any],
              let nodes = items["nodes"] as? [[String: Any]] else {
            return []
        }
        
        return nodes.compactMap { item -> Todo? in
            guard let content = item["content"] as? [String: Any],
                  let issueId = content["id"] as? String,
                  let number = content["number"] as? Int,
                  let title = content["title"] as? String else {
                return nil
            }
            
            let state = content["state"] as? String ?? "OPEN"
            let body = content["body"] as? String
            let repoInfo = content["repository"] as? [String: Any]
            let repoName = repoInfo?["nameWithOwner"] as? String ?? ""
            
            let assigneesData = content["assignees"] as? [String: Any]
            let assigneeNodes = assigneesData?["nodes"] as? [[String: Any]] ?? []
            let assignees = assigneeNodes.compactMap { $0["login"] as? String }
            
            // Parse field values
            var dueDate: Date?
            var priority: Priority = .none
            
            if let fieldValues = item["fieldValues"] as? [String: Any],
               let fieldNodes = fieldValues["nodes"] as? [[String: Any]] {
                for field in fieldNodes {
                    if let fieldInfo = field["field"] as? [String: Any],
                       let fieldName = fieldInfo["name"] as? String {
                        if fieldName.lowercased().contains("due") {
                            if let dateStr = field["date"] as? String {
                                let formatter = ISO8601DateFormatter()
                                formatter.formatOptions = [.withFullDate]
                                dueDate = formatter.date(from: dateStr)
                            }
                        } else if fieldName.lowercased().contains("priority") {
                            if let priorityName = field["name"] as? String {
                                priority = Priority(rawValue: priorityName) ?? .none
                            }
                        }
                    }
                }
            }
            
            let createdAt = parseDate(content["createdAt"] as? String) ?? Date()
            let updatedAt = parseDate(content["updatedAt"] as? String) ?? Date()
            
            return Todo(
                id: item["id"] as? String ?? UUID().uuidString,
                issueId: issueId,
                issueNumber: number,
                title: title,
                body: body,
                isCompleted: state == "CLOSED",
                dueDate: dueDate,
                priority: priority,
                assignees: assignees,
                repositoryFullName: repoName,
                projectItemId: item["id"] as? String,
                createdAt: createdAt,
                updatedAt: updatedAt
            )
        }
    }
    
    private func parseSearchResults(from response: [String: Any]) throws -> [Todo] {
        guard let data = response["data"] as? [String: Any],
              let search = data["search"] as? [String: Any],
              let nodes = search["nodes"] as? [[String: Any]] else {
            return []
        }
        
        return nodes.compactMap { issue -> Todo? in
            guard let issueId = issue["id"] as? String,
                  let number = issue["number"] as? Int,
                  let title = issue["title"] as? String else {
                return nil
            }
            
            let state = issue["state"] as? String ?? "OPEN"
            let body = issue["body"] as? String
            let repoInfo = issue["repository"] as? [String: Any]
            let repoName = repoInfo?["nameWithOwner"] as? String ?? ""
            
            let assigneesData = issue["assignees"] as? [String: Any]
            let assigneeNodes = assigneesData?["nodes"] as? [[String: Any]] ?? []
            let assignees = assigneeNodes.compactMap { $0["login"] as? String }
            
            let createdAt = parseDate(issue["createdAt"] as? String) ?? Date()
            let updatedAt = parseDate(issue["updatedAt"] as? String) ?? Date()
            
            return Todo(
                id: UUID().uuidString,
                issueId: issueId,
                issueNumber: number,
                title: title,
                body: body,
                isCompleted: state == "CLOSED",
                dueDate: nil,
                priority: .none,
                assignees: assignees,
                repositoryFullName: repoName,
                projectItemId: nil,
                createdAt: createdAt,
                updatedAt: updatedAt
            )
        }
    }
    
    private func parseDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: dateString)
    }
}
