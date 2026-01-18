# TodoHub

**Your todos, backed by GitHub.**

TodoHub is a native iOS application that uses GitHub Issues as the storage backend for your personal todo items. Authenticate with GitHub, select a repository, and manage your tasks with an elegant, minimal interface.

![iOS](https://img.shields.io/badge/iOS-17.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

- 🔐 **Secure GitHub OAuth** - Sign in with your GitHub account
- 📋 **Issue-backed todos** - Every todo is a GitHub Issue
- 📊 **Project integration** - Uses GitHub Projects for ordering and custom fields
- 📅 **Due dates** - Set and track deadlines
- 🚦 **Priorities** - High, Medium, Low priority levels
- ✅ **Quick complete** - Swipe to mark tasks done
- 🌐 **All issues view** - See all issues assigned to you across GitHub
- 🌙 **Dark mode** - Full support for light and dark themes
- 📱 **Native iOS** - Built with SwiftUI for iOS 17+

## Screenshots

*Coming soon*

## Requirements

- iOS 17.0+
- Xcode 15.2+
- GitHub account
- GitHub OAuth App (for authentication)

## Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/martinwoodward/todohub.git
cd todohub
```

### 2. Register a GitHub OAuth App

1. Go to [GitHub Developer Settings](https://github.com/settings/developers)
2. Click "New OAuth App"
3. Fill in the details:
   - **Application name:** TodoHub
   - **Homepage URL:** `https://github.com/martinwoodward/todohub`
   - **Authorization callback URL:** `todohub://oauth-callback`
4. Click "Register application"
5. Note your **Client ID** and generate a **Client Secret**

### 3. Configure OAuth credentials

Copy the template to create your config file:

```bash
cp TodoHub/Config/Config.swift.template TodoHub/Config/Config.swift
```

Then edit `TodoHub/Config/Config.swift` and replace the placeholder values:

```swift
enum Config {
    static let githubClientId = "YOUR_GITHUB_CLIENT_ID"
    static let githubClientSecret = "YOUR_GITHUB_CLIENT_SECRET"
}
```

> ⚠️ **Important:** `Config.swift` is gitignored to prevent accidental credential commits.

### 4. Generate the Xcode project

If you need to regenerate the Xcode project:

```bash
brew install xcodegen  # If not already installed
xcodegen generate
```

### 5. Open and run

```bash
open TodoHub.xcodeproj
```

Select an iOS Simulator and run (⌘R).

## Project Structure

```
TodoHub/
├── App/                    # App entry point
├── Models/                 # Data models (Todo, User, Repository, etc.)
├── Views/                  # SwiftUI views
│   ├── Login/             # Login screen
│   ├── Setup/             # Repository selection
│   ├── TodoList/          # Main todo list
│   ├── TodoDetail/        # Todo editing
│   ├── AllIssues/         # Cross-repo issues
│   ├── Settings/          # App settings
│   └── Components/        # Reusable components
├── ViewModels/            # View models (MVVM pattern)
├── Services/              # GitHub API, Keychain, etc.
├── Extensions/            # Swift extensions
├── GraphQL/               # GraphQL queries/mutations
├── Config/                # App configuration
└── Resources/             # Assets, localization
```

## Architecture

TodoHub follows the **MVVM (Model-View-ViewModel)** architecture pattern:

- **Models** - Data structures for todos, users, repositories
- **Views** - SwiftUI views for the UI
- **ViewModels** - Business logic and state management
- **Services** - API communication, authentication, storage

### GitHub Integration

- **OAuth 2.0** with PKCE for secure authentication
- **GraphQL API** for efficient data fetching
- **GitHub Projects v2** for ordering and custom fields
- **Issues** as the storage backend for todos

## Building for Release

### Running Tests

```bash
xcodebuild test -scheme TodoHub -destination 'platform=iOS Simulator,name=iPhone 16'
```

### Creating an Archive

```bash
xcodebuild archive -scheme TodoHub -archivePath build/TodoHub.xcarchive
```

## CI/CD

GitHub Actions workflows are configured for:
- **Build** - Compiles on every push/PR
- **Test** - Runs unit and UI tests
- **Deploy** - Uploads to TestFlight on version tags
- **PR Issue Link Check** - Ensures PRs are linked to issues for better tracking

See `.github/workflows/` for workflow definitions.

## Roadmap

- [ ] Widget support
- [ ] Watch app
- [ ] Offline mode with local caching
- [ ] Notifications for due dates
- [ ] Siri shortcuts
- [ ] macOS app (Catalyst or native)

## Contributing

Contributions are welcome! Please read our contributing guidelines before submitting PRs.

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. **Link your PR to an issue** - Use keywords like `Fixes #123` or `Closes #456` in your PR description
4. Commit your changes (`git commit -m 'Add amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

**Note:** PRs without linked issues will be asked to add one. PRs from external contributors without write access that don't link an issue will be automatically converted to draft status.

## License

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

## Acknowledgments

- Built with [SwiftUI](https://developer.apple.com/xcode/swiftui/)
- OAuth via [AppAuth-iOS](https://github.com/openid/AppAuth-iOS)
- Powered by [GitHub API](https://docs.github.com/en/graphql)
