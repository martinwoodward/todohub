//
//  TodoHubApp.swift
//  TodoHub
//
//  Copyright (c) 2025 Martin Woodward
//  Licensed under MIT License
//

import SwiftUI

@main
struct TodoHubApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var todoListViewModel = TodoListViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(todoListViewModel)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                if authViewModel.selectedRepository == nil {
                    RepoSelectionView()
                } else {
                    MainTabView()
                }
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut, value: authViewModel.isAuthenticated)
    }
}

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var todoListViewModel: TodoListViewModel
    @State private var selectedTab = 0
    @State private var submitInlineAddTrigger = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        // Use split view on iPad in landscape (regular width), tab view everywhere else
        if SplitViewHelper.shouldUseSplitView(horizontalSizeClass: horizontalSizeClass) {
            iPadSplitView
        } else {
            compactTabView
        }
    }
    
    // iPad split view layout
    private var iPadSplitView: some View {
        TabView(selection: $selectedTab) {
            SplitViewContainer()
                .environmentObject(authViewModel)
                .environmentObject(todoListViewModel)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            AllIssuesView()
                .tabItem {
                    Label("All Issues", systemImage: "tray.fill")
                }
                .tag(1)
        }
    }
    
    // Compact layout for iPhone and iPad portrait
    private var compactTabView: some View {
        ZStack(alignment: .bottom) {
            // Content views
            Group {
                switch selectedTab {
                case 0:
                    TodoListView(submitTrigger: $submitInlineAddTrigger)
                case 1:
                    AllIssuesView()
                default:
                    TodoListView(submitTrigger: $submitInlineAddTrigger)
                }
            }
            
            // Custom tab bar
            CustomTabBar(selectedTab: $selectedTab) {
                // Trigger submit in InlineAddView
                submitInlineAddTrigger.toggle()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
        .environmentObject(TodoListViewModel())
}
