# Models - Agent Guidelines

## Overview

Data models representing the domain entities for Todo List. All models are value types (structs) conforming to common protocols.

## Model List

| Model | Purpose |
|-------|---------|
| `Todo` | Main todo item (wraps GitHub Issue) |
| `User` | GitHub user |
| `Repository` | GitHub repository |
| `Project` | GitHub Project v2 |
| `Priority` | High/Medium/Low enum |

## Protocols

All models conform to:
- `Identifiable` - For SwiftUI lists
- `Codable` - For JSON serialization
- `Sendable` - For concurrency safety
- `Hashable` / `Equatable` - For comparison

## Todo Model

The core model representing a todo item:

```swift
struct Todo: Identifiable, Codable, Sendable, Hashable {
    let id: String              // GitHub Issue node ID
    var title: String
    var body: String?
    var isCompleted: Bool       // Issue closed state
    var dueDate: Date?          // From project field
    var priority: Priority?     // From project field
    var assignee: User?
    var repositoryOwner: String
    var repositoryName: String
    var issueNumber: Int
    var createdAt: Date
    var updatedAt: Date
}
```

## Priority Enum

```swift
enum Priority: String, Codable, CaseIterable, Sendable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"
    
    var color: Color { ... }
    var icon: String { ... }
}
```

## Conventions

### Naming
- Use Swift naming conventions (camelCase)
- Match GitHub API field names where possible
- Use optionals for nullable fields

### Initialization
- Provide default values where sensible
- Use memberwise initializer when possible
- Create convenience initializers for common patterns

### Computed Properties
Use computed properties for derived data:
```swift
var isOverdue: Bool {
    guard let dueDate else { return false }
    return dueDate < Date() && !isCompleted
}
```

## Adding a New Model

1. Create `ModelName.swift` in this directory
2. Define as `struct` conforming to `Identifiable, Codable, Sendable, Hashable`
3. Add `id` property for Identifiable
4. Add computed properties for derived values
5. Add sample/mock data for previews if needed
