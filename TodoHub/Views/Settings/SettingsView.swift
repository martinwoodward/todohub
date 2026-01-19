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
                    
                    // About section
                    Section {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("1.0.0")
                                .foregroundStyle(.secondary)
                        }
                        
                        Link("View on GitHub", destination: URL(string: "https://github.com/martinwoodward/todohub")!)
                        
                        Link("Report an Issue", destination: URL(string: "https://github.com/martinwoodward/todohub/issues/new")!)
                    } header: {
                        Text("About")
                    }
                    
                    // Sign out
                    Section {
                        Button(role: .destructive) {
                            showingSignOutAlert = true
                        } label: {
                            HStack {
                                Spacer()
                                Text("Sign Out")
                                Spacer()
                            }
                        }
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
