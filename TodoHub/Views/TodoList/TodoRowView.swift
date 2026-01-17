//
//  TodoRowView.swift
//  TodoHub
//
//  Copyright (c) 2025 Martin Woodward
//  Licensed under MIT License
//

import SwiftUI

struct TodoRowView: View {
    let todo: Todo
    @ObservedObject var viewModel: TodoListViewModel
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: { 
            // Don't allow editing pending todos
            if !todo.isPending {
                showingDetail = true 
            }
        }) {
            HStack(alignment: .top, spacing: 12) {
                // Checkbox or pending indicator
                if todo.isPending {
                    ProgressView()
                        .scaleEffect(0.8)
                        .frame(width: 28, height: 28)
                } else if todo.pendingError != nil {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.red)
                } else {
                    Button(action: {
                        Task {
                            await viewModel.toggleComplete(todo)
                        }
                    }) {
                        Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundStyle(todo.isCompleted ? .green : .secondary)
                    }
                    .buttonStyle(.plain)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(todo.title)
                        .font(.body)
                        .foregroundStyle(todo.isPending ? .secondary : (todo.isCompleted ? .secondary : .primary))
                        .strikethrough(todo.isCompleted)
                        .lineLimit(2)
                    
                    // Error message for failed todos
                    if todo.pendingError != nil {
                        HStack(spacing: 12) {
                            Text("Failed to save")
                                .font(.caption)
                                .foregroundStyle(.red)
                            
                            Button("Retry") {
                                viewModel.retryFailedTodo(todo)
                            }
                            .font(.caption.bold())
                            .foregroundStyle(.blue)
                            
                            Button("Remove") {
                                viewModel.removeFailedTodo(todo)
                            }
                            .font(.caption.bold())
                            .foregroundStyle(.red)
                        }
                    } else {
                        // Metadata row
                        HStack(spacing: 8) {
                            // Priority badge
                            if todo.priority != .none {
                                PriorityBadge(priority: todo.priority)
                            }
                            
                            // Due date badge
                            if let dueDate = todo.dueDate {
                                DueDateBadge(date: dueDate, isOverdue: todo.isOverdue)
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 4)
            .opacity(todo.isPending ? 0.7 : 1.0)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if !todo.isPending {
                Button(role: .destructive) {
                    Task {
                        await viewModel.deleteTodo(todo)
                    }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            if !todo.isPending {
                Button {
                    Task {
                        await viewModel.toggleComplete(todo)
                    }
                } label: {
                    Label(todo.isCompleted ? "Undo" : "Done", systemImage: todo.isCompleted ? "arrow.uturn.backward" : "checkmark")
                }
                .tint(.green)
            }
        }
        .sheet(isPresented: $showingDetail) {
            TodoDetailView(todo: todo, viewModel: viewModel)
        }
    }
}

#Preview {
    List {
        TodoRowView(
            todo: Todo.preview,
            viewModel: TodoListViewModel()
        )
    }
}
