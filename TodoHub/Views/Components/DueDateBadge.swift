//
//  DueDateBadge.swift
//  TodoHub
//
//  Copyright (c) 2025 Martin Woodward
//  Licensed under MIT License
//

import SwiftUI

struct DueDateBadge: View {
    let date: Date
    let isOverdue: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "calendar")
                .font(.caption2)
            Text(formattedDate)
                .font(.caption)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(backgroundColor.opacity(0.15))
        .foregroundStyle(foregroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
    
    private var formattedDate: String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInTomorrow(date) {
            return "Tomorrow"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
    
    private var backgroundColor: Color {
        if isOverdue {
            return .red
        } else if Calendar.current.isDateInToday(date) {
            return .orange
        } else {
            return .blue
        }
    }
    
    private var foregroundColor: Color {
        if isOverdue {
            return .red
        } else if Calendar.current.isDateInToday(date) {
            return .orange
        } else {
            return .blue
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        DueDateBadge(date: Date(), isOverdue: false)
        DueDateBadge(date: Calendar.current.date(byAdding: .day, value: 1, to: Date())!, isOverdue: false)
        DueDateBadge(date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, isOverdue: true)
        DueDateBadge(date: Calendar.current.date(byAdding: .day, value: 5, to: Date())!, isOverdue: false)
    }
    .padding()
}
