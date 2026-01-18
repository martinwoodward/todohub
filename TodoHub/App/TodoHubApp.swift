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
    @State private var showingAddTodo = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Content views
            Group {
                switch selectedTab {
                case 0:
                    TodoListView()
                case 1:
                    AllIssuesView()
                default:
                    TodoListView()
                }
            }
            
            // Custom tab bar
            CustomTabBar(selectedTab: $selectedTab) {
                showingAddTodo = true
            }
        }
        .sheet(isPresented: $showingAddTodo) {
            QuickAddView(viewModel: todoListViewModel)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
        .environmentObject(TodoListViewModel())
}
