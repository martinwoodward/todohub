//
//  SplitViewContainer.swift
//  TodoHub
//
//  Copyright (c) 2025 Martin Woodward
//  Licensed under MIT License
//

import SwiftUI

/// iPad-optimized split view that shows todo list on left, detail on right
struct SplitViewContainer: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var viewModel: TodoListViewModel
    @State private var selectedTodoId: String?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar (List)
            TodoListSidebarView(selectedTodoId: $selectedTodoId)
                .environmentObject(authViewModel)
                .environmentObject(viewModel)
        } detail: {
            // Detail view
            if let selectedTodoId = selectedTodoId,
               let todo = viewModel.todos.first(where: { $0.id == selectedTodoId }) {
                TodoDetailContentView(todo: todo, viewModel: viewModel)
                    .navigationTitle("Todo Details")
                    .navigationBarTitleDisplayMode(.inline)
            } else {
                // Empty state when no todo is selected
                SplitViewEmptyDetailView()
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
}

/// Sidebar view for split view on iPad
struct TodoListSidebarView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var viewModel: TodoListViewModel
    @Binding var selectedTodoId: String?
    @State private var showingSettings = false
    @State private var showingQuickAdd = false
    @State private var inlineAddTitle = ""
    @FocusState private var isAddFieldFocused: Bool
    
    var body: some View {
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
            
            // Inline add view at bottom
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
                            Button("Done") {
                                showingSettings = false
                            }
                        }
                    }
            }
        }
        .task {
            await viewModel.loadTodos()
        }
    }
}

/// Reusable content view for todo rows (used in both list and split views)
struct TodoRowContentView: View {
    let todo: Todo
    @ObservedObject var viewModel: TodoListViewModel
    
    var body: some View {
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
    }
}

/// Detail content view without navigation wrapper (for iPad split view)
struct TodoDetailContentView: View {
    @State private var todo: Todo
    @ObservedObject var viewModel: TodoListViewModel
    
    @State private var isEditing = true
    @State private var editedTitle: String
    @State private var editedBody: String
    @State private var editedDueDate: Date?
    @State private var editedPriority: Priority
    @State private var showDatePicker = false
    @State private var isSaving = false
    @State private var isAssigningToCopilot = false
    @State private var showDeleteConfirmation = false
    
    init(todo: Todo, viewModel: TodoListViewModel) {
        self._todo = State(initialValue: todo)
        self.viewModel = viewModel
        self._editedTitle = State(initialValue: todo.title)
        self._editedBody = State(initialValue: todo.body ?? "")
        self._editedDueDate = State(initialValue: todo.dueDate)
        self._editedPriority = State(initialValue: todo.priority)
    }
    
    var body: some View {
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
                    
                    // Assign to Copilot button
                    if isEditing && !todo.assignees.contains(GitHubAPIService.copilotUsername) {
                        Button {
                            Task {
                                await assignToCopilot()
                            }
                        } label: {
                            HStack {
                                Image("CopilotIcon")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                                Text("Assign to Copilot")
                                Spacer()
                                if isAssigningToCopilot {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .disabled(isAssigningToCopilot)
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
                Button(role: .destructive) {
                    showDeleteConfirmation = true
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
            .padding()
        }
        .toolbar {
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
            
            ToolbarItem(placement: .cancellationAction) {
                if isEditing {
                    Button("Cancel") {
                        // Reset editing state
                        editedTitle = todo.title
                        editedBody = todo.body ?? ""
                        editedDueDate = todo.dueDate
                        editedPriority = todo.priority
                        isEditing = false
                    }
                }
            }
        }
        .confirmationDialog("Delete Todo", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteTodo(todo)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this todo?")
        }
        .animation(.easeInOut, value: isEditing)
        .animation(.easeInOut, value: showDatePicker)
        .onChange(of: viewModel.todos) { _, newTodos in
            // Update local todo state when it changes in view model
            if let updatedTodo = newTodos.first(where: { $0.id == todo.id }) {
                todo = updatedTodo
            }
        }
    }
    
    private func save() async {
        isSaving = true
        defer { isSaving = false }
        
        var updatedTodo = todo
        updatedTodo.title = editedTitle
        updatedTodo.body = editedBody.isEmpty ? nil : editedBody
        updatedTodo.dueDate = editedDueDate
        updatedTodo.priority = editedPriority
        updatedTodo.updatedAt = Date()
        
        await viewModel.updateTodo(updatedTodo)
        
        isEditing = false
    }
    
    private func openInGitHub() {
        let urlString = "https://github.com/\(todo.repositoryFullName)/issues/\(todo.issueNumber)"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func assignToCopilot() async {
        isAssigningToCopilot = true
        defer { isAssigningToCopilot = false }
        
        await viewModel.assignToCopilot(todo)
        
        // Update local state to reflect the assignment from view model
        if let updatedTodo = viewModel.todos.first(where: { $0.id == todo.id }) {
            todo = updatedTodo
        }
    }
}

/// Empty state when no todo is selected in split view
struct SplitViewEmptyDetailView: View {
    var body: some View {
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

#Preview("Split View") {
    SplitViewContainer()
        .environmentObject(AuthViewModel())
        .environmentObject(TodoListViewModel())
}
