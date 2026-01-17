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
        Button(action: { showingDetail = true }) {
            HStack(alignment: .top, spacing: 12) {
                // Checkbox
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
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(todo.title)
                        .font(.body)
                        .foregroundStyle(todo.isCompleted ? .secondary : .primary)
                        .strikethrough(todo.isCompleted)
                        .lineLimit(2)
                    
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
                
                Spacer()
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                Task {
                    await viewModel.deleteTodo(todo)
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                Task {
                    await viewModel.toggleComplete(todo)
                }
            } label: {
                Label(todo.isCompleted ? "Undo" : "Done", systemImage: todo.isCompleted ? "arrow.uturn.backward" : "checkmark")
            }
            .tint(.green)
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
