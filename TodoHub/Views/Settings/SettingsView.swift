//
//  SettingsView.swift
//  TodoHub
//
//  Copyright (c) 2025 Martin Woodward
//  Licensed under MIT License
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @AppStorage("appearance") private var appearance: Appearance = .system
    @State private var showingSignOutAlert = false
    @State private var showingRepoSelection = false
    
    var body: some View {
        NavigationStack {
            List {
                // Account section
                Section {
                    if let user = authViewModel.currentUser {
                        HStack(spacing: 12) {
                            // Avatar
                                AsyncImage(url: URL(string: user.avatarUrl ?? "")) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Image(systemName: "person.circle.fill")
                                        .font(.system(size: 44))
                                        .foregroundStyle(.secondary)
                                }
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("@\(user.login)")
                                        .fontWeight(.semibold)
                                    
                                    if let name = user.name {
                                        Text(name)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Button(action: openGitHubProfile) {
                                    Image(systemName: "arrow.up.right")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    } header: {
                        Text("Account")
                    }
                    
                    // Repository section
                    Section {
                        if let repo = authViewModel.selectedRepository {
                            HStack {
                                Image(systemName: repo.isPrivate ? "lock.fill" : "folder.fill")
                                    .foregroundStyle(.secondary)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(repo.fullName)
                                        .fontWeight(.medium)
                                }
                                
                                Spacer()
                            }
                            
                            Button("Change Repository") {
                                showingRepoSelection = true
                            }
                        } else {
                            Text("No repository selected")
                                .foregroundStyle(.secondary)
                            
                            Button("Select Repository") {
                                showingRepoSelection = true
                            }
                        }
                    } header: {
                        Text("Todo Repository")
                    }
                    
                    // Appearance section
                    Section {
                        Picker("Theme", selection: $appearance) {
                            ForEach(Appearance.allCases, id: \.self) { theme in
                                Text(theme.displayName).tag(theme)
                            }
                        }
                    } header: {
                        Text("Appearance")
                    }
                    
                    // Sync section
                    Section {
                        HStack {
                            Text("Last synced")
                            Spacer()
                            Text("Just now")
                                .foregroundStyle(.secondary)
                        }
                        
                        Button("Sync Now") {
                            // TODO: Force sync
                        }
                    } header: {
                        Text("Sync")
                    }
                    
                    // Help & Support section
                    Section {
                        Link(destination: URL(string: "https://github.com/martinwoodward/todohub#readme")!) {
                            Label("Help & Documentation", systemImage: "questionmark.circle")
                        }
                        
                        Link(destination: URL(string: "https://github.com/martinwoodward/todohub/issues/new")!) {
                            Label("Report an Issue", systemImage: "exclamationmark.bubble")
                        }
                        
                        Link(destination: URL(string: "mailto:support@todohub.app?subject=TodoHub%20Support")!) {
                            Label("Contact Support", systemImage: "envelope")
                        }
                    } header: {
                        Text("Help & Support")
                    }
                    
                    // Legal section
                    Section {
                        Link(destination: URL(string: "https://github.com/martinwoodward/todohub/blob/main/PRIVACY.md")!) {
                            Label("Privacy Policy", systemImage: "hand.raised")
                        }
                        
                        Link(destination: URL(string: "https://github.com/martinwoodward/todohub/blob/main/LICENSE")!) {
                            Label("Terms of Service", systemImage: "doc.text")
                        }
                    } header: {
                        Text("Legal")
                    }
                    
                    // About section
                    Section {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("1.0.0")
                                .foregroundStyle(.secondary)
                        }
                        
                        Link(destination: URL(string: "https://github.com/martinwoodward/todohub")!) {
                            Label("View on GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                        }
                    } header: {
                        Text("About")
                    }
                    
                    // Sign out and account management
                    Section {
                        Link(destination: URL(string: "https://github.com/settings/connections/applications")!) {
                            Label("Manage GitHub Access", systemImage: "key")
                        }
                        
                        Button(role: .destructive) {
                            showingSignOutAlert = true
                        } label: {
                            HStack {
                                Spacer()
                                Text("Sign Out")
                                Spacer()
                            }
                        }
                    } header: {
                        Text("Account Management")
                    } footer: {
                        Text("To revoke TodoHub's access to your GitHub account, tap 'Manage GitHub Access' and remove TodoHub from your authorized applications.")
                    }
                    
                    // Footer
                    Section {
                        VStack(spacing: 4) {
                            Text("TodoHub")
                                .font(.headline)
                            Text("Made with ♥ by Martin Woodward")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                    }
                }
            .navigationTitle("Settings")
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    Task {
                        await authViewModel.signOut()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .sheet(isPresented: $showingRepoSelection) {
                RepoSelectionView()
                    .environmentObject(authViewModel)
            }
            .preferredColorScheme(appearance.colorScheme)
        }
    }
    
    private func openGitHubProfile() {
        if let login = authViewModel.currentUser?.login,
           let url = URL(string: "https://github.com/\(login)") {
            UIApplication.shared.open(url)
        }
    }
}

enum Appearance: String, CaseIterable {
    case system
    case light
    case dark
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthViewModel())
}
