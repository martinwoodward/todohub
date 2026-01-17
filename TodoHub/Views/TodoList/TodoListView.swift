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
    @EnvironmentObject var viewModel: TodoListViewModel
    @State private var showingSettings = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Group {
                    if viewModel.isLoading && viewModel.todos.isEmpty {
                        ProgressView("Loading todos...")
                    } else if viewModel.todos.isEmpty {
                        EmptyTodoView()
                    } else {
                        todoList
                    }
                }
                
                // Inline add view at bottom
                VStack {
                    Spacer()
                    InlineAddView(viewModel: viewModel)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)
                }
            }
            .navigationTitle(Config.defaultProjectName)
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
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
            .onMove { from, to in
                Task {
                    await viewModel.moveTodo(from: from, to: to)
                }
            }
            
            // Spacer to prevent list content from being hidden by inline add view
            Color.clear
                .frame(height: 80)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .animation(.spring(duration: 0.4), value: viewModel.todos)
    }
}

struct EmptyTodoView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 64))
                .foregroundStyle(.green.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("All caught up!")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Type below to add your first todo")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    TodoListView()
        .environmentObject(AuthViewModel())
        .environmentObject(TodoListViewModel())
}
