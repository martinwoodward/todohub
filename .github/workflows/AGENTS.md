# GitHub Workflows - Agent Guidelines

## Overview

CI/CD workflows for TodoHub using GitHub Actions. All workflows use native xcodebuild commands (no Ruby/Fastlane).

## Workflows

### build.yml
**Trigger:** Push or PR to `main`
**Purpose:** Verify the app compiles

```yaml
- Select Xcode 16.2
- Resolve package dependencies
- Build for iOS Simulator
```

### test.yml
**Trigger:** Push or PR to `main`
**Purpose:** Run unit tests

```yaml
- Select Xcode 16.2
- Resolve package dependencies
- Run TodoHubTests
- Upload test results artifact
- Generate test summary
```

### deploy-testflight.yml
**Trigger:** Push of version tag (v*)
**Purpose:** Build and upload to TestFlight

```yaml
- Install signing certificate
- Install provisioning profile
- Build archive
- Export IPA
- Upload to App Store Connect
```

## Required Secrets for TestFlight

| Secret | Description |
|--------|-------------|
| `APPLE_CERTIFICATE_BASE64` | Distribution cert (.p12, base64) |
| `APPLE_CERTIFICATE_PASSWORD` | Cert password |
| `PROVISIONING_PROFILE_BASE64` | App Store profile (.mobileprovision, base64) |
| `APPLE_TEAM_ID` | 10-char Team ID |
| `KEYCHAIN_PASSWORD` | Temporary keychain password |
| `ASC_KEY_ID` | App Store Connect API Key ID |
| `ASC_ISSUER_ID` | App Store Connect Issuer ID |
| `ASC_API_KEY_BASE64` | API key (.p8, base64) |

See `TESTFLIGHT_SETUP.md` in repo root for detailed setup instructions.

## Conventions

### Runner
- Use `macos-14` runner (Apple Silicon)
- Select Xcode with: `sudo xcode-select -s /Applications/Xcode_16.2.app`

### Simulator
- Use `iPhone 16` for iOS 18.2 compatibility
- Always set `CODE_SIGNING_ALLOWED=NO` for simulator builds

### Artifacts
- Upload test results as artifacts
- Upload build logs on failure

## Modifying Workflows

1. Edit workflow YAML files directly
2. Test locally if possible with `act` or by pushing to a branch
3. Check workflow run logs for failures
4. Xcode version must match project.yml `xcodeVersion`

## Triggering Deployment

```bash
# Create and push version tag
git tag v1.0.0
git push origin v1.0.0
```

Deployment only triggers on tags matching `v*` pattern.
