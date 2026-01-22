# GitHub Agentic Workflows Setup for TodoHub

This directory contains GitHub Agentic Workflows (gh-aw) that help automate maintenance tasks for the TodoHub iOS project.

## What are Agentic Workflows?

GitHub Agentic Workflows are AI-powered automation workflows written in natural language markdown. They use AI agents to perform repository tasks like investigating CI failures, updating dependencies, improving test coverage, and more.

## Available Workflows

### 🏥 CI Doctor (`ci-doctor.md`)
**Purpose**: Automatically investigates iOS build and test failures

- Triggers when Build or Test workflows fail
- Analyzes Xcode logs and Swift compiler errors
- Creates detailed investigation reports with root causes
- Suggests fixes for iOS-specific issues (actor isolation, async/await, etc.)
- **Permissions**: `issues: write`, `actions: read`

### 📦 Daily Dependency Updater (`daily-dependency-updates.md`)
**Purpose**: Keeps Swift Package dependencies up to date

- Runs daily to check for Dependabot alerts
- Updates AppAuth-iOS and other dependencies in project.yml
- Creates draft PRs with tested dependency updates
- **Permissions**: `contents: write`, `pull-requests: write`
- **⚠️ Warning**: Requires careful review before merging

### 🧪 Daily Test Coverage Improver (`daily-test-improver.md`)
**Purpose**: Systematically improves test coverage

- Operates in 3 phases: research, configure, implement
- Identifies under-tested ViewModels, Services, and Models
- Writes new XCTest unit tests
- Creates draft PRs with coverage improvements
- **Permissions**: `contents: write`, `issues: write`, `pull-requests: write`
- **⚠️ Warning**: Requires careful review before merging

### 🔧 PR Fix (`pr-fix.md`)
**Purpose**: Fixes failing CI checks on pull requests

- Triggered by commenting `/pr-fix` on a PR
- Analyzes iOS build/test failures
- Implements fixes for Swift compilation errors
- Pushes corrections directly to PR branch
- **Permissions**: `contents: write`, `pull-requests: write`
- **⚠️ Warning**: Requires careful review of pushed changes

### 📚 Weekly Research (`weekly-research.md`)
**Purpose**: Provides iOS and GitHub API trend analysis

- Runs every Monday
- Researches iOS/SwiftUI updates, GitHub API changes
- Analyzes competitive landscape
- Creates discussion with findings and recommendations
- **Permissions**: `discussions: write`

## Installation

### Prerequisites

1. **Install the gh-aw extension**:
   ```bash
   gh extension install githubnext/gh-aw
   ```

2. **Choose an AI agent**: You need to select an AI model to power the workflows. Options include:
   - GitHub Copilot (recommended)
   - Anthropic Claude
   - OpenAI GPT-4
   
   See: https://githubnext.github.io/gh-aw/reference/engines/

