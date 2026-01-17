//
//  QuickAddView.swift
//  TodoHub
//
//  Copyright (c) 2025 Martin Woodward
//  Licensed under MIT License
//

import SwiftUI

struct QuickAddView: View {
    @ObservedObject var viewModel: TodoListViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var dueDate: Date?
    @State private var priority: Priority = .none
    @State private var showDatePicker = false
    @State private var isSubmitting = false
    
    @FocusState private var isTitleFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Title input
                TextField("What do you need to do?", text: $title, axis: .vertical)
                    .font(.title3)
                    .lineLimit(3...6)
                    .focused($isTitleFocused)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Quick options
                HStack(spacing: 12) {
                    // Due date button
                    Button(action: { showDatePicker.toggle() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                            if let date = dueDate {
                                Text(date.formatted(date: .abbreviated, time: .omitted))
                            } else {
                                Text("Date")
                            }
                        }
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(dueDate != nil ? Color.blue.opacity(0.15) : Color(.systemGray5))
                        .foregroundStyle(dueDate != nil ? .blue : .primary)
                        .clipShape(Capsule())
                    }
                    
                    // Priority menu
                    Menu {
                        ForEach(Priority.allCases, id: \.self) { p in
                            Button(action: { priority = p }) {
                                HStack {
                                    Text(p.rawValue)
                                    if priority == p {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: priority.icon)
                            Text(priority.rawValue)
                        }
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(priority != .none ? priority.color.opacity(0.15) : Color(.systemGray5))
                        .foregroundStyle(priority != .none ? priority.color : .primary)
                        .clipShape(Capsule())
                    }
                    
                    Spacer()
                    
                    // Submit button
                    Button(action: submit) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title)
                            .foregroundStyle(canSubmit ? .green : .gray)
                    }
                    .disabled(!canSubmit || isSubmitting)
                }
                
                // Date picker (expandable)
                if showDatePicker {
                    DatePicker(
                        "Due Date",
                        selection: Binding(
                            get: { dueDate ?? Date() },
                            set: { dueDate = $0 }
                        ),
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("New Todo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                isTitleFocused = true
            }
            .animation(.easeInOut, value: showDatePicker)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    private var canSubmit: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func submit() {
        guard canSubmit else { return }
        
        isSubmitting = true
        
        Task {
            await viewModel.createTodo(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                dueDate: dueDate,
                priority: priority
            )
            dismiss()
        }
    }
}

#Preview {
    QuickAddView(viewModel: TodoListViewModel())
}
