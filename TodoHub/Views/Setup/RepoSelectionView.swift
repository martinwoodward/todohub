//
//  RepoSelectionView.swift
//  TodoHub
//
//  Copyright (c) 2025 Martin Woodward
//  Licensed under MIT License
//

import SwiftUI

struct RepoSelectionView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = RepoSelectionViewModel()
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            List {
                // Create new repo option
                Section {
                    Button(action: {
                        Task {
                            if let repo = await viewModel.createNewRepositoryAndSetup() {
                                authViewModel.selectRepository(repo)
                            }
                        }
                    }) {
                        HStack(spacing: 12) {
                            if viewModel.isCreatingRepo {
                                ProgressView()
                                    .frame(width: 28, height: 28)
                            } else {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.green)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(viewModel.isCreatingRepo ? "Creating repository..." : "Create new \"todos\" repo")
                                    .fontWeight(.medium)
                                    .foregroundStyle(.primary)
                                Text("Recommended for a fresh start")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .disabled(viewModel.isCreatingRepo)
                } header: {
                    Text("Suggested")
                }
                
                // User's repositories
                Section {
                    if viewModel.isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .padding(.vertical, 20)
                    } else if filteredRepositories.isEmpty {
                        Text("No repositories found")
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 20)
                    } else {
                        ForEach(filteredRepositories) { repo in
                            Button(action: {
                                viewModel.selectedRepository = repo
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: repo.isPrivate ? "lock.fill" : "folder.fill")
                                        .foregroundStyle(.secondary)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(repo.name)
                                            .fontWeight(.medium)
                                            .foregroundStyle(.primary)
                                        if let description = repo.description, !description.isEmpty {
                                            Text(description)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    if viewModel.selectedRepository?.id == repo.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                } header: {
                    Text("Your Repositories")
                }
            }
            .searchable(text: $searchText, prompt: "Search repositories...")
            .navigationTitle("Select Repository")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.isSettingUp {
                        ProgressView()
                    } else {
                        Button("Continue") {
                            if let repo = viewModel.selectedRepository {
                                Task {
                                    await viewModel.setupProjectAndContinue(repository: repo)
                                    authViewModel.selectRepository(repo)
                                }
                            }
                        }
                        .disabled(viewModel.selectedRepository == nil)
                    }
                }
            }
            .task {
                await viewModel.loadRepositories()
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") {
                    viewModel.error = nil
                }
            } message: {
                if let error = viewModel.error {
                    Text(error.localizedDescription)
                }
            }
        }
    }
    
    private var filteredRepositories: [Repository] {
        if searchText.isEmpty {
            return viewModel.repositories
        }
        return viewModel.repositories.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.fullName.localizedCaseInsensitiveContains(searchText)
        }
    }
}

@MainActor
class RepoSelectionViewModel: ObservableObject {
    @Published var repositories: [Repository] = []
    @Published var selectedRepository: Repository?
    @Published var isLoading = false
    @Published var isSettingUp = false
    @Published var isCreatingRepo = false
    @Published var error: Error?
    
    private let keychainService = KeychainService.shared
    
    func loadRepositories() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            guard let token = try await keychainService.getAccessToken() else {
                throw AuthError.noAccessToken
            }
            
            var request = URLRequest(url: URL(string: "https://api.github.com/user/repos?sort=updated&per_page=100")!)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw APIError.requestFailed
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            struct GitHubRepo: Decodable {
                let id: Int
                let nodeId: String
                let name: String
                let owner: Owner
                let `private`: Bool
                let description: String?
                
                struct Owner: Decodable {
                    let login: String
                }
            }
            
            let ghRepos = try decoder.decode([GitHubRepo].self, from: data)
            
