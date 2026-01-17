//
//  TodoListView.swift
//  TodoHub
//
//  Copyright (c) 2025 Martin Woodward
//  Licensed under MIT License
//

import SwiftUI

struct TodoListView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = TodoListViewModel()
    @State private var showingAddTodo = false
    @State private var showingSettings = false
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.todos.isEmpty {
                    ProgressView("Loading todos...")
                } else if viewModel.todos.isEmpty {
                    EmptyTodoView(onAddTodo: { showingAddTodo = true })
                } else {
                    todoList
                }
            }
            .navigationTitle("My Todos")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        AvatarView(login: authViewModel.currentUser?.login)
                    }
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            .sheet(isPresented: $showingAddTodo) {
                QuickAddView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .task {
                await viewModel.loadTodos()
            }
        }
    }
    
    private var todoList: some View {
        List {
            // Overdue
            if !viewModel.overdueTodos.isEmpty {
                Section {
                    ForEach(viewModel.overdueTodos) { todo in
                        TodoRowView(todo: todo, viewModel: viewModel)
                    }
                } header: {
                    Label("Overdue", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                }
            }
            
            // Today
            if !viewModel.todayTodos.isEmpty {
                Section {
                    ForEach(viewModel.todayTodos) { todo in
                        TodoRowView(todo: todo, viewModel: viewModel)
                    }
                } header: {
                    Label("Today", systemImage: "calendar")
                }
            }
            
            // Upcoming
            if !viewModel.upcomingTodos.isEmpty {
                Section {
                    ForEach(viewModel.upcomingTodos) { todo in
                        TodoRowView(todo: todo, viewModel: viewModel)
                    }
                } header: {
                    Label("Upcoming", systemImage: "calendar.badge.clock")
                }
            }
            
            // No Due Date
            if !viewModel.noDueDateTodos.isEmpty {
                Section {
                    ForEach(viewModel.noDueDateTodos) { todo in
                        TodoRowView(todo: todo, viewModel: viewModel)
                    }
                } header: {
                    Label("No Due Date", systemImage: "tray")
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

struct EmptyTodoView: View {
    let onAddTodo: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 64))
                .foregroundStyle(.green.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("All caught up!")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Add your first todo to get started")
                    .foregroundStyle(.secondary)
            }
            
            Button(action: onAddTodo) {
                Label("Add Todo", systemImage: "plus")
                    .fontWeight(.medium)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
        }
    }
}

#Preview {
    TodoListView()
        .environmentObject(AuthViewModel())
}
