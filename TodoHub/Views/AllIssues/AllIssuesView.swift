//
//  AllIssuesView.swift
//  TodoHub
//
//  Copyright (c) 2025 Martin Woodward
//  Licensed under MIT License
//

import SwiftUI

struct AllIssuesView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var todoListViewModel: TodoListViewModel
    @StateObject private var viewModel = AllIssuesViewModel()
    @State private var searchText = ""
    @State private var selectedOrg: String?
    @State private var showingSettings = false
    @State private var flyingIssueId: String?
    
    var body: some View {
        NavigationStack {
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
                    issuesList
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
                SettingsView()
            }
            .task {
                await viewModel.loadIssues()
            }
        }
    }
    
    private var issuesList: some View {
        List {
            ForEach(groupedIssues.keys.sorted(), id: \.self) { repoName in
                Section {
                    ForEach(groupedIssues[repoName] ?? []) { issue in
                        IssueRowView(
                            issue: issue,
                            viewModel: viewModel,
                            isFlying: flyingIssueId == issue.id,
                            onAddToTodoList: {
                                await addIssueToTodoList(issue)
                            }
                        )
                    }
                } header: {
                    Text(repoName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
        }
        .listStyle(.insetGrouped)
        .animation(.spring(duration: 0.3), value: filteredIssues.map(\.id))
    }
    
    private func addIssueToTodoList(_ issue: Todo) async {
        // Start fly animation
        withAnimation(.easeIn(duration: 0.3)) {
            flyingIssueId = issue.id
        }
        
        // Wait for animation
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        // Add to project
        await viewModel.addToTodoList(issue)
        
        // Add to local todo list immediately
        var todoIssue = issue
        todoIssue.projectItemId = "pending"
        todoListViewModel.todos.insert(todoIssue, at: 0)
        
        // Remove from all issues view
        viewModel.issues.removeAll { $0.id == issue.id }
        
        // Reset animation state
        flyingIssueId = nil
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

struct EmptyIssuesView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text("No issues assigned")
                .font(.title3)
                .fontWeight(.medium)
            
            Text("Issues assigned to you across GitHub will appear here")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

struct IssueRowView: View {
    let issue: Todo
    @ObservedObject var viewModel: AllIssuesViewModel
    let isFlying: Bool
    let onAddToTodoList: () async -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button(action: {
                Task {
                    await viewModel.markAsDone(issue)
                }
            }) {
                Image(systemName: "circle")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(issue.title)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    Text("#\(issue.issueNumber)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if let date = issue.createdAt as Date? {
                        Text(date, style: .relative)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Add to todo list button
            Button(action: {
                Task {
                    await onAddToTodoList()
                }
            }) {
                Image(systemName: "plus.circle")
                    .font(.title2)
                    .foregroundStyle(.green)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .opacity(isFlying ? 0 : 1)
        .offset(x: isFlying ? -UIScreen.main.bounds.width : 0)
        .scaleEffect(isFlying ? 0.5 : 1)
    }
}

#Preview {
    AllIssuesView()
        .environmentObject(AuthViewModel())
        .environmentObject(TodoListViewModel())
}
