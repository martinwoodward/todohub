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
        
        let issueId = issue["id"] as? String ?? ""
        
        // Add issue to project and set fields
        var projectItemId: String? = nil
        if let projectId = UserDefaults.standard.string(forKey: "selectedProjectId") {
            projectItemId = try await addIssueToProject(issueId: issueId, projectId: projectId, token: token)
            
            if let itemId = projectItemId {
                try await updateProjectItemFields(itemId: itemId, dueDate: dueDate, priority: priority, token: token)
                // Move new item to top of project
                try await updateProjectItemPosition(itemId: itemId, afterId: nil, projectId: projectId, token: token)
            }
        }
        
        // Assign to current user
        if let login = UserDefaults.standard.string(forKey: "currentUserLogin") {
            try await assignIssueToUser(issueId: issueId, login: login, token: token)
        }
        
        return Todo(
            id: UUID().uuidString,
            issueId: issueId,
            issueNumber: issue["number"] as? Int ?? 0,
            title: title,
            body: body,
            isCompleted: false,
            dueDate: dueDate,
            priority: priority,
            assignees: [],
            repositoryFullName: (issue["repository"] as? [String: Any])?["nameWithOwner"] as? String ?? "",
            projectItemId: projectItemId,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    // MARK: - Add Issue to Project
    
    private func addIssueToProject(issueId: String, projectId: String, token: String) async throws -> String? {
        let query = """
        mutation AddToProject($projectId: ID!, $contentId: ID!) {
          addProjectV2ItemById(input: {
            projectId: $projectId
            contentId: $contentId
          }) {
            item {
              id
            }
          }
        }
        """
        
        let variables: [String: Any] = [
            "projectId": projectId,
            "contentId": issueId
        ]
        
        let responseData = try await executeGraphQL(query: query, variables: variables, token: token)
        
        guard let data = responseData["data"] as? [String: Any],
              let addItem = data["addProjectV2ItemById"] as? [String: Any],
              let item = addItem["item"] as? [String: Any],
              let itemId = item["id"] as? String else {
            return nil
        }
        
        return itemId
    }
    
    // MARK: - Assign Issue to User
    
    private func assignIssueToUser(issueId: String, login: String, token: String) async throws {
        // First get user ID
        let userQuery = """
        query GetUserId($login: String!) {
          user(login: $login) {
            id
          }
        }
        """
        
        let userResult = try await executeGraphQL(query: userQuery, variables: ["login": login], token: token)
        
        guard let userData = userResult["data"] as? [String: Any],
              let user = userData["user"] as? [String: Any],
              let userId = user["id"] as? String else {
            return
        }
        
        let assignQuery = """
        mutation AssignUser($issueId: ID!, $assigneeIds: [ID!]!) {
          updateIssue(input: { id: $issueId, assigneeIds: $assigneeIds }) {
            issue {
              id
            }
          }
        }
        """
        
        _ = try await executeGraphQL(query: assignQuery, variables: ["issueId": issueId, "assigneeIds": [userId]], token: token)
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
        guard let token = try await keychainService.getAccessToken() else {
            throw APIError.notAuthenticated
        }
        
        try await updateProjectItemFields(itemId: itemId, dueDate: dueDate, priority: priority, token: token)
    }
    
    private func updateProjectItemFields(itemId: String, dueDate: Date?, priority: Priority, token: String) async throws {
        guard let projectId = UserDefaults.standard.string(forKey: "selectedProjectId") else {
            return
        }
        
        // Get project fields
        let fieldsQuery = """
        query GetProjectFields($projectId: ID!) {
          node(id: $projectId) {
            ... on ProjectV2 {
              fields(first: 20) {
                nodes {
                  ... on ProjectV2Field {
                    id
                    name
                  }
                  ... on ProjectV2SingleSelectField {
                    id
                    name
                    options {
                      id
                      name
                    }
                  }
                }
              }
            }
          }
        }
        """
        
        let fieldsResult = try await executeGraphQL(query: fieldsQuery, variables: ["projectId": projectId], token: token)
        
        guard let data = fieldsResult["data"] as? [String: Any],
              let node = data["node"] as? [String: Any],
              let fields = node["fields"] as? [String: Any],
              let fieldNodes = fields["nodes"] as? [[String: Any]] else {
            return
        }
        
        // Find Due Date field and Priority field
        var dueDateFieldId: String?
        var priorityFieldId: String?
        var priorityOptions: [[String: Any]] = []
        
        for field in fieldNodes {
            guard let name = field["name"] as? String,
                  let id = field["id"] as? String else { continue }
            
            if name.lowercased().contains("due") {
                dueDateFieldId = id
            } else if name.lowercased().contains("priority") {
                priorityFieldId = id
                priorityOptions = field["options"] as? [[String: Any]] ?? []
            }
        }
        
        // Update Due Date
        if let fieldId = dueDateFieldId, let dueDate = dueDate {
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withFullDate]
            let dateString = dateFormatter.string(from: dueDate)
            
            let updateQuery = """
            mutation UpdateDueDate($projectId: ID!, $itemId: ID!, $fieldId: ID!, $value: Date!) {
              updateProjectV2ItemFieldValue(input: {
                projectId: $projectId
                itemId: $itemId
                fieldId: $fieldId
                value: { date: $value }
              }) {
                projectV2Item {
                  id
                }
              }
            }
            """
            
            let variables: [String: Any] = [
                "projectId": projectId,
                "itemId": itemId,
                "fieldId": fieldId,
                "value": dateString
            ]
            
            _ = try await executeGraphQL(query: updateQuery, variables: variables, token: token)
        }
        
        // Update Priority
        if let fieldId = priorityFieldId, priority != .none {
            // Find matching option ID
            let priorityName = priority.rawValue
            var optionId: String?
            
            for option in priorityOptions {
                if let name = option["name"] as? String,
                   let id = option["id"] as? String,
                   name.lowercased() == priorityName.lowercased() {
                    optionId = id
                    break
                }
            }
            
            if let optionId = optionId {
                let updateQuery = """
                mutation UpdatePriority($projectId: ID!, $itemId: ID!, $fieldId: ID!, $optionId: String!) {
                  updateProjectV2ItemFieldValue(input: {
                    projectId: $projectId
                    itemId: $itemId
                    fieldId: $fieldId
                    value: { singleSelectOptionId: $optionId }
                  }) {
                    projectV2Item {
                      id
                    }
                  }
                }
                """
                
                let variables: [String: Any] = [
                    "projectId": projectId,
                    "itemId": itemId,
                    "fieldId": fieldId,
                    "optionId": optionId
                ]
                
                _ = try await executeGraphQL(query: updateQuery, variables: variables, token: token)
            }
        }
    }
    
    // MARK: - Update Project Item Position
    
    func updateProjectItemPosition(itemId: String, afterId: String?) async throws {
        guard let token = try await keychainService.getAccessToken() else {
            throw APIError.notAuthenticated
        }
        
        guard let projectId = UserDefaults.standard.string(forKey: "selectedProjectId") else {
            throw APIError.noProjectSelected
        }
        
        try await updateProjectItemPosition(itemId: itemId, afterId: afterId, projectId: projectId, token: token)
    }
    
    private func updateProjectItemPosition(itemId: String, afterId: String?, projectId: String, token: String) async throws {
        let query = """
        mutation UpdateItemPosition($projectId: ID!, $itemId: ID!, $afterId: ID) {
          updateProjectV2ItemPosition(input: {
            projectId: $projectId
            itemId: $itemId
            afterId: $afterId
          }) {
            items {
              nodes {
                id
              }
            }
          }
        }
        """
        
        var variables: [String: Any] = [
            "projectId": projectId,
            "itemId": itemId
        ]
        if let afterId = afterId {
            variables["afterId"] = afterId
        } else {
            // Explicitly set to null to move to top
            variables["afterId"] = NSNull()
        }
        
        print("Updating position: itemId=\(itemId), afterId=\(afterId ?? "nil (top)")")
        let result = try await executeGraphQL(query: query, variables: variables, token: token)
        
        // Check for errors in response
        if let errors = result["errors"] as? [[String: Any]], !errors.isEmpty {
            let message = errors.first?["message"] as? String ?? "Unknown error"
            print("GraphQL error updating position: \(message)")
            throw APIError.graphqlError(message)
        }
        
        print("Position update successful")
    }
    
    // MARK: - Add Issue to Project (public)
    
    func addIssueToProjectBoard(issueId: String) async throws -> String? {
        guard let token = try await keychainService.getAccessToken() else {
            throw APIError.notAuthenticated
        }
        
        guard let projectId = UserDefaults.standard.string(forKey: "selectedProjectId") else {
            throw APIError.noProjectSelected
        }
        
        let itemId = try await addIssueToProject(issueId: issueId, projectId: projectId, token: token)
        
        // Move to top of project
        if let itemId = itemId {
            try await updateProjectItemPosition(itemId: itemId, afterId: nil, projectId: projectId, token: token)
        }
        
        return itemId
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
