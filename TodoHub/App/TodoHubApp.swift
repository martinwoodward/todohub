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
    @EnvironmentObject var todoListViewModel: TodoListViewModel
    @State private var selectedTab = 0
    @State private var showingAddTodo = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            TodoListView()
                .tabItem {
                    Label("My Todos", systemImage: "checklist")
                }
                .tag(0)
            
            AllIssuesView()
                .tabItem {
                    Label("All Issues", systemImage: "globe")
                }
                .tag(1)

            Color.clear
                .tabItem {
                    Label("Add", systemImage: "plus.circle.fill")
                }
                .tag(2)
            
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            if newValue == 2 {
                showingAddTodo = true
                selectedTab = oldValue
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
