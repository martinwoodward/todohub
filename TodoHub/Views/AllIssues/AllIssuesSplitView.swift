//
//  AllIssuesSplitView.swift
//  TodoHub
//
//  Copyright (c) 2025 Martin Woodward
//  Licensed under MIT License
//

import SwiftUI

/// iPad split view for All Issues: issue list sidebar on left, detail on right.
struct AllIssuesSplitView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var todoListViewModel: TodoListViewModel
    @StateObject private var viewModel = AllIssuesViewModel()
    @State private var selectedIssueId: String?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var searchText = ""
    @State private var selectedOrg: String?
    @State private var showingSettings = false
    
    private var selectedIssue: Todo? {
        guard let id = selectedIssueId else { return nil }
        return viewModel.issues.first { $0.id == id }
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
        Group {
            if viewModel.isLoading && viewModel.issues.isEmpty {
                LoadingView("Loading issues...")
            } else if filteredIssues.isEmpty && viewModel.issues.isEmpty {
                EmptyIssuesView()
            } else if filteredIssues.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 48))
                        .foregroundStyle(.green.opacity(0.5))
                    Text("All issues are in your Todo List")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            } else {
                List(selection: $selectedIssueId) {
                    ForEach(groupedIssues.keys.sorted(), id: \.self) { repoName in
                        Section {
                            ForEach(groupedIssues[repoName] ?? []) { issue in
                                IssueRowSimpleView(issue: issue)
                                    .tag(issue.id)
                            }
                        } header: {
                            Text(repoName)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                    }
                }
                .listStyle(.sidebar)
            }
        }
        .navigationTitle("All Issues")
        .searchable(text: $searchText, prompt: "Search issues...")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Button("All Organizations") {
                        selectedOrg = nil
                    }
                    Divider()
                    ForEach(viewModel.organizations, id: \.self) { org in
                        Button(org) {
                            selectedOrg = org
                        }
                    }
                } label: {
                    Label(selectedOrg ?? "Filter", systemImage: "line.3.horizontal.decrease.circle")
                }
            }
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
            await viewModel.loadIssues()
        }
    }
    
    // MARK: - Detail
    
    @ViewBuilder
    private var detail: some View {
        if let issue = selectedIssue {
            IssueDetailView(
                issue: issue,
                viewModel: viewModel,
                todoListViewModel: todoListViewModel,
                onAddedToTodoList: {
                    selectedIssueId = nil
                }
            )
        } else {
            VStack(spacing: 24) {
                Image(systemName: "tray")
                    .font(.system(size: 64))
                    .foregroundStyle(.secondary.opacity(0.5))
                
                VStack(spacing: 8) {
                    Text("Select an Issue")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Choose an issue from the list to view details")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    // MARK: - Filtering
    
    private var filteredIssues: [Todo] {
        let todoIssueIds = Set(todoListViewModel.todos.map(\.issueId))
        var issues = viewModel.issues.filter { !todoIssueIds.contains($0.issueId) }
        
        if let org = selectedOrg {
            issues = issues.filter { $0.repositoryFullName.hasPrefix(org + "/") }
        }
        
        if !searchText.isEmpty {
            issues = issues.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.repositoryFullName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return issues
    }
    
    private var groupedIssues: [String: [Todo]] {
        Dictionary(grouping: filteredIssues, by: { $0.repositoryFullName })
    }
}

/// Compact row for issue list in iPad sidebar.
struct IssueRowSimpleView: View {
    let issue: Todo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(issue.title)
                .lineLimit(2)
            
            HStack(spacing: 8) {
                Text("#\(issue.issueNumber)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(issue.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

/// Detail view for a selected issue in the split view.
struct IssueDetailView: View {
    let issue: Todo
    @ObservedObject var viewModel: AllIssuesViewModel
    @ObservedObject var todoListViewModel: TodoListViewModel
    var onAddedToTodoList: () -> Void
    @State private var isAddingToTodoList = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(issue.title)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Divider()
                
                if let body = issue.body, !body.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        Text(body)
                    }
                    Divider()
                }
                
                // Metadata
                VStack(spacing: 16) {
                    metadataRow(icon: "folder", label: "Repository", value: issue.repositoryFullName)
                    Divider()
                    metadataRow(icon: "calendar", label: "Created", value: issue.createdAt.formatted(date: .abbreviated, time: .omitted))
                    Divider()
                    
                    HStack {
                        Label("Assigned to", systemImage: "person")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(issue.assignees.isEmpty ? "Unassigned" : issue.assignees.map { "@\($0)" }.joined(separator: ", "))
                            .foregroundStyle(issue.assignees.isEmpty ? .secondary : .primary)
                    }
                    
                    Divider()
                    
                    HStack {
                        Label("GitHub Issue", systemImage: "link")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Link(destination: URL(string: "https://github.com/\(issue.repositoryFullName)/issues/\(issue.issueNumber)")!) {
                            HStack {
                                Text("#\(issue.issueNumber)")
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                            }
                        }
                    }
                }
                
                Spacer(minLength: 40)
                
                // Actions
                VStack(spacing: 12) {
                    Button {
                        Task { await addToTodoList() }
                    } label: {
                        HStack {
                            Spacer()
                            if isAddingToTodoList {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Label("Add to Todo List", systemImage: "plus.circle")
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color.green)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(isAddingToTodoList)
                    
                    Button {
                        Task { await viewModel.markAsDone(issue) }
                    } label: {
                        HStack {
                            Spacer()
                            Label("Mark as Done", systemImage: "checkmark.circle")
                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Issue Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func metadataRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Label(label, systemImage: icon)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }
    }
    
    private func addToTodoList() async {
        isAddingToTodoList = true
        defer { isAddingToTodoList = false }
        
        await viewModel.addToTodoList(issue)
        
        var todoIssue = issue
        todoIssue.projectItemId = "pending"
        todoListViewModel.todos.insert(todoIssue, at: 0)
        viewModel.issues.removeAll { $0.id == issue.id }
        
        onAddedToTodoList()
    }
}

#Preview {
    AllIssuesSplitView()
        .environmentObject(AuthViewModel())
        .environmentObject(TodoListViewModel())
}
