//
//  Color+Theme.swift
//  TodoHub
//
//  Copyright (c) 2025 Martin Woodward
//  Licensed under MIT License
//

import SwiftUI

extension Color {
    // Brand colors
    static let todoGreen = Color("TodoGreen", bundle: nil)
    static let todoBrand = Color.green
    
    // Semantic colors
    static let todoBackground = Color(.systemBackground)
    static let todoSecondaryBackground = Color(.secondarySystemBackground)
    static let todoGroupedBackground = Color(.systemGroupedBackground)
    
    // Priority colors
    static let priorityHigh = Color.red
    static let priorityMedium = Color.orange
    static let priorityLow = Color.blue
    static let priorityNone = Color.gray
}

extension ShapeStyle where Self == Color {
    static var todoAccent: Color { .green }
}
