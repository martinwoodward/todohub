# TodoHub - iOS GitHub Issues Todo App

## Implementation Plan

**Project Name:** TodoHub  
**Platform:** iOS (Native SwiftUI)  
**Backend:** GitHub Issues + GitHub Projects API  
**License:** MIT - Copyright Martin Woodward  

---

## 📋 Executive Summary

TodoHub is a native iOS application that uses GitHub Issues as the storage backend for personal todo items. Users authenticate via GitHub OAuth, select a repository for storing their todos, and manage tasks through an intuitive, minimal interface. Issues are organized via GitHub Projects for ordering support, with custom fields for due dates and priority.

---

## 🎨 UI/UX Design Philosophy

Based on 2025 iOS design trends research:

### Design Principles
1. **Minimalist Task-First Interface** - Clean, distraction-free layouts (inspired by Todoist, Clear)
2. **Liquid Glass Design** - Apple's 2025 translucent, layered UI elements
3. **Gesture-Driven Navigation** - Swipe to complete/delete, drag-to-reorder
4. **Microinteractions** - Satisfying animations for task completion
5. **Dark/Light Mode** - Full support with high-contrast colors
6. **Accessibility First** - Dynamic Type, VoiceOver, large touch targets

### UI Inspiration Sources
- Todoist (minimal task-first design)
- Clear (gesture-based interactions)
- Things 3 (elegant organization)
- Apple Reminders (native iOS feel)

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                         TodoHub App                          │
├─────────────────────────────────────────────────────────────┤
│  Presentation Layer (SwiftUI)                                │
│  ┌─────────────┬─────────────┬─────────────┬───────────────┐ │
│  │   Login     │  Todo List  │  All Issues │   Settings    │ │
│  │   View      │    View     │    View     │     View      │ │
│  └─────────────┴─────────────┴─────────────┴───────────────┘ │
├─────────────────────────────────────────────────────────────┤
│  ViewModel Layer (ObservableObject)                          │
│  ┌─────────────┬─────────────┬─────────────┬───────────────┐ │
│  │   Auth      │    Todo     │   Issues    │    Settings   │ │
│  │   ViewModel │  ViewModel  │  ViewModel  │   ViewModel   │ │
│  └─────────────┴─────────────┴─────────────┴───────────────┘ │
├─────────────────────────────────────────────────────────────┤
│  Service Layer                                               │
│  ┌─────────────┬─────────────┬─────────────────────────────┐ │
│  │   GitHub    │   GitHub    │       Keychain              │ │
│  │   Auth      │   API       │       Storage               │ │
│  │   Service   │   Service   │       Service               │ │
│  └─────────────┴─────────────┴─────────────────────────────┘ │
├─────────────────────────────────────────────────────────────┤
│  Network Layer                                               │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │           Apollo iOS (GraphQL Client)                    │ │
│  │           + REST API for OAuth                           │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      GitHub Backend                          │
│  ┌─────────────┬─────────────┬─────────────────────────────┐ │
│  │   OAuth     │   GraphQL   │        REST API             │ │
│  │   Server    │   API       │        (fallback)           │ │
│  └─────────────┴─────────────┴─────────────────────────────┘ │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                  GitHub Projects v2                      │ │
│  │   - Custom Fields (Due Date, Priority)                   │ │
│  │   - Item Ordering                                        │ │
│  │   - Board Views                                          │ │
│  └─────────────────────────────────────────────────────────┘ │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                    GitHub Issues                         │ │
│  │   - Todo Items (title, description)                      │ │
│  │   - Assignees                                            │ │
│  │   - State (open/closed)                                  │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

---

## 📱 Screen-by-Screen Specifications

### 1. Login/Onboarding Screen

