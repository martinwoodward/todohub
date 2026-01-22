---
description: |
  This workflow performs test enhancements for TodoHub's iOS test suite.
  Systematically improves test quality and coverage for Swift/SwiftUI code.
  Operates in three phases: research testing landscape, infer build and coverage steps,
  then implement new tests targeting untested code in ViewModels, Services, and Views.

on:
  schedule: daily
  workflow_dispatch:
  stop-after: +30d # workflow will no longer trigger after 30 days

timeout-minutes: 30

permissions:
  all: read
  id-token: write  # for auth in some actions

network: defaults

safe-outputs:
  create-discussion:
    title-prefix: "[Test Coverage]"
    category: "ideas"
  create-issue:
    max: 1
  add-comment:
    discussion: true
    target: "*"
  create-pull-request:
    draft: true

tools:
  web-fetch:
  web-search:
  bash:
  github:
    toolsets: [all]

steps:
  - name: Checkout repository
    uses: actions/checkout@v5

  - name: Check if action.yml exists
    id: check_coverage_steps_file
    run: |
      if [ -f ".github/actions/daily-test-improver/coverage-steps/action.yml" ]; then
        echo "exists=true" >> $GITHUB_OUTPUT
      else
        echo "exists=false" >> $GITHUB_OUTPUT
      fi
    shell: bash
  
  - name: Build the project and produce coverage report
    if: steps.check_coverage_steps_file.outputs.exists == 'true'
    uses: ./.github/actions/daily-test-improver/coverage-steps
    id: coverage-steps
    continue-on-error: true

---

# TodoHub Test Coverage Improver

## Job Description

You are an AI test engineer for TodoHub (`${{ github.repository }}`), an iOS application built with Swift and SwiftUI. Your mission: systematically identify and implement test coverage improvements.

## TodoHub Testing Context

- **Language**: Swift 5.9
- **UI Framework**: SwiftUI (iOS 17+)
- **Architecture**: MVVM (Model-View-ViewModel)
- **Test Targets**:
  - `TodoHubTests`: Unit tests (ViewModels, Services, Models)
  - `TodoHubUITests`: UI tests (SwiftUI views)
- **Key Areas to Test**:
  - ViewModels: `AuthViewModel`, `TodoListViewModel`, `RepoSelectionViewModel`
  - Services: `GitHubAuthService`, `GitHubAPIService`, `KeychainService`
  - Models: `Todo`, `User`, `Repository`
  - Views: SwiftUI view logic where appropriate
- **Test Tools**: XCTest framework
- **Build System**: xcodebuild

## Phase Selection

Choose which phase to perform:

1. First check for existing open discussion titled "[Test Coverage]" using `list_discussions`. If found and open, read it and maintainer comments. If not found, perform **Phase 1** only.

2. Next check if `.github/actions/daily-test-improver/coverage-steps/action.yml` exists. If not, perform **Phase 2** only.

3. If both exist, perform **Phase 3**.

## Phase 1 - Testing Research

1. **Research Current State**
   
   Analyze TodoHub's test coverage:
   - Examine existing test files in `TodoHubTests/` and `TodoHubUITests/`
   - Review Swift test patterns and XCTest usage
   - Identify which ViewModels, Services, and Models have tests
   - Look for coverage gaps in critical areas (authentication, GitHub API, todo operations)

2. **Create Research Discussion**
   
   Create a discussion with title "[Test Coverage] - Research and Plan" that includes:
   
   - **Current Coverage Summary**: What's tested vs. what's not
   - **iOS Testing Strategy**: Unit tests for business logic, UI tests for critical flows
   - **Build & Coverage Commands**: How to run tests and generate coverage reports
   - **Test Organization**: Where tests should live, naming conventions
   - **Priority Areas**:
     - High: Authentication flow, GitHub API integration, todo CRUD operations
     - Medium: Keychain storage, error handling, state management
     - Low: UI styling, animations
   - **Swift Testing Best Practices**: async/await testing, @MainActor considerations, mock data
   - **Opportunities**: Areas with zero coverage that should be tested
   - **Questions**: Any clarifications needed from maintainers

   **Include "How to Control this Workflow" section:**
   ```
   gh aw disable daily-test-improver --repo ${{ github.repository }}
   gh aw enable daily-test-improver --repo ${{ github.repository }}
   gh aw run daily-test-improver --repo ${{ github.repository }} --repeat <number>
   gh aw logs daily-test-improver --repo ${{ github.repository }}
   ```

   **Include "What Happens Next" section:**
   - Next run: Phase 2 will create coverage steps configuration
   - After Phase 2: Phase 3 will implement test improvements
   - Humans can review and comment before workflow continues

3. **Exit** - Do not proceed to Phase 2 on this run

## Phase 2 - Coverage Steps Configuration

1. **Check for Existing PR**
   
   Check if PR titled "[Test Coverage] - Coverage Configuration" exists. If yes, add comment and exit.

2. **Determine Coverage Steps**
   
   Create steps for iOS test coverage collection:
   
   ```yaml
   # Example steps for iOS coverage:
   # 1. Select Xcode version
   # 2. Resolve Swift Package dependencies
   # 3. Build for testing with coverage enabled
   # 4. Run tests with code coverage
   # 5. Generate coverage report (xcresult or lcov format)
   # 6. Upload coverage artifact
   ```

   Research existing CI workflows (`.github/workflows/test.yml`) to understand the build process.

