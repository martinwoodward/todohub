# iPad Implementation Guide

## Overview

TodoHub has been optimized for iPad with a native, adaptive user interface that takes advantage of iPad's larger screen and multitasking capabilities.

## Design Philosophy

The iPad version follows Apple's Human Interface Guidelines for iPad apps:

1. **Adaptive Layouts** - Automatically adjusts between portrait and landscape orientations
2. **Split View** - Master-detail interface in landscape mode for efficient navigation
3. **Multitasking Support** - Works seamlessly in Split View and Slide Over
4. **Touch-First** - Large, accessible touch targets optimized for direct interaction

## Architecture

### Device Detection

The app uses `Device+Extensions.swift` to detect device type and adapt accordingly:

```swift
// Check device type
UIDevice.isIPad  // true on iPad
UIDevice.isIPhone  // true on iPhone

// Check if split view should be used
SplitViewHelper.shouldUseSplitView(horizontalSizeClass: .regular)
```

### Layout Modes

TodoHub uses three different layout modes:

#### 1. iPhone Mode (Compact)
- Custom tab bar at bottom
- Modal sheets for detail views
- Optimized for one-handed use

#### 2. iPad Portrait Mode
- Standard tab view with tabs at top
- More spacing and padding
- Still uses sheets for detail views

#### 3. iPad Landscape Mode (Split View)
- Two-column layout using `NavigationSplitView`
- Todo list in left sidebar
- Detail view always visible on right
- No modal sheets - navigation is inline

### Key Components

#### SplitViewContainer
Main container for iPad split view interface in landscape mode.

**Features:**
- Left sidebar: Todo list with inline add functionality
- Right detail: Full todo details with edit capabilities
- Persistent selection across orientation changes
- Smooth transitions between items

**Usage:**
```swift
SplitViewContainer()
    .environmentObject(authViewModel)
    .environmentObject(todoListViewModel)
```

#### AllIssuesSplitView
Split view interface for "All Issues" tab on iPad landscape.

**Features:**
- Left sidebar: Grouped issue list by repository
- Right detail: Issue details with action buttons
- Filter and search capabilities
- Quick actions to add to todo list or mark done

#### TodoDetailContentView
Reusable detail view component that works in both sheet and split view modes.

**Key differences from TodoDetailView:**
- No navigation wrapper (parent provides it)
- Adapts toolbar items based on context
- Optimized for persistent display

### Adaptive UI Elements

#### CustomTabBar
The custom tab bar automatically hides when split view is active on iPad landscape, replaced by standard TabView.

#### Settings Modal
On iPad, settings appear in a properly sized sheet with navigation stack, not the custom dropdown used on iPhone.

#### Quick Add View
Uses `.presentationDetents([.medium, .large])` to allow flexible sizing on iPad while maintaining compact presentation.

## Best Practices

### 1. Size Classes
Always check horizontal size class to determine layout:

```swift
@Environment(\.horizontalSizeClass) private var horizontalSizeClass

if SplitViewHelper.shouldUseSplitView(horizontalSizeClass: horizontalSizeClass) {
    // iPad landscape - use split view
} else {
    // iPhone or iPad portrait - use compact layout
}
```

### 2. Navigation Patterns
- **iPhone:** Modal sheets with "Done" or "Cancel" buttons
- **iPad Portrait:** Same as iPhone for consistency
- **iPad Landscape:** Inline navigation with persistent detail view

### 3. Touch Targets
- Minimum 44x44 points for all interactive elements
- More spacing between elements on iPad
- Larger fonts where appropriate

### 4. Content Sizing
- Use `frame(maxWidth:)` to limit content width on larger screens
- Provide appropriate padding for readability
- Consider landscape orientation in all designs

## Multitasking Support

TodoHub supports all iPad multitasking features:

### Split View
Works seamlessly when running alongside another app. The app automatically adapts to the available width.

### Slide Over
Functions correctly in narrow slide-over mode, falling back to compact layout.

### Multiple Windows
`UIApplicationSupportsMultipleScenes` is enabled in Info.plist, allowing users to open multiple windows of TodoHub on iPad.

## Testing Checklist

When testing iPad features, verify:

- [ ] App launches correctly on iPad simulator
- [ ] Portrait orientation displays properly
- [ ] Landscape orientation shows split view
- [ ] Rotation transitions are smooth
- [ ] Split view master-detail navigation works
- [ ] Items can be selected and viewed
- [ ] Todo list sidebar is scrollable
- [ ] Detail view updates when todos change
- [ ] Settings modal appears correctly
- [ ] Quick add sheet sizes appropriately
- [ ] Tab navigation works in landscape
- [ ] All gestures work (swipe actions, pull to refresh)
- [ ] Keyboard shortcuts work (if implemented)
- [ ] Split View multitasking works
- [ ] Slide Over multitasking works

## Future Enhancements

Potential iPad-specific features for future releases:

1. **Keyboard Shortcuts** - Add keyboard navigation and shortcuts
2. **Drag and Drop** - Support dragging todos between lists
3. **Pointer Support** - Add hover effects for mouse/trackpad
4. **Context Menus** - Right-click menus for power users
5. **Picture in Picture** - For any future video content
6. **Focus Modes** - Integration with iOS Focus modes
7. **Multiple Windows** - Support for multiple todo lists in different windows

## Resources

- [Apple HIG: iPad Apps](https://developer.apple.com/design/human-interface-guidelines/ipad)
- [NavigationSplitView Documentation](https://developer.apple.com/documentation/swiftui/navigationsplitview)
- [Size Classes Documentation](https://developer.apple.com/design/human-interface-guidelines/layout)
- [Multitasking on iPad](https://developer.apple.com/design/human-interface-guidelines/multitasking)
