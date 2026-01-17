//
//  LoginView.swift
//  TodoHub
//
//  Copyright (c) 2025 Martin Woodward
//  Licensed under MIT License
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(.systemBackground), Color(.systemGray6)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Logo and title
                VStack(spacing: 16) {
                    Image("AppIcon")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                    
                    Text("TodoHub")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Your todos, backed by GitHub.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Sign in button
                VStack(spacing: 24) {
                    Button(action: {
                        authViewModel.signIn()
                    }) {
                        HStack(spacing: 12) {
                            Image("GitHubIcon")
                                .renderingMode(.template)
                                .resizable()
                                .frame(width: 24, height: 24)
                            Text("Sign in with GitHub")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(.label))
                        .foregroundColor(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(authViewModel.isLoading)
                    
                    if authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                }
                .padding(.horizontal, 32)
                
                // Features list
                VStack(spacing: 12) {
                    FeatureRow(icon: "lock.fill", text: "Secure OAuth Login")
                    FeatureRow(icon: "iphone", text: "Works with any repo")
                    FeatureRow(icon: "arrow.triangle.2.circlepath", text: "Syncs automatically")
                }
                .padding(.top, 24)
                
                Spacer()
            }
        }
        .alert("Sign In Error", isPresented: .constant(authViewModel.error != nil)) {
            Button("OK") {
                authViewModel.clearError()
            }
        } message: {
            if let error = authViewModel.error {
                Text(error.localizedDescription)
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.green)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 48)
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}