```
┌─────────────────────────────────────┐
│                                     │
│                                     │
│            ┌───────────┐            │
│            │  TodoHub  │            │
│            │   Logo    │            │
│            └───────────┘            │
│                                     │
│         Your todos, backed          │
│           by GitHub.                │
│                                     │
│    ┌─────────────────────────┐      │
│    │  ◆  Sign in with GitHub │      │
│    └─────────────────────────┘      │
│                                     │
│                                     │
│         ─────────────────           │
│                                     │
│      🔒 Secure OAuth Login          │
│      📱 Works with any repo         │
│      ✅ Syncs automatically         │
│                                     │
└─────────────────────────────────────┘
```

**Features:**
- GitHub OAuth 2.0 with PKCE
- In-app browser (ASWebAuthenticationSession)
- Scopes: `repo`, `read:user`, `read:org`, `project`

---

### 2. Repository Selection Screen (First-time Setup)

```
┌─────────────────────────────────────┐
│  ←  Select Repository               │
├─────────────────────────────────────┤
│                                     │
│  Choose a repository for your       │
│  personal todo list:                │
│                                     │
│  ┌─────────────────────────────┐    │
│  │  🔍 Search repositories...   │    │
│  └─────────────────────────────┘    │
│                                     │
│  SUGGESTED                          │
│  ┌─────────────────────────────┐    │
│  │  ➕  Create new "todos" repo│    │
│  └─────────────────────────────┘    │
│                                     │
│  YOUR REPOSITORIES                  │
│  ┌─────────────────────────────┐    │
│  │ 📁  martinwoodward/todos    │ ◉  │
│  ├─────────────────────────────┤    │
│  │ 📁  martinwoodward/notes    │ ○  │
│  ├─────────────────────────────┤    │
│  │ 📁  martinwoodward/tasks    │ ○  │
│  └─────────────────────────────┘    │
│                                     │
│    ┌─────────────────────────┐      │
│    │       Continue →        │      │
│    └─────────────────────────┘      │
└─────────────────────────────────────┘
```

**Features:**
- Search user's repositories
- Create new repository option
- Auto-setup GitHub Project board

---

### 3. Main Todo List View (Primary Screen)

```
┌─────────────────────────────────────┐
│  ☰  TodoHub            ⚙️   👤      │
├─────────────────────────────────────┤
│                                     │
│  TODAY                    + Add     │
│  ┌─────────────────────────────┐    │
│  │ ○  Review PR for auth fix   │ !  │
│  │    🔴 High Priority  📅 Today│    │
│  ├─────────────────────────────┤    │
│  │ ○  Update documentation     │    │
│  │    🟡 Medium      📅 Today  │    │
│  └─────────────────────────────┘    │
│                                     │
│  UPCOMING                           │
│  ┌─────────────────────────────┐    │
│  │ ○  Plan sprint goals        │    │
│  │    🟢 Normal      📅 Jan 20 │    │
│  ├─────────────────────────────┤    │
│  │ ○  Write blog post          │    │
│  │    🟡 Medium      📅 Jan 22 │    │
│  └─────────────────────────────┘    │
│                                     │
│  NO DUE DATE                        │
│  ┌─────────────────────────────┐    │
│  │ ○  Research new frameworks  │    │
│  │ ○  Clean up old branches    │    │
│  └─────────────────────────────┘    │
│                                     │
├─────────────────────────────────────┤
│   📋        🌐        ⚙️            │
│  My Todos   All       Settings      │
└─────────────────────────────────────┘
```

**Interactions:**
- **Tap checkbox** → Complete todo (close issue)
- **Swipe left** → Delete / Archive
- **Swipe right** → Quick mark done ✓
- **Long press** → Drag to reorder
- **Tap todo** → Open detail view
- **Pull down** → Refresh from GitHub

---

### 4. Todo Detail/Edit View

