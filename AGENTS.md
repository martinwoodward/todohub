# TodoHub - Agent Guidelines

## Project Overview

TodoHub is a native iOS application that uses GitHub Issues as a todo list backend. Users authenticate via GitHub OAuth, select/create a repository, and manage todos that are stored as GitHub Issues with GitHub Projects for ordering and custom fields.

## Tech Stack

- **Language:** Swift 5.9
- **UI Framework:** SwiftUI (iOS 17+)
- **Architecture:** MVVM (Model-View-ViewModel)
- **Project Generation:** XcodeGen (project.yml → TodoHub.xcodeproj)
- **Authentication:** OAuth 2.0 with PKCE via AppAuth-iOS
- **API:** GitHub GraphQL API
- **Storage:** GitHub Issues + GitHub Projects v2
- **CI/CD:** GitHub Actions (no Ruby/Fastlane)

## Quick Commands

```bash
# Generate Xcode project (after modifying project.yml)
xcodegen generate

# Build
xcodebuild build -scheme TodoHub -project TodoHub.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  CODE_SIGNING_ALLOWED=NO

# Run tests
xcodebuild test -scheme TodoHub -project TodoHub.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:TodoHubTests CODE_SIGNING_ALLOWED=NO

# Open in Xcode
open TodoHub.xcodeproj
```

## Project Structure

```
TodoHub/
├── App/                    # App entry point (TodoHubApp.swift)
├── Config/                 # OAuth credentials (Config.swift - GITIGNORED)
├── Models/                 # Data models
├── Views/                  # SwiftUI views organized by feature
│   ├── Login/
│   ├── Setup/              # Repository selection
│   ├── TodoList/
│   ├── TodoDetail/
│   ├── AllIssues/
│   ├── Settings/
│   └── Components/
├── ViewModels/             # Business logic and state
├── Services/               # API, Auth, Keychain services
├── Extensions/             # Swift extensions
├── GraphQL/                # Query definitions
└── Resources/              # Assets
```

## Key Files

| File | Purpose |
|------|---------|
| `project.yml` | XcodeGen config - edit this, not .xcodeproj |
| `Config.swift.template` | Template for OAuth credentials |
| `Config.swift` | Actual credentials (gitignored) |
| `GitHubAuthService.swift` | OAuth flow implementation |
| `GitHubAPIService.swift` | GraphQL API calls |
| `AuthViewModel.swift` | Authentication state management |
| `TodoListViewModel.swift` | Main todo list logic |
| `RepoSelectionView.swift` | Repository creation and project setup |

## Conventions

### Swift/SwiftUI
- Use `@Observable` macro for ViewModels (iOS 17+)
- Use `@MainActor` for UI-bound classes
- Prefer `async/await` over completion handlers
- Use `Sendable` for thread-safe types

### Naming
- ViewModels: `*ViewModel` (e.g., `TodoListViewModel`)
- Views: Descriptive names (e.g., `TodoRowView`, `QuickAddView`)
- Services: `*Service` (e.g., `GitHubAPIService`)

### Error Handling
- Use `APIError` enum for all API errors
- Display user-friendly error messages via alerts
- Log errors for debugging

### GitHub API
- Use GraphQL for all GitHub API calls (not REST)
- Queries defined in `GraphQL/` directory
- Token stored securely in Keychain

## Configuration

OAuth credentials must be configured before running:

```bash
cp TodoHub/Config/Config.swift.template TodoHub/Config/Config.swift
# Edit Config.swift with your GitHub OAuth App credentials
```

Create OAuth App at: https://github.com/settings/developers
- Callback URL: `todohub://oauth-callback`
- Scopes needed: `repo`, `read:user`, `read:org`, `project`

## GitHub Integration

### How Todos Work
1. Each todo is a GitHub Issue in the user's selected repository
2. Issues are organized in a GitHub Project named "TodoHub"
3. Custom project fields store metadata:
   - **Due Date** (DATE type)
   - **Priority** (SINGLE_SELECT: High/Medium/Low)
4. Completing a todo closes the issue
5. Reassigning removes it from user's todo list

### Key GraphQL Operations
- `viewer` - Get authenticated user
- `repository.issues` - List todos
- `createIssue` - Create todo
- `updateIssue` - Update todo
- `closeIssue` - Complete todo
- `createProjectV2` - Create project
- `updateProjectV2ItemFieldValue` - Set due date/priority

## Testing

- Unit tests in `TodoHubTests/`
- UI tests in `TodoHubUITests/`
- Tests use mock data, not real GitHub API
- Run tests before committing changes

## CI/CD

Three GitHub Actions workflows:
- `build.yml` - Build on push/PR to main
- `test.yml` - Run unit tests
- `deploy-testflight.yml` - Deploy on version tags (v*)

See `TESTFLIGHT_SETUP.md` for deployment configuration.

## Common Tasks

### Adding a New View
1. Create view in appropriate `Views/` subdirectory
2. Create ViewModel if needed in `ViewModels/`
3. Wire up navigation in parent view

### Adding a New API Call
1. Add GraphQL query/mutation in `GraphQL/`
2. Add method to `GitHubAPIService`
3. Call from ViewModel

### Modifying Build Settings
1. Edit `project.yml` (not the .xcodeproj directly)
2. Run `xcodegen generate`
3. Rebuild

## Troubleshooting

### "No such module 'AppAuth'"
Run: `xcodebuild -resolvePackageDependencies -scheme TodoHub -project TodoHub.xcodeproj`

### Actor isolation errors
Ensure `@MainActor` is applied to classes that update UI. Use `await MainActor.run {}` when calling from non-main contexts.

### OAuth callback not working
Verify URL scheme `todohub` is registered in Info.plist and matches Config.swift settings.
