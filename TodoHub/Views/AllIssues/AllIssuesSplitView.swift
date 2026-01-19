//
//  AllIssuesSplitView.swift
//  TodoHub
//
//  Copyright (c) 2025 Martin Woodward
//  Licensed under MIT License
//

import SwiftUI

/// iPad-optimized split view for All Issues
struct AllIssuesSplitView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var todoListViewModel: TodoListViewModel
    @StateObject private var viewModel = AllIssuesViewModel()
    @State private var selectedIssueId: String?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar (List)
            AllIssuesListView(
                viewModel: viewModel,
                selectedIssueId: $selectedIssueId
            )
            .environmentObject(authViewModel)
            .environmentObject(todoListViewModel)
        } detail: {
            // Detail view
            if let selectedIssueId = selectedIssueId,
               let issue = viewModel.issues.first(where: { $0.id == selectedIssueId }) {
                AllIssuesDetailView(
                    issue: issue,
                    viewModel: viewModel
                )
                .environmentObject(todoListViewModel)
            } else {
                // Empty state when no issue is selected
                AllIssuesEmptyDetailView()
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
}

/// List view for All Issues split view
struct AllIssuesListView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var todoListViewModel: TodoListViewModel
    @ObservedObject var viewModel: AllIssuesViewModel
    @Binding var selectedIssueId: String?
    @State private var searchText = ""
    @State private var selectedOrg: String?
    @State private var showingSettings = false
    
    var body: some View {
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
                            Button("Done") {
                                showingSettings = false
                            }
                        }
                    }
            }
        }
        .task {
            await viewModel.loadIssues()
        }
    }
    
    private var filteredIssues: [Todo] {
        // Get issue IDs already in todo list
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

/// Simple row view for issue in split view
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
        }
        .padding(.vertical, 4)
    }
}

/// Detail view for a single issue in All Issues split view
struct AllIssuesDetailView: View {
    let issue: Todo
    @ObservedObject var viewModel: AllIssuesViewModel
    @EnvironmentObject var todoListViewModel: TodoListViewModel
    @State private var isAddingToTodoList = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Title
                Text(issue.title)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Divider()
                
                // Description
                if let body = issue.body, !body.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        
                        Text(body)
                            .foregroundStyle(.primary)
                    }
                    
                    Divider()
                }
                
                // Metadata
                VStack(spacing: 16) {
                    // Repository
                    HStack {
                        Label("Repository", systemImage: "folder")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(issue.repositoryFullName)
                    }
                    
                    Divider()
                    
                    // Created date
                    HStack {
                        Label("Created", systemImage: "calendar")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(issue.createdAt.formatted(date: .abbreviated, time: .omitted))
                    }
                    
                    Divider()
                    
                    // Assignees
                    HStack {
                        Label("Assigned to", systemImage: "person")
                            .foregroundStyle(.secondary)
                        Spacer()
                        if issue.assignees.isEmpty {
                            Text("Unassigned")
                                .foregroundStyle(.secondary)
                        } else {
                            Text(issue.assignees.map { "@\($0)" }.joined(separator: ", "))
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
                                Text("#\(issue.issueNumber)")
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                            }
                            .foregroundStyle(.blue)
                        }
                    }
                }
                
                Spacer(minLength: 40)
                
                // Action buttons
                VStack(spacing: 12) {
                    // Add to Todo List button
                    Button {
                        Task {
                            await addToTodoList()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if isAddingToTodoList {
                                ProgressView()
                                    .progressViewStyle(.circular)
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
                    
                    // Mark as Done button
                    Button {
                        Task {
                            await viewModel.markAsDone(issue)
                        }
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
    
    private func addToTodoList() async {
        isAddingToTodoList = true
        defer { isAddingToTodoList = false }
        
        // Add to project
        await viewModel.addToTodoList(issue)
        
        // Add to local todo list immediately
        var todoIssue = issue
        todoIssue.projectItemId = "pending"
        todoListViewModel.todos.insert(todoIssue, at: 0)
        
        // Remove from all issues view
        viewModel.issues.removeAll { $0.id == issue.id }
    }
    
    private func openInGitHub() {
        let urlString = "https://github.com/\(issue.repositoryFullName)/issues/\(issue.issueNumber)"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

/// Empty state when no issue is selected in All Issues split view
struct AllIssuesEmptyDetailView: View {
    var body: some View {
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

#Preview("All Issues Split View") {
    AllIssuesSplitView()
        .environmentObject(AuthViewModel())
        .environmentObject(TodoListViewModel())
}