```
┌─────────────────────────────────────┐
│  ←  Back                     Save   │
├─────────────────────────────────────┤
│                                     │
│  ┌─────────────────────────────┐    │
│  │ Review PR for auth fix      │    │
│  │                             │    │
│  └─────────────────────────────┘    │
│                                     │
│  DESCRIPTION                        │
│  ┌─────────────────────────────┐    │
│  │ Need to review the PR from  │    │
│  │ @teammate for the OAuth     │    │
│  │ authentication refactor.    │    │
│  │                             │    │
│  │ - Check security impl       │    │
│  │ - Test edge cases           │    │
│  │ - Review error handling     │    │
│  └─────────────────────────────┘    │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  📅  Due Date        January 17     │
│  ─────────────────────────────────  │
│  🚦  Priority        🔴 High        │
│  ─────────────────────────────────  │
│  👤  Assigned to     @martinw       │
│  ─────────────────────────────────  │
│  🔗  GitHub Issue    #42 →          │
│  ─────────────────────────────────  │
│                                     │
│    ┌─────────────────────────┐      │
│    │  🗑️  Delete Todo         │      │
│    └─────────────────────────┘      │
│                                     │
└─────────────────────────────────────┘
```

**Features:**
- Markdown support in description
- Date picker for due date
- Priority selector (High/Medium/Low/None)
- Reassign to other collaborators
- Direct link to GitHub issue

---

### 5. All Issues View (Cross-Repository)

```
┌─────────────────────────────────────┐
│  ←  All Assigned Issues      🔍     │
├─────────────────────────────────────┤
│                                     │
│  ┌─────────────────────────────┐    │
│  │ Filter: All ▼  │ Org: All ▼ │    │
│  └─────────────────────────────┘    │
│                                     │
│  martinwoodward/project-alpha       │
│  ┌─────────────────────────────┐    │
│  │ ○  Fix login bug        #23 │ ➕ │
│  │    2 days ago               │    │
│  ├─────────────────────────────┤    │
│  │ ○  Add unit tests       #45 │ ➕ │
│  │    5 days ago               │    │
│  └─────────────────────────────┘    │
│                                     │
│  github/copilot-cli                 │
│  ┌─────────────────────────────┐    │
│  │ ○  Review docs PR       #89 │ ➕ │
│  │    1 day ago                │    │
│  └─────────────────────────────┘    │
│                                     │
│  microsoft/vscode                   │
│  ┌─────────────────────────────┐    │
│  │ ○  Investigate perf     #12 │ ➕ │
│  │    3 days ago               │    │
│  └─────────────────────────────┘    │
│                                     │
│  ─────────────────────────────────  │
│  ➕ = Add to My Todo List           │
│                                     │
└─────────────────────────────────────┘
```

**Features:**
- Shows all issues assigned to user across GitHub
- Filter by organization
- Filter by repository
- One-tap to mark done
- Add to main todo list (creates link/copy)

---

### 6. Quick Add Modal

```
┌─────────────────────────────────────┐
│                                     │
│  ┌─────────────────────────────┐    │
│  │                             │    │
│  │  What do you need to do?    │    │
│  │  __________________________ │    │
│  │                             │    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌──────┐ ┌──────┐ ┌──────────┐    │
│  │ 📅   │ │ 🚦   │ │ ➕ Create │    │
│  │Today │ │ Med  │ │          │    │
│  └──────┘ └──────┘ └──────────┘    │
│                                     │
└─────────────────────────────────────┘
```

**Features:**
- Minimal friction task entry
- Optional quick-set date
- Optional quick-set priority
- Keyboard-first design

---

### 7. Settings View

