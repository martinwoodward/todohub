# Getting Started with Agentic Workflows

TodoHub now includes AI-powered GitHub Agentic Workflows to help automate maintenance tasks. These workflows are located in `.github/workflows/agentics/`.

## Quick Start

### 1. Install the gh-aw CLI Extension

```bash
gh extension install githubnext/gh-aw
```

### 2. Choose Your AI Engine

Select an AI model to power the workflows. Options:

- **GitHub Copilot** (recommended if you have access)
- **Anthropic Claude** - Requires `ANTHROPIC_API_KEY`
- **OpenAI GPT-4** - Requires `OPENAI_API_KEY`

Add your API key to repository secrets:
- Go to Settings > Secrets and variables > Actions
- Create new repository secret with your key

See full engine options: https://githubnext.github.io/gh-aw/reference/engines/

### 3. Install Workflows

Each workflow must be compiled from markdown to YAML before it can run:

```bash
# Install CI Doctor (safe - read-only, creates issues)
gh aw add .github/workflows/agentics/ci-doctor.md --pr

# Install Weekly Research (safe - read-only, creates discussions)
gh aw add .github/workflows/agentics/weekly-research.md --pr

# Install PR Fix (⚠️ writes code - review carefully)
gh aw add .github/workflows/agentics/pr-fix.md --pr

# Install Dependency Updater (⚠️ writes code - review carefully)
gh aw add .github/workflows/agentics/daily-dependency-updates.md --pr

# Install Test Coverage Improver (⚠️ writes code - review carefully)
gh aw add .github/workflows/agentics/daily-test-improver.md --pr
```

Each command creates a PR with the compiled workflow. Review and merge to activate.

### 4. Enable Actions to Create PRs

For workflows that create PRs:
1. Go to Settings > Actions > General
2. Scroll to "Workflow permissions"
3. Check "Allow GitHub Actions to create and approve pull requests"

### 5. Run a Workflow

```bash
# Run manually
gh aw run weekly-research

# View logs
gh aw logs weekly-research

# Trigger PR Fix by commenting on a PR
# Just add this comment: /pr-fix
```

## Recommended Rollout Order

1. ✅ **Start with Weekly Research** - Completely safe, provides insights
2. ✅ **Add CI Doctor** - Safe, helps debug iOS build failures
3. ⚠️ **Try PR Fix** - Test on a non-critical PR first
4. ⚠️ **Experiment with Test Coverage Improver** - Start with 1-2 day time limit
5. ⚠️ **Add Dependency Updater** - Requires careful PR review

## Available Workflows

| Workflow | Description | Risk Level | Permissions |
|----------|-------------|------------|-------------|
| 🏥 CI Doctor | Investigates iOS build/test failures | Low | Read + Create Issues |
| 📚 Weekly Research | iOS/SwiftUI trends and GitHub updates | Low | Read + Create Discussions |
| 🔧 PR Fix | Fixes CI failures on demand (`/pr-fix`) | Medium | Write Code |
| 🧪 Test Coverage Improver | Adds XCTest tests to improve coverage | Medium | Write Code + Create PRs |
| 📦 Dependency Updater | Updates AppAuth-iOS and packages | Medium | Write Code + Create PRs |

## Safety Features

All workflows include:
- ⏱️ **Time limits** (30 days by default) - workflows auto-disable
- 🔒 **Read-only by default** - write operations use "safe outputs"
- 🎯 **Specific permissions** - minimal access needed
- 📝 **Draft PRs** - code changes always created as drafts
- 🧪 **Sandboxed execution** - runs in GitHub Actions containers

## Important Notes

### ⚠️ CI Won't Auto-Run on Workflow PRs

GitHub Actions won't trigger CI on PRs created by workflows. To run CI:
- Close and reopen the PR, OR
- Click "Update branch" button

This is a GitHub limitation, not a bug.

### 🔍 Always Review AI-Generated Code

Before merging any PR from these workflows:
1. Review all code changes carefully
2. Ensure tests pass
3. Check for security issues
4. Verify changes align with TodoHub's architecture

### 📊 Monitor Activity

Regularly check:
- Issues created by CI Doctor
- PRs created by dependency/test workflows
- Discussions from Weekly Research
- Workflow run logs

## Customization

To customize a workflow:

1. Edit the markdown file in `.github/workflows/agentics/`
2. Recompile: `gh aw compile <workflow-name>`
3. Commit and push changes

Or create a config file:
`.github/workflows/agentics/<workflow-name>.config.md`

## Documentation

- [Full Setup Guide](.github/workflows/agentics/README.md)
- [GitHub Agentic Workflows Docs](https://githubnext.github.io/gh-aw/)
- [Security Guide](https://githubnext.github.io/gh-aw/guides/security/)

## Troubleshooting

**Workflow not triggering?**
- Check if `stop-after` time expired
- Verify workflow is enabled: `gh aw list`

**API rate limits?**
- Reduce frequency (daily → weekly)
- Check: `gh api rate_limit`

**Need help?**
- Open an issue in this repository
- Check workflow logs: `gh aw logs <workflow-name>`

---

**Remember**: These are experimental AI-powered workflows. Start small, monitor closely, and always review AI-generated changes.
