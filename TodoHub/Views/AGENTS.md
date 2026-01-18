# Views - Agent Guidelines

## Overview

All SwiftUI views for Todo List are organized in this directory by feature area.

## Directory Structure

```
Views/
├── Login/          # GitHub OAuth login
├── Setup/          # Repository selection and creation
├── TodoList/       # Main todo list interface
├── TodoDetail/     # Todo editing screen
├── AllIssues/      # Cross-repository issues view
├── Settings/       # App settings
└── Components/     # Reusable UI components
```

## View Conventions

### Structure
- One view per file
- Views should be lightweight - business logic goes in ViewModels
- Use `@State` for local UI state, `@Bindable` for ViewModel binding
- Prefer composition over large monolithic views

### Naming
- Main views: `FeatureView` (e.g., `LoginView`, `SettingsView`)
- Row/cell views: `*RowView` (e.g., `TodoRowView`, `IssueRowView`)
- Subcomponents: Descriptive names (e.g., `QuickAddView`, `PriorityBadge`)

### Example View Pattern
```swift
import SwiftUI

struct ExampleView: View {
    @State private var viewModel = ExampleViewModel()
    
    var body: some View {
        NavigationStack {
            List {
                // Content
            }
            .navigationTitle("Example")
        }
        .task {
            await viewModel.load()
        }
    }
}
```

## Key Views

| View | Purpose |
|------|---------|
| `LoginView` | GitHub OAuth sign-in button |
| `RepoSelectionView` | Pick or create repository for todos |
| `TodoListView` | Main todo list with sections |
| `TodoRowView` | Individual todo item display |
| `QuickAddView` | Inline todo creation |
| `TodoDetailView` | Full todo editing (title, description, due date, priority) |
| `AllIssuesView` | All GitHub issues assigned to user |
| `SettingsView` | Theme selection, sign out |

## Component Guidelines

Components in `Components/` should be:
- Reusable across multiple views
- Self-contained with no external dependencies
- Configurable via parameters

Current components:
- `PriorityBadge` - Colored priority indicator
- `DueDateBadge` - Due date with overdue styling
- `LoadingView` - Centered spinner with optional message

## Navigation

- Use `NavigationStack` as the root navigation container
- Use `NavigationLink` for push navigation
- Use `.sheet()` for modal presentation
- Main app uses tab-based navigation in `ContentView`