```
┌─────────────────────────────────────┐
│  ←  Settings                        │
├─────────────────────────────────────┤
│                                     │
│  ACCOUNT                            │
│  ┌─────────────────────────────┐    │
│  │ 👤  @martinwoodward          │    │
│  │     Martin Woodward          │    │
│  │     View on GitHub →         │    │
│  └─────────────────────────────┘    │
│                                     │
│  TODO REPOSITORY                    │
│  ┌─────────────────────────────┐    │
│  │ 📁  martinwoodward/todos    │    │
│  │     Change Repository →      │    │
│  └─────────────────────────────┘    │
│                                     │
│  APPEARANCE                         │
│  ┌─────────────────────────────┐    │
│  │ 🌓  Theme          System ▼ │    │
│  ├─────────────────────────────┤    │
│  │ 🔤  Text Size      Default  │    │
│  └─────────────────────────────┘    │
│                                     │
│  SYNC                               │
│  ┌─────────────────────────────┐    │
│  │ 🔄  Last synced: Just now   │    │
│  │     Sync Now                 │    │
│  └─────────────────────────────┘    │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│    ┌─────────────────────────┐      │
│    │    Sign Out              │      │
│    └─────────────────────────┘      │
│                                     │
│  TodoHub v1.0.0                     │
│  Made with ♥ by Martin Woodward    │
│                                     │
└─────────────────────────────────────┘
```

---

## 📂 Project Structure

```
TodoHub/
├── TodoHub.xcodeproj/
├── TodoHub/
│   ├── App/
│   │   ├── TodoHubApp.swift           # App entry point
│   │   └── AppDelegate.swift          # OAuth callback handling
│   │
│   ├── Models/
│   │   ├── Todo.swift                 # Core todo model
│   │   ├── User.swift                 # GitHub user model
│   │   ├── Repository.swift           # Repository model
│   │   ├── Project.swift              # GitHub Project model
│   │   └── Priority.swift             # Priority enum
│   │
│   ├── Views/
│   │   ├── Login/
│   │   │   └── LoginView.swift
│   │   ├── Setup/
│   │   │   └── RepoSelectionView.swift
│   │   ├── TodoList/
│   │   │   ├── TodoListView.swift
│   │   │   ├── TodoRowView.swift
│   │   │   └── QuickAddView.swift
│   │   ├── TodoDetail/
│   │   │   └── TodoDetailView.swift
│   │   ├── AllIssues/
│   │   │   ├── AllIssuesView.swift
│   │   │   └── IssueRowView.swift
│   │   ├── Settings/
│   │   │   └── SettingsView.swift
│   │   └── Components/
│   │       ├── PriorityBadge.swift
│   │       ├── DueDateBadge.swift
│   │       └── LoadingView.swift
│   │
│   ├── ViewModels/
│   │   ├── AuthViewModel.swift
│   │   ├── TodoListViewModel.swift
│   │   ├── TodoDetailViewModel.swift
│   │   ├── AllIssuesViewModel.swift
│   │   └── SettingsViewModel.swift
│   │
│   ├── Services/
│   │   ├── GitHubAuthService.swift    # OAuth handling
│   │   ├── GitHubAPIService.swift     # GraphQL/REST API
│   │   ├── KeychainService.swift      # Secure token storage
│   │   └── SyncService.swift          # Background sync
│   │
│   ├── GraphQL/
│   │   ├── schema.graphqls            # GitHub GraphQL schema
│   │   ├── Queries/
│   │   │   ├── GetUser.graphql
│   │   │   ├── GetRepositories.graphql
│   │   │   ├── GetProjectItems.graphql
│   │   │   └── GetAssignedIssues.graphql
│   │   └── Mutations/
│   │       ├── CreateIssue.graphql
│   │       ├── UpdateIssue.graphql
│   │       ├── CloseIssue.graphql
│   │       └── UpdateProjectItem.graphql
│   │
│   ├── Extensions/
│   │   ├── Date+Extensions.swift
│   │   ├── Color+Theme.swift
│   │   └── View+Extensions.swift
│   │
│   ├── Resources/
│   │   ├── Assets.xcassets/
│   │   └── Localizable.strings
│   │
│   └── Config/
│       └── Secrets.swift              # OAuth credentials (gitignored)
│
├── TodoHubTests/
│   ├── ViewModels/
│   ├── Services/
│   └── Mocks/
│
├── TodoHubUITests/
│
│
├── .github/
│   └── workflows/
│       ├── build.yml
│       ├── test.yml
│       └── deploy-testflight.yml
│
├── README.md
├── LICENSE
├── IMPLEMENTATION_PLAN.md
└── .gitignore
```

