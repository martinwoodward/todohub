//
//  CustomTabBar.swift
//  TodoHub
//
//  Copyright (c) 2025 Martin Woodward
//  Licensed under MIT License
//

import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    let onAddTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Gradient fade for content underneath
            LinearGradient(
                colors: [.clear, Color(.systemBackground).opacity(0.8), Color(.systemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 20)
            .allowsHitTesting(false)
            
            HStack(spacing: 12) {
                // Main tab bar with glass effect
                HStack(spacing: 0) {
                    TabBarButton(
                        icon: "house.fill",
                        title: "Home",
                        isSelected: selectedTab == 0
                    ) {
                        selectedTab = 0
                    }
                    
                    TabBarButton(
                        icon: "tray.fill",
                        title: "All Issues",
                        isSelected: selectedTab == 1
                    ) {
                        selectedTab = 1
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
                
                // Add button with glass effect
                Button(action: onAddTapped) {
                    Image(systemName: "plus")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Circle()
                                        .fill(Color.blue.opacity(0.8))
                                )
                        )
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 2)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            .background(Color(.systemBackground))
        }
    }
}

struct TabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .frame(height: 24)
                
                Text(title)
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .foregroundStyle(isSelected ? .blue : .secondary)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack {
        Spacer()
        CustomTabBar(selectedTab: .constant(0), onAddTapped: {})
    }
}
