# ViewModels - Agent Guidelines

## Overview

ViewModels contain business logic and state management for views. They follow the MVVM pattern and use Swift's modern concurrency features.

## Available ViewModels

| ViewModel | Purpose |
|-----------|---------|
| `AuthViewModel` | Authentication state, sign in/out |
| `TodoListViewModel` | Main todo list, CRUD operations |
| `AllIssuesViewModel` | Cross-repo issues, filtering |

## ViewModel Pattern

```swift
import SwiftUI

@Observable
@MainActor
final class ExampleViewModel {
    // Published state
    var items: [Item] = []
    var isLoading = false
    var error: Error?
    
    // Dependencies
    private let apiService: GitHubAPIService
    
    init(apiService: GitHubAPIService = .shared) {
        self.apiService = apiService
    }
    
    // Async actions
    func load() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            items = try await apiService.fetchItems()
        } catch {
            self.error = error
        }
    }
    
    func createItem(title: String) async {
        do {
            let item = try await apiService.createItem(title: title)
            items.append(item)
        } catch {
            self.error = error
        }
    }
}
```

## Key Conventions

### Annotations
- `@Observable` - Makes properties observable (iOS 17+)
- `@MainActor` - Ensures UI updates on main thread

### State Properties
- `isLoading: Bool` - Loading indicator state
- `error: Error?` - Last error for display
- Collection properties for list data
- Selected item properties for detail views

### Methods
- `load()` / `refresh()` - Initial data fetch
- `create*()` - Create operations
- `update*()` - Update operations  
- `delete*()` - Delete operations
- All mutating methods are `async`

### Error Handling
```swift
do {
    // API call
} catch {
    self.error = error
    // Optionally show alert
}
```

## AuthViewModel

Manages authentication state across the app:

```swift
@Observable
@MainActor
final class AuthViewModel {
    var isAuthenticated = false
    var currentUser: User?
    var selectedRepository: Repository?
    
    func signIn() async { ... }
    func signOut() { ... }
    func handleCallback(url: URL) async { ... }
}
```

Shared instance available as `@Environment` in views.

## TodoListViewModel

Main todo list logic:

```swift
@Observable  
@MainActor
final class TodoListViewModel {
    var todos: [Todo] = []
    var sections: [TodoSection] = []  // Grouped by date
    
    func loadTodos() async { ... }
    func createTodo(title: String) async { ... }
    func completeTodo(_ todo: Todo) async { ... }
    func updateTodo(_ todo: Todo) async { ... }
    func deleteTodo(_ todo: Todo) async { ... }
}
```

## Testing ViewModels

ViewModels should be testable with mock services:

```swift
func testLoadTodos() async {
    let mockService = MockGitHubAPIService()
    mockService.mockTodos = [Todo.sample]
    
    let viewModel = TodoListViewModel(apiService: mockService)
    await viewModel.load()
    
    XCTAssertEqual(viewModel.todos.count, 1)
}
```