---

## 🔧 Technical Implementation Details

### Phase 1: Project Setup & Authentication

#### 1.1 Create Xcode Project
- New SwiftUI App (iOS 17.0+)
- Bundle ID: `com.martinwoodward.todohub`
- Enable Swift Concurrency

#### 1.2 Dependencies (Swift Package Manager)
```swift
// Package.swift dependencies
dependencies: [
    .package(url: "https://github.com/apollographql/apollo-ios.git", from: "1.0.0"),
    .package(url: "https://github.com/openid/AppAuth-iOS.git", from: "1.7.0"),
    .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.0")
]
```

#### 1.3 GitHub OAuth App Registration
1. Go to GitHub Settings → Developer Settings → OAuth Apps
2. Create new OAuth App:
   - **Name:** TodoHub
   - **Homepage URL:** `https://github.com/martinwoodward/todohub`
   - **Callback URL:** `todohub://oauth-callback`
3. Note Client ID and Client Secret

#### 1.4 OAuth Implementation
- Use AppAuth-iOS with PKCE
- Required scopes: `repo`, `read:user`, `read:org`, `project`
- Store tokens securely in Keychain

### Phase 2: Core Data Models & GitHub API Integration

#### 2.1 GraphQL Schema Setup
- Download GitHub GraphQL schema
- Configure Apollo code generation
- Create typed queries and mutations

#### 2.2 Key GraphQL Operations

**Get Project Items (Todos):**
```graphql
query GetProjectItems($projectId: ID!, $first: Int!) {
  node(id: $projectId) {
    ... on ProjectV2 {
      items(first: $first) {
        nodes {
          id
          content {
            ... on Issue {
              id
              title
              body
              state
              assignees(first: 5) { nodes { login } }
            }
          }
          fieldValues(first: 10) {
            nodes {
              ... on ProjectV2ItemFieldDateValue {
                date
                field { ... on ProjectV2FieldCommon { name } }
              }
              ... on ProjectV2ItemFieldSingleSelectValue {
                name
                field { ... on ProjectV2FieldCommon { name } }
              }
            }
          }
        }
      }
    }
  }
}
```

**Create Issue:**
```graphql
mutation CreateIssue($repositoryId: ID!, $title: String!, $body: String) {
  createIssue(input: {
    repositoryId: $repositoryId
    title: $title
    body: $body
  }) {
    issue {
      id
      number
    }
  }
}
```

#### 2.3 GitHub Project Setup (Automated)
When user selects a repository:
1. Check for existing "TodoHub" project
2. If not exists, create project via API
3. Add custom fields:
   - `Due Date` (Date field)
   - `Priority` (Single select: High, Medium, Low)
4. Store project ID in UserDefaults

### Phase 3: Core UI Implementation

#### 3.1 View Implementation Order
1. LoginView (OAuth flow)
2. RepoSelectionView (onboarding)
3. TodoListView (main screen)
4. TodoRowView (list items)
5. QuickAddView (new todos)
6. TodoDetailView (edit/details)
7. AllIssuesView (cross-repo)
8. SettingsView

#### 3.2 SwiftUI Best Practices
- Use `@Observable` macro (iOS 17+)
- Implement `Sendable` for thread safety
- Use `AsyncStream` for real-time updates
- NavigationStack for navigation

### Phase 4: Advanced Features

#### 4.1 Issue Ordering via Projects
- Use `updateProjectV2ItemFieldValue` mutation
- Implement drag-and-drop with `onMove`
- Sync order changes to GitHub

#### 4.2 Cross-Repository Issue View
```graphql
query GetAssignedIssues($login: String!) {
  search(query: "assignee:$login is:open is:issue", type: ISSUE, first: 100) {
    nodes {
      ... on Issue {
        id
        title
        repository { nameWithOwner }
        createdAt
      }
    }
  }
}
```

