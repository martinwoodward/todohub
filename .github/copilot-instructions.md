# GitHub Copilot Custom Instructions for TodoHub

## Project Overview

TodoHub is a native iOS application that uses GitHub Issues as a todo list backend. Users authenticate via GitHub OAuth, select/create a repository, and manage todos that are stored as GitHub Issues with GitHub Projects v2 for ordering and custom fields.

## Tech Stack

- **Language:** Swift 5.9
- **UI Framework:** SwiftUI (iOS 17+)
- **Architecture:** MVVM (Model-View-ViewModel)
- **Project Generation:** XcodeGen (project.yml → TodoHub.xcodeproj)
- **Authentication:** OAuth 2.0 with PKCE via AppAuth-iOS
- **API:** GitHub GraphQL API (NOT REST)
- **Storage:** GitHub Issues + GitHub Projects v2
- **CI/CD:** GitHub Actions + Fastlane (deployment only)

## Code Review Priorities

When reviewing code, prioritize:

1. **Security** - OAuth credentials, token storage, API security
2. **App Store Compliance** - Follow Apple App Store Review Guidelines (see `instructions/apple-appstore-reviewer.instructions.md`)
3. **Swift Concurrency** - Proper use of async/await, actor isolation, Sendable
4. **MVVM Pattern** - Clear separation between Views, ViewModels, and Services
5. **GraphQL Usage** - Efficient queries, proper error handling
6. **iOS 17+ Features** - Modern SwiftUI patterns, @Observable macro

## App Store Compliance

This app targets the Apple App Store. When reviewing or generating code, always consider:

### Privacy & Permissions
- All permission usage strings (`NS*UsageDescription`) must be clear and specific
- Never request permissions at launch without justification
- Privacy manifest (`PrivacyInfo.xcprivacy`) must accurately reflect data collection

### Authentication
- GitHub OAuth is the only authentication method (no Apple Sign-In requirement)
- Account deletion must be accessible if account creation exists
- Clear explanation of why account is required

### Technical Quality
- Handle network errors gracefully with user-friendly messages
- Provide meaningful empty states (no blank screens)
- Support offline scenarios where appropriate
- No crashes or dead-end states

### Reviewer Experience
- First-run experience should clearly show app purpose
- Core features accessible without complex setup
- Onboarding should explain key features

For detailed App Store review guidance, see `instructions/apple-appstore-reviewer.instructions.md`

## Critical Conventions

### Swift/SwiftUI
- ✅ Use `@Observable` macro for ViewModels (iOS 17+)
- ✅ Use `@MainActor` for UI-bound classes
- ✅ Prefer `async/await` over completion handlers
- ✅ Use `Sendable` for thread-safe types
- ❌ Avoid force unwrapping (`!`) unless absolutely safe
- ❌ Don't use Combine or older state management patterns

### Architecture
- **ViewModels**: Business logic, state management, marked with `@Observable` and `@MainActor`
- **Views**: UI only, lightweight, use `@State` for local state and `@Bindable` for ViewModel binding
- **Services**: Stateless, thread-safe, handle external APIs
- **Models**: Value types (structs), conform to `Identifiable`, `Codable`, `Sendable`, `Hashable`

### Naming Conventions
- ViewModels: `*ViewModel` (e.g., `TodoListViewModel`, `AuthViewModel`)
- Views: Descriptive names (e.g., `TodoRowView`, `QuickAddView`, `LoginView`)
- Services: `*Service` (e.g., `GitHubAPIService`, `KeychainService`)
- Row/cell views: `*RowView` suffix

### Error Handling
- Use `APIError` enum for all API errors
- Display user-friendly error messages via alerts
- Log errors for debugging with clear context
- Never expose raw error messages to users

### GitHub API
- ✅ Use GraphQL for ALL GitHub API calls (not REST)
- ✅ Queries defined in `GraphQL/` directory
- ✅ Token stored securely in Keychain via `KeychainService`
- ✅ Handle rate limiting and network errors gracefully

## Project Structure

```
TodoHub/
├── App/                    # App entry point (TodoHubApp.swift)
├── Config/                 # OAuth credentials (Config.swift - GITIGNORED)
├── Models/                 # Data models (Todo, User, Repository, Priority)
├── Views/                  # SwiftUI views organized by feature
│   ├── Login/             # GitHub OAuth login
│   ├── Setup/             # Repository selection
│   ├── TodoList/          # Main todo list interface
│   ├── TodoDetail/        # Todo editing screen
│   ├── AllIssues/         # Cross-repository issues view
│   ├── Settings/          # App settings
│   └── Components/        # Reusable UI components
├── ViewModels/            # Business logic and state
├── Services/              # API, Auth, Keychain services
├── Extensions/            # Swift extensions
├── GraphQL/               # Query definitions
└── Resources/             # Assets
```

