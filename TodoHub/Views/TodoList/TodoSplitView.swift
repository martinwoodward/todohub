//
//  TodoSplitView.swift
//  TodoHub
//
//  Copyright (c) 2025 Martin Woodward
//  Licensed under MIT License
//

import SwiftUI

/// iPad split view: todo list sidebar on left, detail pane on right.
struct TodoSplitView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var viewModel: TodoListViewModel
    @State private var selectedTodoId: String?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var showingSettings = false
    @State private var showingQuickAdd = false
    @State private var inlineAddTitle = ""
    @FocusState private var isAddFieldFocused: Bool
    
    private var selectedTodo: Todo? {
        guard let id = selectedTodoId else { return nil }
        return viewModel.todos.first { $0.id == id }
    }
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebar
        } detail: {
            detail
        }
        .navigationSplitViewStyle(.balanced)
    }
    
    // MARK: - Sidebar
    
    private var sidebar: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading && viewModel.todos.isEmpty {
                ProgressView("Loading todos...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.todos.isEmpty {
                EmptyTodoView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(selection: $selectedTodoId) {
                    ForEach(viewModel.todos.filter { !$0.isCompleted }) { todo in
                        TodoRowContentView(todo: todo, viewModel: viewModel)
                            .tag(todo.id)
                    }
                    .onMove { from, to in
                        Task {
                            await viewModel.moveTodo(from: from, to: to)
                        }
                    }
                }
                .listStyle(.sidebar)
            }
            
            // Inline add at bottom of sidebar
            InlineAddView(
                viewModel: viewModel,
                isFocused: $isAddFieldFocused,
                title: $inlineAddTitle,
                onExpandTapped: { showingQuickAdd = true }
            )
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
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
        .sheet(isPresented: $showingQuickAdd) {
            QuickAddView(viewModel: viewModel, title: $inlineAddTitle)
        }
        .sheet(isPresented: $showingSettings) {
            NavigationStack {
                SettingsView()
                    .navigationTitle("Settings")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showingSettings = false }
                        }
                    }
            }
        }
        .task {
            await viewModel.loadTodos()
        }
    }
    
    // MARK: - Detail
    
    @ViewBuilder
    private var detail: some View {
        if let todo = selectedTodo {
            TodoDetailContentView(todo: todo, viewModel: viewModel)
                .id(todo.id)
        } else {
            VStack(spacing: 24) {
                Image(systemName: "sidebar.left")
                    .font(.system(size: 64))
                    .foregroundStyle(.secondary.opacity(0.5))
                
                VStack(spacing: 8) {
                    Text("Select a Todo")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Choose a todo from the list to view details")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    TodoSplitView()
        .environmentObject(AuthViewModel())
        .environmentObject(TodoListViewModel())
}