#### 4.3 Reassignment
- Query repository collaborators
- Update issue assignees via mutation
- Automatically hide from user's todo list

#### 4.4 Offline Support (Deferred)
> **Note:** Offline support is deferred until we have a working, deployed application.
> Future implementation will include:
> - Cache todos locally with SwiftData
> - Queue mutations when offline
> - Sync when connection restored

### Phase 5: Polish & Animations

#### 5.1 Microinteractions
- Checkbox completion animation (confetti burst)
- Swipe gesture haptics
- Pull-to-refresh spring animation
- Card slide-out on delete

#### 5.2 Theming
- System appearance support
- Custom accent colors
- SF Symbols throughout

---

## 🚀 CI/CD Setup

### GitHub Actions Workflows (No Ruby/Fastlane)

We use native `xcodebuild` and `xcrun` commands to avoid Ruby dependencies.

#### `.github/workflows/build.yml`
```yaml
name: Build

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_15.2.app
      - name: Build
        run: xcodebuild build -scheme TodoHub -destination 'platform=iOS Simulator,name=iPhone 15'
```

#### `.github/workflows/test.yml`
```yaml
name: Test

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_15.2.app
      - name: Run Tests
        run: xcodebuild test -scheme TodoHub -destination 'platform=iOS Simulator,name=iPhone 15' -resultBundlePath TestResults
      - name: Upload Test Results
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: test-results
          path: TestResults.xcresult
```

#### `.github/workflows/deploy-testflight.yml`
```yaml
name: Deploy to TestFlight

on:
  push:
    tags:
      - 'v*'
  workflow_dispatch:

env:
  SCHEME: TodoHub
  ARCHIVE_PATH: build/TodoHub.xcarchive
  EXPORT_PATH: build/export

jobs:
  deploy:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_15.2.app

      - name: Install Apple Certificate
        env:
          CERTIFICATE_BASE64: ${{ secrets.APPLE_CERTIFICATE_BASE64 }}
          CERTIFICATE_PASSWORD: ${{ secrets.APPLE_CERTIFICATE_PASSWORD }}
          KEYCHAIN_PASSWORD: ${{ secrets.KEYCHAIN_PASSWORD }}
        run: |
          # Create temporary keychain
          KEYCHAIN_PATH=$RUNNER_TEMP/app-signing.keychain-db
          security create-keychain -p "$KEYCHAIN_PASSWORD" $KEYCHAIN_PATH
          security set-keychain-settings -lut 21600 $KEYCHAIN_PATH
          security unlock-keychain -p "$KEYCHAIN_PASSWORD" $KEYCHAIN_PATH

          # Import certificate
          CERTIFICATE_PATH=$RUNNER_TEMP/certificate.p12
          echo -n "$CERTIFICATE_BASE64" | base64 --decode -o $CERTIFICATE_PATH
          security import $CERTIFICATE_PATH -P "$CERTIFICATE_PASSWORD" -A -t cert -f pkcs12 -k $KEYCHAIN_PATH
          security set-key-partition-list -S apple-tool:,apple: -k "$KEYCHAIN_PASSWORD" $KEYCHAIN_PATH
          security list-keychain -d user -s $KEYCHAIN_PATH

      - name: Install Provisioning Profile
        env:
          PROVISIONING_PROFILE_BASE64: ${{ secrets.PROVISIONING_PROFILE_BASE64 }}
        run: |
          PP_PATH=$RUNNER_TEMP/profile.mobileprovision
          echo -n "$PROVISIONING_PROFILE_BASE64" | base64 --decode -o $PP_PATH
          mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
          cp $PP_PATH ~/Library/MobileDevice/Provisioning\ Profiles/

      - name: Set Build Number
        run: |
          BUILD_NUMBER=${{ github.run_number }}
          /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" TodoHub/Info.plist

      - name: Archive App
        run: |
          xcodebuild archive \
            -scheme $SCHEME \
            -archivePath $ARCHIVE_PATH \
            -configuration Release \
            -destination 'generic/platform=iOS' \
            CODE_SIGN_STYLE=Manual \
            DEVELOPMENT_TEAM="${{ secrets.APPLE_TEAM_ID }}"

      - name: Create ExportOptions.plist
        run: |
          cat > ExportOptions.plist << EOF
          <?xml version="1.0" encoding="UTF-8"?>
          <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
          <plist version="1.0">
          <dict>
              <key>method</key>
              <string>app-store-connect</string>
              <key>teamID</key>
              <string>${{ secrets.APPLE_TEAM_ID }}</string>
              <key>uploadSymbols</key>
              <true/>
              <key>destination</key>
              <string>upload</string>
          </dict>
          </plist>
          EOF

      - name: Export & Upload to TestFlight
        env:
          ASC_KEY_ID: ${{ secrets.ASC_KEY_ID }}
          ASC_ISSUER_ID: ${{ secrets.ASC_ISSUER_ID }}
          ASC_API_KEY_BASE64: ${{ secrets.ASC_API_KEY_BASE64 }}
        run: |
          # Write API key
          mkdir -p ~/.private_keys
          echo -n "$ASC_API_KEY_BASE64" | base64 --decode -o ~/.private_keys/AuthKey_$ASC_KEY_ID.p8

          # Export and upload in one step
          xcodebuild -exportArchive \
            -archivePath $ARCHIVE_PATH \
            -exportOptionsPlist ExportOptions.plist \
            -exportPath $EXPORT_PATH \
            -allowProvisioningUpdates \
            -authenticationKeyPath ~/.private_keys/AuthKey_$ASC_KEY_ID.p8 \
            -authenticationKeyID $ASC_KEY_ID \
            -authenticationKeyIssuerID $ASC_ISSUER_ID

      - name: Clean up keychain
        if: always()
        run: security delete-keychain $RUNNER_TEMP/app-signing.keychain-db || true
```