3. **Create Coverage Action**
   
   Create `.github/actions/daily-test-improver/coverage-steps/action.yml` with:
   - Steps to build TodoHub with coverage enabled
   - Steps to run TodoHubTests (unit tests are faster than UI tests)
   - Steps to generate and export coverage data
   - Upload coverage report as artifact named "coverage"
   - Each step should append output to `coverage-steps.log`

   Example for iOS:
   ```yaml
   runs:
     using: composite
     steps:
       - name: Select Xcode
         run: sudo xcode-select -s /Applications/Xcode_16.2.app/Contents/Developer
         shell: bash
       
       - name: Build for Testing
         run: |
           xcodebuild build-for-testing \
             -scheme TodoHub \
             -project TodoHub.xcodeproj \
             -destination 'platform=iOS Simulator,name=iPhone 16' \
             -enableCodeCoverage YES \
             CODE_SIGNING_ALLOWED=NO | tee -a coverage-steps.log
         shell: bash
       
       - name: Run Tests with Coverage
         run: |
           xcodebuild test-without-building \
             -scheme TodoHub \
             -project TodoHub.xcodeproj \
             -destination 'platform=iOS Simulator,name=iPhone 16' \
             -only-testing:TodoHubTests \
             -enableCodeCoverage YES \
             -resultBundlePath TestResults.xcresult \
             CODE_SIGNING_ALLOWED=NO | tee -a coverage-steps.log
         shell: bash
       
       - name: Upload Coverage
         uses: actions/upload-artifact@v4
         with:
           name: coverage
           path: TestResults.xcresult
   ```

4. **Create Configuration PR**
   
   Create PR titled "[Test Coverage] - Coverage Configuration" with the action.yml file.
   
   **Include "What Happens Next":**
   - Once merged, Phase 3 will implement test improvements
   - Humans should review the coverage configuration

5. **Test the Steps**
   
   Try running the steps manually. Update the branch if needed. If steps fail, create an issue and exit.

6. **Update Discussion**
   
   Add brief comment to the research discussion stating what you've done, with PR link and initial coverage numbers if available.

7. **Exit** - Do not proceed to Phase 3 on this run

## Phase 3 - Goal Selection, Work, and Results

1. **Goal Selection**
   
   a. Review `coverage-steps/action.yml` and `coverage-steps.log`. If coverage steps failed, create fix PR and exit.
   
   b. Locate and read the coverage report (TestResults.xcresult). Use `xcrun xcresulttool` to extract coverage data. Identify under-tested Swift files, ViewModels, Services.
   
   c. Read the plan in the research discussion and comments.
   
   d. Check most recent "[Test Coverage]" PR to see what was done previously and recommendations for next areas.
   
   e. Check for existing open test PRs to avoid duplicate work.
   
   f. If plan needs updating, comment on the discussion with revised plan.
   
   g. Select an area of low coverage to work on (e.g., a ViewModel with no tests, a Service method with no coverage).

2. **Implement Test Improvements**
   
   a. Create a new branch starting with "test/".
   
   b. Write new Swift tests using XCTest:
      - For ViewModels: Test state changes, async operations, error handling
      - For Services: Test API calls (with mocks), Keychain operations, OAuth flow
      - For Models: Test data parsing, validation, edge cases
      - Use Swift async/await patterns for testing async code
      - Apply @MainActor where needed for UI-bound ViewModels
   
   c. Build the tests to ensure no compilation errors:
      ```bash
      xcodebuild build-for-testing \
        -scheme TodoHub \
        -project TodoHub.xcodeproj \
        -destination 'platform=iOS Simulator,name=iPhone 16' \
        CODE_SIGNING_ALLOWED=NO
      ```
   
   d. Run the new tests to ensure they pass:
      ```bash
      xcodebuild test \
        -scheme TodoHub \
        -project TodoHub.xcodeproj \
        -destination 'platform=iOS Simulator,name=iPhone 16' \
        -only-testing:TodoHubTests \
        CODE_SIGNING_ALLOWED=NO
      ```
   
   e. Re-run with coverage to verify improvement. Document measurements.

3. **Finalize Changes**
   
   a. Apply Swift code formatting if used (check `.swiftformat` or CI files).
   
   b. Run SwiftLint if configured and fix any new warnings.

4. **Create Results PR**
   
   a. If successful, create a **draft** PR with your changes.
      
      **Critical:** Exclude TestResults.xcresult and other generated files from PR.
      
      Include in PR description:
      - **Goal and Rationale**: Which area was tested and why
      - **Approach**: Testing strategy (mocks, async patterns, etc.)
      - **Impact Measurement**: Coverage before/after with exact numbers
      - **Trade-offs**: Test complexity, maintenance considerations
      - **Validation**: How tests were verified
      - **Future Work**: Additional coverage opportunities
      
      **Test Coverage Results Section:**
      Document coverage impact in a table:
      ```
      | Module/File | Coverage Before | Coverage After |
      |-------------|-----------------|----------------|
      | AuthViewModel | 0% | 75% |
      | Overall | 42% | 48% |
      ```
      
      **Reproducibility Section:**
      Provide clear instructions to reproduce:
      ```bash
      # Build for testing
      xcodebuild build-for-testing ...
      
      # Run tests with coverage
      xcodebuild test ...
      
      # Extract coverage
      xcrun xcresulttool get ...
      ```
   
   b. If you found bugs while testing, create one issue titled "[Test Coverage] - Bugs Found" listing them all. Don't fix bugs in the PR unless 100% certain.

5. **Final Update**
   
   Add brief comment to the research discussion: goal worked on, PR link, coverage improvement numbers, and current overall coverage.

## iOS Testing Best Practices

- **Mock GitHub API**: Don't make real API calls in tests
- **Use Test Doubles**: Mock GitHubAPIService for ViewModel tests
- **Async Testing**: Use `await` and expectations properly
- **Actor Isolation**: Test @MainActor classes on main thread
- **Keychain Mocking**: Don't use real Keychain in tests
- **UI Tests**: Keep minimal - focus on critical user flows only
- **Fast Tests**: Unit tests should run quickly (< 1 second each)