            self.repositories = ghRepos.map { repo in
                Repository(
                    id: repo.nodeId,
                    name: repo.name,
                    owner: repo.owner.login,
                    isPrivate: repo.private,
                    description: repo.description
                )
            }
            
        } catch {
            self.error = error
        }
    }
    
    func createNewRepository() {
        Task {
            _ = await createNewRepositoryAndSetup()
        }
    }
    
    func createNewRepositoryAndSetup() async -> Repository? {
        isCreatingRepo = true
        defer { isCreatingRepo = false }
        
        do {
            guard let token = try await keychainService.getAccessToken() else {
                throw AuthError.noAccessToken
            }
            
            // Create the repository
            var request = URLRequest(url: URL(string: "https://api.github.com/user/repos")!)
            request.httpMethod = "POST"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body: [String: Any] = [
                "name": "todos",
                "description": "My personal todo list managed by TodoHub",
                "private": true,
                "auto_init": true
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.requestFailed
            }
            
            var newRepo: Repository
            
            if httpResponse.statusCode == 422 {
                // Repository already exists, try to find it
                await loadRepositories()
                if let existingRepo = repositories.first(where: { $0.name == "todos" }) {
                    newRepo = existingRepo
                } else {
                    throw APIError.custom("Repository 'todos' already exists but couldn't be found")
                }
            } else if httpResponse.statusCode == 201 {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                
                struct GitHubRepo: Decodable {
                    let id: Int
                    let nodeId: String
                    let name: String
                    let owner: Owner
                    let `private`: Bool
                    let description: String?
                    
                    struct Owner: Decodable {
                        let login: String
                    }
                }
                
                let ghRepo = try decoder.decode(GitHubRepo.self, from: data)
                
                newRepo = Repository(
                    id: ghRepo.nodeId,
                    name: ghRepo.name,
                    owner: ghRepo.owner.login,
                    isPrivate: ghRepo.private,
                    description: ghRepo.description
                )
                
                // Add to list
                repositories.insert(newRepo, at: 0)
            } else {
                throw APIError.httpError(httpResponse.statusCode)
            }
            
            selectedRepository = newRepo
            
            // Now set up the project
            await setupProjectAndContinue(repository: newRepo)
            
            return newRepo
            
        } catch {
            self.error = error
            return nil
        }
    }
    
    private func createTodosRepository() async {
        isCreatingRepo = true
        defer { isCreatingRepo = false }
        
        do {
            guard let token = try await keychainService.getAccessToken() else {
                throw AuthError.noAccessToken
            }
            
            // Create the repository
            var request = URLRequest(url: URL(string: "https://api.github.com/user/repos")!)
            request.httpMethod = "POST"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body: [String: Any] = [
                "name": "todos",
                "description": "My personal todo list managed by TodoHub",
                "private": true,
                "auto_init": true
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.requestFailed
            }
            
            if httpResponse.statusCode == 422 {
                // Repository already exists, try to find it
                await loadRepositories()
                if let existingRepo = repositories.first(where: { $0.name == "todos" }) {
                    selectedRepository = existingRepo
                    return
                }
                throw APIError.custom("Repository 'todos' already exists")
            }
            
            guard httpResponse.statusCode == 201 else {
                throw APIError.httpError(httpResponse.statusCode)
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            struct GitHubRepo: Decodable {
                let id: Int
                let nodeId: String
                let name: String
                let owner: Owner
                let `private`: Bool
                let description: String?
                
                struct Owner: Decodable {
                    let login: String
                }
            }
            
            let ghRepo = try decoder.decode(GitHubRepo.self, from: data)
            
            let newRepo = Repository(
                id: ghRepo.nodeId,
                name: ghRepo.name,
                owner: ghRepo.owner.login,
                isPrivate: ghRepo.private,
                description: ghRepo.description
            )
            
            // Add to list and select it
            repositories.insert(newRepo, at: 0)
            selectedRepository = newRepo
            
        } catch {
            self.error = error
        }
    }
    
    func setupProjectAndContinue(repository: Repository) async {
        isSettingUp = true
        defer { isSettingUp = false }
        
        do {
            guard let token = try await keychainService.getAccessToken() else {
                throw AuthError.noAccessToken
            }
            
            // Get the user's login
            guard let user = try await keychainService.getUser() else {
                throw AuthError.userFetchFailed
            }
            
            // First, check if a TodoHub project already exists
            let existingProject = try await findExistingProject(owner: repository.owner, token: token)
            
            if let project = existingProject {
                // Use existing project
                saveProjectInfo(project)
                saveRepositoryInfo(repository)
            } else {
                // Create new project
                let newProject = try await createProject(owner: user.login, repoId: repository.id, token: token)
                
                // Add custom fields
                try await addProjectFields(projectId: newProject.id, token: token)
                
                saveProjectInfo(newProject)
                saveRepositoryInfo(repository)
            }
            
        } catch {
            self.error = error
            // Still save repo info so user can continue without project
            saveRepositoryInfo(repository)
        }
    }
    
    private func findExistingProject(owner: String, token: String) async throws -> Project? {
        let query = """
        query FindProject($owner: String!) {
          user(login: $owner) {
            projectsV2(first: 20) {
              nodes {
                id
                number
                title
                url
              }
            }
          }
        }
        """
        
        let result = try await executeGraphQL(query: query, variables: ["owner": owner], token: token)
        
        guard let data = result["data"] as? [String: Any],
              let user = data["user"] as? [String: Any],
              let projects = user["projectsV2"] as? [String: Any],
              let nodes = projects["nodes"] as? [[String: Any]] else {
            return nil
        }
        
        // Look for TodoHub project
        for node in nodes {
            if let title = node["title"] as? String,
               title == Config.defaultProjectName,
               let id = node["id"] as? String,
               let number = node["number"] as? Int,
               let url = node["url"] as? String {
                return Project(id: id, number: number, title: title, url: url)
            }
        }
        
        return nil
    }
    
    private func createProject(owner: String, repoId: String, token: String) async throws -> Project {
        let query = """
        mutation CreateProject($ownerId: ID!, $title: String!) {
          createProjectV2(input: {
            ownerId: $ownerId
            title: $title
          }) {
            projectV2 {
              id
              number
              title
              url
            }
          }
        }
        """
        
        // First get the user's node ID
        let userQuery = """
        query GetUserId($login: String!) {
          user(login: $login) {
            id
          }
        }
        """
        
        let userResult = try await executeGraphQL(query: userQuery, variables: ["login": owner], token: token)
        
        guard let userData = userResult["data"] as? [String: Any],
              let user = userData["user"] as? [String: Any],
              let userId = user["id"] as? String else {
            throw APIError.custom("Could not get user ID")
        }
        
        let variables: [String: Any] = [
            "ownerId": userId,
            "title": Config.defaultProjectName
        ]
        
        let result = try await executeGraphQL(query: query, variables: variables, token: token)
        
        guard let data = result["data"] as? [String: Any],
              let createProject = data["createProjectV2"] as? [String: Any],
              let projectV2 = createProject["projectV2"] as? [String: Any],
              let id = projectV2["id"] as? String,
              let number = projectV2["number"] as? Int,
              let title = projectV2["title"] as? String,
              let url = projectV2["url"] as? String else {
            throw APIError.custom("Failed to create project")
        }
        
        return Project(id: id, number: number, title: title, url: url)
    }
    
    private func addProjectFields(projectId: String, token: String) async throws {
        // Add Due Date field
        let dueDateQuery = """
        mutation AddDueDateField($projectId: ID!) {
          createProjectV2Field(input: {
            projectId: $projectId
            dataType: DATE
            name: "Due Date"
          }) {
            projectV2Field {
              ... on ProjectV2FieldCommon {
                id
                name
              }
            }
          }
        }
        """
        
        _ = try? await executeGraphQL(query: dueDateQuery, variables: ["projectId": projectId], token: token)
        
        // Add Priority field (Single Select) - must be done in two steps
        // Step 1: Create the single select field
        let priorityQuery = """
        mutation AddPriorityField($projectId: ID!) {
          createProjectV2Field(input: {
            projectId: $projectId
            dataType: SINGLE_SELECT
            name: "Priority"
            singleSelectOptions: [
              { name: "High", color: RED, description: "High priority item" }
              { name: "Medium", color: ORANGE, description: "Medium priority item" }
              { name: "Low", color: BLUE, description: "Low priority item" }
            ]
          }) {
            projectV2Field {
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
        """
        
        let result = try? await executeGraphQL(query: priorityQuery, variables: ["projectId": projectId], token: token)
        
        // Check if priority field was created
        if result != nil {
            // Field created successfully with options
            return
        }
        
        // If the above didn't work, try creating without options and adding them separately
        let simplePriorityQuery = """
        mutation AddPriorityField($projectId: ID!) {
          createProjectV2Field(input: {
            projectId: $projectId
            dataType: SINGLE_SELECT
            name: "Priority"
          }) {
            projectV2Field {
              ... on ProjectV2SingleSelectField {
                id
                name
              }
            }
          }
        }
        """
        
        _ = try? await executeGraphQL(query: simplePriorityQuery, variables: ["projectId": projectId], token: token)
        
        // Create project views
        await addProjectViews(projectId: projectId, token: token)
    }
    
    private func addProjectViews(projectId: String, token: String) async {
        // Create "Todo" view with status filter
        let todoViewQuery = """
        mutation CreateTodoView($projectId: ID!) {
          createProjectV2View(input: {
            projectId: $projectId
            name: "Todo"
            layout: TABLE_LAYOUT
          }) {
            projectV2View {
              id
              name
            }
          }
        }
        """
        
        if let result = try? await executeGraphQL(query: todoViewQuery, variables: ["projectId": projectId], token: token),
           let data = result["data"] as? [String: Any],
           let createView = data["createProjectV2View"] as? [String: Any],
           let view = createView["projectV2View"] as? [String: Any],
           let viewId = view["id"] as? String {
            
            // Add filter to the Todo view
            let filterQuery = """
            mutation UpdateTodoViewFilter($projectId: ID!, $viewId: ID!) {
              updateProjectV2View(input: {
                projectId: $projectId
                viewId: $viewId
                filter: "status:Todo"
              }) {
                projectV2View {
                  id
                }
              }
            }
            """
            _ = try? await executeGraphQL(query: filterQuery, variables: ["projectId": projectId, "viewId": viewId], token: token)
        }
        
        // Create "All" view with no filter
        let allViewQuery = """
        mutation CreateAllView($projectId: ID!) {
          createProjectV2View(input: {
            projectId: $projectId
            name: "All"
            layout: TABLE_LAYOUT
          }) {
            projectV2View {
              id
              name
            }
          }
        }
        """
        
        _ = try? await executeGraphQL(query: allViewQuery, variables: ["projectId": projectId], token: token)
    }
    
    private func executeGraphQL(query: String, variables: [String: Any], token: String) async throws -> [String: Any] {
        var request = URLRequest(url: URL(string: "https://api.github.com/graphql")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "query": query,
            "variables": variables
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.requestFailed
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
    
    private func saveProjectInfo(_ project: Project) {
        UserDefaults.standard.set(project.id, forKey: "selectedProjectId")
        if let data = try? JSONEncoder().encode(project) {
            UserDefaults.standard.set(data, forKey: "selectedProjectData")
        }
    }
    
    private func saveRepositoryNodeId(_ nodeId: String) {
        UserDefaults.standard.set(nodeId, forKey: "selectedRepositoryNodeId")
    }
    
    private func saveRepositoryInfo(_ repository: Repository) {
        UserDefaults.standard.set(repository.id, forKey: "selectedRepositoryNodeId")
        UserDefaults.standard.set(repository.owner, forKey: "selectedRepositoryOwner")
        UserDefaults.standard.set(repository.name, forKey: "selectedRepositoryName")
    }
}

enum APIError: LocalizedError {
    case requestFailed
    case invalidResponse
    case notAuthenticated
    case noProjectSelected
    case noRepositorySelected
    case httpError(Int)
    case graphqlError(String)
    case custom(String)
    
    var errorDescription: String? {
        switch self {
        case .requestFailed:
            return "API request failed"
        case .invalidResponse:
            return "Invalid response from server"
        case .notAuthenticated:
            return "Not authenticated"
        case .noProjectSelected:
            return "No project selected"
        case .noRepositorySelected:
            return "No repository selected"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .graphqlError(let message):
            return "GraphQL error: \(message)"
        case .custom(let message):
            return message
        }
    }
}

#Preview {
    RepoSelectionView()
        .environmentObject(AuthViewModel())
}