---

## 📋 Manual Setup Steps

### Prerequisites
1. **Apple Developer Account** ($99/year)
2. **App Store Connect access**
3. **GitHub OAuth App** registered

### One-Time Setup Steps

#### 1. Apple Developer Portal
```bash
# Create App ID
1. Go to developer.apple.com → Certificates, IDs & Profiles
2. Create new App ID: com.martinwoodward.todohub
3. Enable capabilities: Associated Domains (for OAuth callback)
```

#### 2. App Store Connect
```bash
1. Create new app "TodoHub"
2. Bundle ID: com.martinwoodward.todohub
3. Generate App Store Connect API Key:
   - Users and Access → Keys → Generate
   - Download .p8 file (save securely!)
   - Note: Key ID, Issuer ID
```

#### 3. Code Signing Certificates (Manual Export)
```bash
# On your Mac with Xcode:
1. Open Keychain Access
2. Export your Apple Distribution certificate as .p12
3. Base64 encode it:
   base64 -i Certificates.p12 -o certificate_base64.txt

# For provisioning profile:
1. Download from Apple Developer Portal
2. Base64 encode it:
   base64 -i profile.mobileprovision -o profile_base64.txt
```

#### 4. GitHub Repository Secrets
Add these secrets to your TodoHub repository:
```
APPLE_CERTIFICATE_BASE64    # Base64-encoded .p12 distribution certificate
APPLE_CERTIFICATE_PASSWORD  # Password for the .p12 file
PROVISIONING_PROFILE_BASE64 # Base64-encoded .mobileprovision file
APPLE_TEAM_ID               # Your Apple Developer Team ID
KEYCHAIN_PASSWORD           # Any secure password for temp keychain
ASC_API_KEY_BASE64          # Base64-encoded App Store Connect .p8 key
ASC_KEY_ID                  # App Store Connect API Key ID
ASC_ISSUER_ID               # App Store Connect Issuer ID
```

