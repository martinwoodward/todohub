//
//  TodoDetailView.swift
//  TodoHub
//
//  Copyright (c) 2025 Martin Woodward
//  Licensed under MIT License
//

import SwiftUI

struct TodoDetailView: View {
    @State private var todo: Todo
    @ObservedObject var viewModel: TodoListViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var isEditing = false
    @State private var editedTitle: String
    @State private var editedBody: String
    @State private var editedDueDate: Date?
    @State private var editedPriority: Priority
    @State private var showDatePicker = false
    @State private var isSaving = false
    
    init(todo: Todo, viewModel: TodoListViewModel) {
        self._todo = State(initialValue: todo)
        self.viewModel = viewModel
        self._editedTitle = State(initialValue: todo.title)
        self._editedBody = State(initialValue: todo.body ?? "")
        self._editedDueDate = State(initialValue: todo.dueDate)
        self._editedPriority = State(initialValue: todo.priority)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Title
                    VStack(alignment: .leading, spacing: 8) {
                        if isEditing {
                            TextField("Title", text: $editedTitle, axis: .vertical)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .lineLimit(3...6)
                        } else {
                            Text(todo.title)
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                    }
                    
                    Divider()
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        
                        if isEditing {
                            TextEditor(text: $editedBody)
                                .frame(minHeight: 100)
                                .padding(8)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            if let body = todo.body, !body.isEmpty {
                                Text(body)
                                    .foregroundStyle(.primary)
                            } else {
                                Text("No description")
                                    .foregroundStyle(.secondary)
                                    .italic()
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Metadata
                    VStack(spacing: 16) {
                        // Due Date
                        HStack {
                            Label("Due Date", systemImage: "calendar")
                                .foregroundStyle(.secondary)
                            Spacer()
                            if isEditing {
                                Button(action: { showDatePicker.toggle() }) {
                                    if let date = editedDueDate {
                                        Text(date.formatted(date: .abbreviated, time: .omitted))
                                            .foregroundStyle(.blue)
                                    } else {
                                        Text("Set Date")
                                            .foregroundStyle(.blue)
                                    }
                                }
                            } else {
                                if let date = todo.dueDate {
                                    Text(date.formatted(date: .abbreviated, time: .omitted))
                                } else {
                                    Text("None")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        
                        if showDatePicker && isEditing {
                            DatePicker(
                                "Due Date",
                                selection: Binding(
                                    get: { editedDueDate ?? Date() },
                                    set: { editedDueDate = $0 }
                                ),
                                displayedComponents: [.date]
                            )
                            .datePickerStyle(.graphical)
                            
                            if editedDueDate != nil {
                                Button("Clear Date", role: .destructive) {
                                    editedDueDate = nil
                                    showDatePicker = false
                                }
                            }
                        }
                        
                        Divider()
                        
                        // Priority
                        HStack {
                            Label("Priority", systemImage: "flag")
                                .foregroundStyle(.secondary)
                            Spacer()
                            if isEditing {
                                Menu {
                                    ForEach(Priority.allCases, id: \.self) { p in
                                        Button(action: { editedPriority = p }) {
                                            HStack {
                                                Text(p.rawValue)
                                                if editedPriority == p {
                                                    Image(systemName: "checkmark")
                                                }
                                            }
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(editedPriority.rawValue)
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.caption)
                                    }
                                    .foregroundStyle(editedPriority.color)
                                }
                            } else {
                                PriorityBadge(priority: todo.priority)
                            }
                        }
                        
                        Divider()
                        
                        // Assignees
                        HStack {
                            Label("Assigned to", systemImage: "person")
                                .foregroundStyle(.secondary)
                            Spacer()
                            if todo.assignees.isEmpty {
                                Text("Unassigned")
                                    .foregroundStyle(.secondary)
                            } else {
                                Text(todo.assignees.map { "@\($0)" }.joined(separator: ", "))
                            }
                        }
                        
                        Divider()
                        
                        // GitHub Link
                        HStack {
                            Label("GitHub Issue", systemImage: "link")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button(action: openInGitHub) {
                                HStack {
                                    Text("#\(todo.issueNumber)")
                                    Image(systemName: "arrow.up.right")
                                        .font(.caption)
                                }
                                .foregroundStyle(.blue)
                            }
                        }
                    }
                    
                    Spacer(minLength: 40)
                    
                    // Delete button
                    if !isEditing {
                        Button(role: .destructive) {
                            Task {
                                await viewModel.deleteTodo(todo)
                                dismiss()
                            }
                        } label: {
                            HStack {
                                Spacer()
                                Label("Delete Todo", systemImage: "trash")
                                Spacer()
                            }
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .foregroundStyle(.red)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(isEditing ? "Edit Todo" : "Todo Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isEditing ? "Cancel" : "Done") {
                        if isEditing {
                            cancelEditing()
                        } else {
                            dismiss()
                        }
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    if isEditing {
                        Button("Save") {
                            Task {
                                await save()
                            }
                        }
                        .disabled(editedTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                    } else {
                        Button("Edit") {
                            isEditing = true
                        }
                    }
                }
            }
            .animation(.easeInOut, value: isEditing)
            .animation(.easeInOut, value: showDatePicker)
        }
    }
    
    private func cancelEditing() {
        editedTitle = todo.title
        editedBody = todo.body ?? ""
        editedDueDate = todo.dueDate
        editedPriority = todo.priority
        showDatePicker = false
        isEditing = false
    }
    
    private func save() async {
        isSaving = true
        defer { isSaving = false }
        
        var updatedTodo = todo
        updatedTodo.body = editedBody.isEmpty ? nil : editedBody
        updatedTodo.dueDate = editedDueDate
        updatedTodo.priority = editedPriority
        updatedTodo.updatedAt = Date()
        
        // Note: title is immutable in current model, would need to update via API
        
        await viewModel.updateTodo(updatedTodo)
        todo = updatedTodo
        isEditing = false
    }
    
    private func openInGitHub() {
        let urlString = "https://github.com/\(todo.repositoryFullName)/issues/\(todo.issueNumber)"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    TodoDetailView(todo: Todo.preview, viewModel: TodoListViewModel())
}
