//
//  PriorityBadge.swift
//  TodoHub
//
//  Copyright (c) 2025 Martin Woodward
//  Licensed under MIT License
//

import SwiftUI

struct PriorityBadge: View {
    let priority: Priority
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: priority.icon)
                .font(.caption2)
            Text(priority.rawValue)
                .font(.caption)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(priority.color.opacity(0.15))
        .foregroundStyle(priority.color)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

#Preview {
    VStack(spacing: 12) {
        PriorityBadge(priority: .high)
        PriorityBadge(priority: .medium)
        PriorityBadge(priority: .low)
        PriorityBadge(priority: .none)
    }
    .padding()
}
