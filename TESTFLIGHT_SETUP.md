# TestFlight Deployment Setup Guide

This guide walks you through setting up automated TestFlight deployment for TodoHub using GitHub Actions.

## Prerequisites

- Apple Developer Program membership ($99/year)
- Access to [App Store Connect](https://appstoreconnect.apple.com)
- Access to [Apple Developer Portal](https://developer.apple.com)

## Overview

The `deploy-testflight.yml` workflow automatically builds and uploads the app to TestFlight when you push a version tag (e.g., `v1.0.0`). It requires 10 repository secrets to be configured.

> **Note:** The `build.yml` and `test.yml` CI workflows also generate `Config.swift` from the template, but they fall back to placeholder values if the OAuth secrets aren't set. Only the TestFlight deployment requires real credentials.

## Step 1: Create App Store Connect API Key

The API key allows GitHub Actions to upload builds to App Store Connect.

1. Go to [App Store Connect → Users and Access → Integrations → App Store Connect API](https://appstoreconnect.apple.com/access/integrations/api)
2. Click the **+** button to create a new key
3. Name it `GitHub Actions` and select **App Manager** role
4. Click **Generate**
5. **Download the .p8 file immediately** (you can only download it once!)
6. Note the **Key ID** shown in the table
7. Note the **Issuer ID** shown at the top of the page

### Configure secrets:

```bash
# Key ID (e.g., "ABC123XYZ")
gh secret set ASC_KEY_ID --repo martinwoodward/todohub

# Issuer ID (e.g., "12345678-1234-1234-1234-123456789012")
gh secret set ASC_ISSUER_ID --repo martinwoodward/todohub

# API Key file (base64 encoded)
base64 -i AuthKey_ABC123XYZ.p8 | gh secret set ASC_API_KEY_BASE64 --repo martinwoodward/todohub
```

## Step 2: Create Distribution Certificate

1. Open **Keychain Access** on your Mac
2. Go to **Keychain Access → Certificate Assistant → Request a Certificate From a Certificate Authority**
3. Enter your email, select **Saved to disk**, click **Continue**
4. Go to [Apple Developer → Certificates](https://developer.apple.com/account/resources/certificates/list)
5. Click **+** to create a new certificate
6. Select **Apple Distribution** and click **Continue**
7. Upload the certificate signing request (.certSigningRequest file)
8. Download the certificate (.cer file)
9. Double-click to install it in Keychain Access

### Export as .p12:

1. In **Keychain Access**, find the certificate under "My Certificates"
2. Right-click → **Export** (choose .p12 format)
3. Set a strong password (you'll need this for the secret)
4. Save as `distribution.p12`

### Configure secrets:

```bash
# Certificate (base64 encoded)
base64 -i distribution.p12 | gh secret set APPLE_CERTIFICATE_BASE64 --repo martinwoodward/todohub

# Certificate password
gh secret set APPLE_CERTIFICATE_PASSWORD --repo martinwoodward/todohub
```

## Step 3: Create App ID and Provisioning Profile

### Create App ID:

1. Go to [Apple Developer → Identifiers](https://developer.apple.com/account/resources/identifiers/list)
2. Click **+** to register a new identifier
3. Select **App IDs** → **App**
4. Enter:
   - Description: `TodoHub`
   - Bundle ID: `com.martinwoodward.todohub` (Explicit)
5. Enable capabilities as needed (none required for basic functionality)
6. Click **Continue** → **Register**

### Create Provisioning Profile:

1. Go to [Apple Developer → Profiles](https://developer.apple.com/account/resources/profiles/list)
2. Click **+** to create a new profile
3. Select **App Store Connect** (under Distribution)
4. Select your App ID (`com.martinwoodward.todohub`)
5. Select your distribution certificate
6. Name it `TodoHub App Store`
7. Download the profile (.mobileprovision file)

### Configure secret:

```bash
# Provisioning profile (base64 encoded)
base64 -i TodoHub_App_Store.mobileprovision | gh secret set PROVISIONING_PROFILE_BASE64 --repo martinwoodward/todohub
```

## Step 4: Configure Remaining Secrets

### Apple Team ID:

Find your Team ID at [Apple Developer → Membership](https://developer.apple.com/account/#/membership) (it's the 10-character alphanumeric ID).

```bash
gh secret set APPLE_TEAM_ID --repo martinwoodward/todohub
```

### Keychain Password:

This is just a temporary password used during the build. Generate any random string:

```bash
echo "$(openssl rand -base64 32)" | gh secret set KEYCHAIN_PASSWORD --repo martinwoodward/todohub
```

## Step 5: Configure GitHub OAuth Credentials

`Config.swift` is gitignored, so CI workflows generate it from `Config.swift.template` at build time using repository secrets.

1. Go to [GitHub Developer Settings → OAuth Apps](https://github.com/settings/developers)
2. Find your existing OAuth App (or create one):
   - Application name: `TodoHub`
   - Homepage URL: `https://github.com/martinwoodward/todohub`
   - Authorization callback URL: `todohub://oauth-callback`
3. Note the **Client ID** and generate a **Client Secret**

### Configure secrets:

```bash
# GitHub OAuth App Client ID
gh secret set OAUTH_CLIENT_ID --repo martinwoodward/todohub

# GitHub OAuth App Client Secret
gh secret set OAUTH_CLIENT_SECRET --repo martinwoodward/todohub
```

## Step 6: Create App in App Store Connect

Before uploading builds, you need to create the app in App Store Connect:

1. Go to [App Store Connect → Apps](https://appstoreconnect.apple.com/apps)
2. Click **+** → **New App**
3. Fill in:
   - Platform: **iOS**
   - Name: `TodoHub`
   - Primary Language: English (US)
   - Bundle ID: Select `com.martinwoodward.todohub`
   - SKU: `todohub` (any unique identifier)
   - User Access: Full Access
4. Click **Create**

## Step 7: Trigger a Deployment

Once all secrets are configured, trigger a deployment by creating a version tag:

```bash
# Make sure you're on main with latest changes
git checkout main
git pull

# Create and push a version tag
git tag v1.0.0
git push origin v1.0.0
```

The workflow will:
1. Build the app for release
2. Create an IPA file
3. Upload to TestFlight
4. You'll receive an email when processing completes

## Verification Checklist

Run this command to verify all secrets are set:

```bash
gh secret list --repo martinwoodward/todohub
```

You should see:
```
APPLE_CERTIFICATE_BASE64
APPLE_CERTIFICATE_PASSWORD
APPLE_TEAM_ID
ASC_API_KEY_BASE64
ASC_ISSUER_ID
ASC_KEY_ID
KEYCHAIN_PASSWORD
OAUTH_CLIENT_ID
OAUTH_CLIENT_SECRET
PROVISIONING_PROFILE_BASE64
```

## Troubleshooting

### "No signing certificate found"
- Ensure the certificate is an **Apple Distribution** certificate (not Development)
- Verify the .p12 was exported with the private key
- Check that `APPLE_CERTIFICATE_PASSWORD` matches the export password

### "Provisioning profile doesn't match"
- Ensure the profile's Bundle ID matches `com.martinwoodward.todohub`
- Ensure the profile includes your distribution certificate
- Re-download and re-encode if recently regenerated

### "Invalid API key"
- Verify the Key ID matches your .p8 filename
- Ensure the key has **App Manager** or higher permissions
- API keys can't be re-downloaded; create a new one if lost

### Build succeeds but upload fails
- Ensure the app exists in App Store Connect
- Check that your API key has upload permissions
- Verify Team ID matches your App Store Connect organization

## Security Notes

- Never commit certificates, profiles, or API keys to the repository
- Rotate API keys periodically
- Use repository secrets, not environment variables
- The workflow uses a temporary keychain that's deleted after each build

## Quick Reference: All Secrets

| Secret | Description | How to Get |
|--------|-------------|------------|
| `APPLE_CERTIFICATE_BASE64` | Distribution certificate (.p12, base64) | Export from Keychain Access |
| `APPLE_CERTIFICATE_PASSWORD` | Password for .p12 file | Set when exporting |
| `PROVISIONING_PROFILE_BASE64` | App Store profile (.mobileprovision, base64) | Download from Developer Portal |
| `APPLE_TEAM_ID` | 10-char Team ID | Developer Portal → Membership |
| `KEYCHAIN_PASSWORD` | Temporary keychain password | Generate random string |
| `ASC_KEY_ID` | App Store Connect API Key ID | App Store Connect → Integrations |
| `ASC_ISSUER_ID` | App Store Connect Issuer ID | App Store Connect → Integrations |
| `ASC_API_KEY_BASE64` | API key file (.p8, base64) | Download when creating key |
| `OAUTH_CLIENT_ID` | GitHub OAuth App Client ID | GitHub Developer Settings |
| `OAUTH_CLIENT_SECRET` | GitHub OAuth App Client Secret | GitHub Developer Settings |