3. **Add API key secret**: Store your AI provider's API key in repository secrets:
   - Go to repository Settings > Secrets and variables > Actions
   - Add secret (e.g., `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, or use GitHub Copilot which may not require additional secrets)

### Installing Workflows

To install a workflow, run:

```bash
# Install from this repository
gh aw add .github/workflows/agentics/<workflow-name>.md --pr

# Examples:
gh aw add .github/workflows/agentics/ci-doctor.md --pr
gh aw add .github/workflows/agentics/weekly-research.md --pr
```

This creates a pull request to add the compiled workflow YAML to `.github/workflows/`.

### Enabling Workflows

After installation, you may need to:

1. **Enable Actions to create PRs**: 
   - Go to Settings > Actions > General
   - Check "Allow GitHub Actions to create and approve pull requests"

2. **Enable workflow**: If a workflow has `stop-after` configured (they all do by default for 30 days), you can extend or remove the time limit:
   ```bash
   # Edit the workflow markdown to remove or extend stop-after
   # Then recompile:
   gh aw compile <workflow-name>
   ```

### Configuration

Each workflow can be configured with a local config file in `.github/workflows/agentics/<workflow-name>.config.md`.

Example configuration structure:
```markdown
# Additional instructions for the workflow

- Focus on specific files or directories
- Exclude certain areas from analysis
- Adjust frequency or behavior
```

After editing configuration, recompile:
```bash
gh aw compile <workflow-name>
git add .github/workflows/<workflow-name>.yml
git commit -m "Update workflow configuration"
git push
```

## Usage

### Running Workflows Manually

```bash
# Run a workflow on-demand
gh aw run <workflow-name> --repo martinwoodward/todohub

# Examples:
gh aw run daily-dependency-updates --repo martinwoodward/todohub
gh aw run weekly-research --repo martinwoodward/todohub
```

### Triggering PR Fix

Comment on any pull request:
```
/pr-fix
```

Or with specific instructions:
```
/pr-fix Please fix the actor isolation errors in AuthViewModel
```

### Viewing Logs

```bash
# View workflow execution logs
gh aw logs <workflow-name> --repo martinwoodward/todohub
```

### Disabling/Enabling Workflows

```bash
# Disable a workflow
gh aw disable <workflow-name> --repo martinwoodward/todohub

# Enable a workflow
gh aw enable <workflow-name> --repo martinwoodward/todohub
```

## Important Security Considerations

### ⚠️ Workflows that Write Code

Three workflows can modify code or create PRs:
- Daily Dependency Updater
- Daily Test Coverage Improver  
- PR Fix

**Security Practices**:
1. **Always review generated code carefully** before merging
2. **Run CI on all PRs** created by workflows
3. **Monitor workflow activity** regularly
4. **Use time limits** (`stop-after`) to limit exposure
5. **Start with short time limits** (e.g., 1-2 days) for experimentation
6. **Read-only by default**: Workflows run with read-only permissions; writes use "safe outputs"

### Network Access

Workflows have network access and can:
- Search the web for solutions
- Fetch documentation
- Query GitHub APIs

**DO NOT**:
- Store secrets in workflow files
- Allow untrusted users to trigger workflows
- Run coding workflows indefinitely without monitoring

### Recommended Rollout

1. **Start with Weekly Research** (read-only, safe)
2. **Add CI Doctor** (read-only, creates issues)
3. **Experiment with PR Fix** on test PRs first
4. **Try Test Coverage Improver** with short time limit
5. **Add Dependency Updater** last, with manual review process

## Customization for TodoHub

All workflows have been customized with:
- iOS/Swift/SwiftUI specific knowledge
- TodoHub architecture (MVVM, ViewModels, Services)
- Xcode build commands and iOS simulator setup
- GitHub integration context (OAuth, GraphQL API)
- AppAuth-iOS dependency awareness
- XCTest and test organization patterns

When the AI agents run, they understand:
- How to build and test iOS apps with xcodebuild
- Swift compilation errors and how to fix them
- Actor isolation and async/await patterns
- SwiftUI view debugging
- GitHub Issues/Projects integration

## Troubleshooting

### Workflow Not Triggering

- Check if `stop-after` time limit has expired
- Verify workflow is enabled: `gh aw list --repo martinwoodward/todohub`
- Check workflow permissions in `.github/workflows/<workflow>.yml`

### CI Not Running on Workflow PRs

This is expected GitHub Actions behavior. To trigger CI:
- Close and reopen the PR
- Click "Update branch" button
- Push another commit manually

### API Rate Limits

If workflows hit GitHub API rate limits:
- Reduce frequency (change from daily to weekly)
- Adjust `timeout-minutes` to give more time
- Check rate limit status: `gh api rate_limit`

## Further Reading

- [GitHub Agentic Workflows Documentation](https://githubnext.github.io/gh-aw/)
- [Agentics Sample Workflows](https://github.com/githubnext/agentics)
- [Security Guide](https://githubnext.github.io/gh-aw/guides/security/)
- [Quick Start Guide](https://githubnext.github.io/gh-aw/setup/quick-start/)

## Feedback

To report issues or request changes to these workflows:
- Open an issue in this repository
- Comment on workflow-generated issues or PRs
- Edit the workflow markdown files and recompile

---

**Remember**: These are experimental AI-powered workflows. Use with caution, monitor actively, and always review AI-generated changes before merging.
