//
//  AllIssuesView.swift
//  TodoHub
//
//  Copyright (c) 2025 Martin Woodward
//  Licensed under MIT License
//

import SwiftUI

struct AllIssuesView: View {
    @StateObject private var viewModel = AllIssuesViewModel()
    @State private var searchText = ""
    @State private var selectedOrg: String?
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.issues.isEmpty {
                    LoadingView("Loading issues...")
                } else if viewModel.issues.isEmpty {
                    EmptyIssuesView()
                } else {
                    issuesList
                }
            }
            .navigationTitle("All Issues")
            .searchable(text: $searchText, prompt: "Search issues...")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
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
            }
            .refreshable {
                await viewModel.refresh()
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
                        IssueRowView(issue: issue, viewModel: viewModel)
                    }
                } header: {
                    Text(repoName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    private var filteredIssues: [Todo] {
        var issues = viewModel.issues
        
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
                    await viewModel.addToTodoList(issue)
                }
            }) {
                Image(systemName: "plus.circle")
                    .font(.title2)
                    .foregroundStyle(.green)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    AllIssuesView()
}
