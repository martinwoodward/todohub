# Services - Agent Guidelines

## Overview

Services handle external communication and platform APIs. They are designed to be stateless and thread-safe.

## Available Services

### GitHubAuthService
Handles OAuth 2.0 authentication with GitHub.

```swift
let authService = GitHubAuthService()
let token = try await authService.exchangeCode(code)
```

- Uses AppAuth-iOS for OAuth flow
- Implements PKCE for security
- Returns access token on success

### GitHubAPIService
All GitHub API communication via GraphQL.

```swift
let apiService = GitHubAPIService(token: accessToken)
let user = try await apiService.fetchCurrentUser()
let issues = try await apiService.fetchIssues(owner: "user", repo: "todos")
```

Key methods:
- `fetchCurrentUser()` - Get authenticated user
- `fetchUserRepositories()` - List user's repos
- `fetchIssues(owner:repo:)` - Get issues from repo
- `createIssue(owner:repo:title:body:)` - Create new issue
- `updateIssue(...)` - Update issue
- `closeIssue(...)` - Close/complete issue
- `createRepository(name:)` - Create new repo
- `createProject(owner:repo:name:)` - Create GitHub Project
- `updateProjectField(...)` - Set due date, priority

### KeychainService
Secure storage for OAuth tokens.

```swift
KeychainService.save(token, forKey: "github_token")
let token = KeychainService.load(forKey: "github_token")
KeychainService.delete(forKey: "github_token")
```

## Design Principles

### Thread Safety
- Services are `Sendable` or use actors
- All async methods are safe to call from any context
- UI updates happen on `@MainActor` in ViewModels, not Services

### Error Handling
All service errors use the `APIError` enum:
```swift
enum APIError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case httpError(Int)
    case unauthorized
    case notFound
    case graphQLError(String)
}
```

### GraphQL
- All GitHub API calls use GraphQL, not REST
- Queries are constructed as string literals
- Responses are decoded with Codable

## Adding a New Service

1. Create `NewService.swift` in this directory
2. Make it `final class` with `Sendable` or use `actor`
3. Use `async throws` for all external operations
4. Handle errors with `APIError`
5. Add to dependency injection in ViewModels as needed