## Key Files and Their Purpose

| File | Purpose | Edit Carefully |
|------|---------|----------------|
| `project.yml` | XcodeGen config - edit this, NOT .xcodeproj | ⚠️ Yes |
| `Config.swift` | OAuth credentials (gitignored) | 🔒 Never commit |
| `Config.swift.template` | Template for OAuth credentials | ✅ Safe |
| `GitHubAuthService.swift` | OAuth flow implementation | 🔒 Security critical |
| `GitHubAPIService.swift` | GraphQL API calls | ⚠️ Core service |
| `KeychainService.swift` | Secure token storage | 🔒 Security critical |
| `AuthViewModel.swift` | Authentication state | ⚠️ Core logic |
| `TodoListViewModel.swift` | Main todo list logic | ⚠️ Core logic |

## Common Patterns

### ViewModel Pattern
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
    
    func load() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            items = try await apiService.fetchItems()
        } catch {
            self.error = error
        }
    }
}
```

### View Pattern
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

### Service Pattern
```swift
final class ExampleService: Sendable {
    func fetchData() async throws -> Data {
        // Use async/await
        // Handle errors with APIError
        // Make thread-safe
    }
}
```

## GitHub Integration Details

### How Todos Work
1. Each todo is a GitHub Issue in the user's selected repository
2. Issues are organized in a GitHub Project named "Todo List"
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

## Build & Test Commands

```bash
# Generate Xcode project (after modifying project.yml)
xcodegen generate

# Build for simulator
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

## Common Workflows

### Adding a New View
1. Create view in appropriate `Views/` subdirectory
2. Create ViewModel if needed in `ViewModels/`
3. Wire up navigation in parent view
4. Follow naming conventions

### Adding a New API Call
1. Add GraphQL query/mutation in `GraphQL/`
2. Add method to `GitHubAPIService`
3. Call from ViewModel using async/await
4. Handle errors with `APIError` enum

### Modifying Build Settings
1. Edit `project.yml` (NOT the .xcodeproj directly)
2. Run `xcodegen generate`
3. Rebuild project

## Security Checklist

When reviewing code, ensure:

- [ ] No OAuth credentials in code (use Config.swift which is gitignored)
- [ ] Tokens stored in Keychain, never UserDefaults
- [ ] PKCE used for OAuth flow
- [ ] GraphQL queries sanitized (no injection)
- [ ] Error messages don't leak sensitive info
- [ ] Network calls use HTTPS
- [ ] Proper actor isolation for thread safety

## CI/CD

Three GitHub Actions workflows:
- `build.yml` - Build on push/PR to main (native xcodebuild)
- `test.yml` - Run unit tests on push/PR to main (native xcodebuild)
- `deploy-testflight.yml` - Deploy on version tags (v*) using Fastlane

**Fastlane is permitted ONLY for the TestFlight deployment workflow.** Build and test workflows must use native `xcodebuild` commands directly. Do not add Fastlane to build or test CI steps.

Fastlane configuration:
- `Gemfile` - Ruby dependency definition (fastlane gem)
- `fastlane/Appfile` - App identifier config
- `fastlane/Fastfile` - Deployment lane (`beta`)

All workflows use:
- `macos-26` runner (Apple Silicon)
- Xcode 26.2
- iPhone 17 Pro simulator (build/test)

## Testing Guidelines

- Unit tests in `TodoHubTests/`
- UI tests in `TodoHubUITests/`
- Tests use mock data, NOT real GitHub API
- Run tests before committing changes
- ViewModels should be testable with mock services

## Common Issues to Watch For

### Actor Isolation Errors
- Ensure `@MainActor` is applied to classes that update UI
- Use `await MainActor.run {}` when calling from non-main contexts

### OAuth Callback Issues
- Verify URL scheme `todohub` is registered in Info.plist
- Ensure callback URL matches Config.swift settings

### Module Not Found
- Run: `xcodebuild -resolvePackageDependencies -scheme TodoHub -project TodoHub.xcodeproj`

## Documentation Standards

- Add comments for complex business logic
- Document GraphQL queries with purpose and fields
- Keep README.md updated with new features
- Update AGENTS.md files when patterns change

## What NOT to Do

❌ Don't edit `.xcodeproj` directly - edit `project.yml` instead
❌ Don't commit `Config.swift` - it's gitignored for security
❌ Don't use REST API - use GraphQL only
❌ Don't use Combine - use async/await
❌ Don't store tokens in UserDefaults - use Keychain
❌ Don't force unwrap in production code without clear safety
❌ Don't add Ruby or Fastlane to build/test CI - only deployment uses Fastlane
❌ Don't break MVVM pattern - keep Views lightweight
❌ Don't request permissions without clear usage description strings
❌ Don't leave dead-end states or empty screens without explanation
❌ Don't collect user data without proper privacy manifest disclosure