#### 5. GitHub OAuth App
```bash
1. GitHub Settings → Developer Settings → OAuth Apps
2. New OAuth App:
   - Name: TodoHub
   - Homepage: https://github.com/martinwoodward/todohub
   - Callback: todohub://oauth-callback
3. Generate client secret
4. Add to Xcode project as environment variables (gitignored)
```

---

## 📅 Implementation Timeline

### Phase A: Working Local Application

#### Week 1: Foundation
- [ ] Create Xcode project with SwiftUI
- [ ] Set up project structure
- [ ] Add SPM dependencies (Apollo, AppAuth, KeychainAccess)
- [ ] Implement GitHub OAuth login flow
- [ ] Create KeychainService for token storage
- [ ] Build LoginView UI

#### Week 2: Core GitHub Integration
- [ ] Download and configure GitHub GraphQL schema
- [ ] Generate Apollo types
- [ ] Implement GitHubAPIService
- [ ] Build RepoSelectionView
- [ ] Create project setup automation
- [ ] Define core data models

#### Week 3: Main Todo List
- [ ] Implement TodoListViewModel
- [ ] Build TodoListView with sections (Today, Upcoming, No Date)
- [ ] Create TodoRowView with swipe actions
- [ ] Add QuickAddView modal
- [ ] Implement create/close issue mutations

#### Week 4: Details & Editing
- [ ] Build TodoDetailView
- [ ] Implement due date picker
- [ ] Add priority selector
- [ ] Create reassignment flow
- [ ] Add issue description editing (Markdown)

#### Week 5: All Issues View
- [ ] Implement cross-repo issue search query
- [ ] Build AllIssuesView
- [ ] Add org/repo filters
- [ ] Implement "Add to Todo List" feature
- [ ] Quick mark-as-done from this view

#### Week 6: Polish & Settings
- [ ] Build SettingsView
- [ ] Add theme support (dark/light/system)
- [ ] Implement microinteractions and animations
- [ ] Add haptic feedback
- [ ] Error handling and loading states

### Phase B: Git, GitHub & CI/CD

#### Week 7: Repository Setup
- [ ] Initialize local Git repository
- [ ] Create .gitignore for Xcode/Swift
- [ ] Write comprehensive README.md
- [ ] Add LICENSE file (MIT)
- [ ] Push to GitHub

#### Week 8: CI/CD & TestFlight
- [ ] Set up GitHub Actions workflows (build, test, deploy)
- [ ] Configure code signing with manual certificates
- [ ] Test TestFlight deployment
- [ ] Document manual setup steps
- [ ] Create app screenshots for App Store

### Phase C: Iteration & Improvement
- [ ] Beta testing and bug fixes
- [ ] Performance optimization
- [ ] Add offline support (deferred feature)
- [ ] User feedback incorporation

---

## 📝 README.md Structure

The README will include:
1. App overview with screenshots
2. Features list
3. Installation instructions (for developers)
4. Building and running locally
5. Running tests
6. CI/CD pipeline description
7. TestFlight deployment guide
8. Contributing guidelines
9. License (MIT)

---

## 📄 License

```
MIT License

Copyright (c) 2025 Martin Woodward

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## ✅ Success Criteria

- [ ] User can log in with GitHub OAuth
- [ ] User can select/create a repository for todos
- [ ] Todos sync with GitHub Issues
- [ ] GitHub Project provides ordering and custom fields
- [ ] User can create, edit, complete, and delete todos
- [ ] Due dates and priorities are supported
- [ ] User can view all assigned issues across GitHub
- [ ] User can reassign issues to others
- [ ] App works offline with cached data
- [ ] CI/CD deploys to TestFlight automatically
- [ ] App is production-ready for App Store submission

---

*This plan is designed for execution with GitHub Copilot. Each phase includes specific, actionable tasks that can be implemented incrementally.*
