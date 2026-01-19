//
//  KeyboardShortcuts.swift
//  TodoHub
//
//  Copyright (c) 2025 Martin Woodward
//  Licensed under MIT License
//

import SwiftUI

/// Keyboard shortcuts for iPad and Mac
struct KeyboardShortcutsModifier: ViewModifier {
    @EnvironmentObject var todoListViewModel: TodoListViewModel
    @Binding var selectedTab: Int
    @Binding var submitInlineAddTrigger: Bool
    
    func body(content: Content) -> some View {
        content
            // New todo: Cmd+N
            .keyboardShortcut("n", modifiers: .command) {
                submitInlineAddTrigger.toggle()
            }
            // Refresh: Cmd+R
            .keyboardShortcut("r", modifiers: .command) {
                Task {
                    await todoListViewModel.refresh()
                }
            }
            // Switch to home tab: Cmd+1
            .keyboardShortcut("1", modifiers: .command) {
                selectedTab = 0
            }
            // Switch to all issues tab: Cmd+2
            .keyboardShortcut("2", modifiers: .command) {
                selectedTab = 1
            }
    }
}

extension View {
    /// Add keyboard shortcuts to a view
    func withKeyboardShortcuts(selectedTab: Binding<Int>, submitTrigger: Binding<Bool>) -> some View {
        modifier(KeyboardShortcutsModifier(selectedTab: selectedTab, submitInlineAddTrigger: submitTrigger))
    }
}
