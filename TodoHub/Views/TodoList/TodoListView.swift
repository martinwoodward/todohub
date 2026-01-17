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
            ForEach(viewModel.todos.filter { !$0.isCompleted }) { todo in
                TodoRowView(todo: todo, viewModel: viewModel)
            }
            .onMove { from, to in
                Task {
                    await viewModel.moveTodo(from: from, to: to)
                }
            }
        }
        .listStyle(.plain)
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
