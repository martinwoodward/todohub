//
//  TodoListView.swift
//  TodoHub
//
//  Copyright (c) 2025 Martin Woodward
//  Licensed under MIT License
//

import SwiftUI

struct TodoListView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var viewModel: TodoListViewModel
    @State private var showingSettings = false
    @State private var showingQuickAdd = false
    @FocusState private var isAddFieldFocused: Bool
    @Binding var submitTrigger: Bool
    @State private var inlineAddTitle = ""
    
    @State private var settingsOffset: CGFloat = -UIScreen.main.bounds.height
    
    var body: some View {
        ZStack(alignment: .top) {
            NavigationStack {
                ZStack(alignment: .bottom) {
                    Group {
                        if viewModel.isLoading && viewModel.todos.isEmpty {
                            ProgressView("Loading todos...")
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    hideKeyboard()
                                }
                        } else if viewModel.todos.isEmpty {
                            EmptyTodoView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    hideKeyboard()
                                }
                        } else {
                            todoList
                        }
                    }
                
                // Inline add view at bottom with background
                VStack(spacing: 0) {
                    Spacer()
                        .contentShape(Rectangle())
                        .onTapGesture {
                            hideKeyboard()
                        }
                    
                    // Gradient fade for content underneath
                    LinearGradient(
                        colors: [.clear, Color(.systemBackground).opacity(0.8), Color(.systemBackground)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 40)
                    .allowsHitTesting(false)
                    
                    // Solid background behind controls
                    VStack(spacing: 0) {
                        InlineAddView(
                            viewModel: viewModel,
                            isFocused: $isAddFieldFocused,
                            title: $inlineAddTitle,
                            onExpandTapped: { showingQuickAdd = true }
                        )
                        .padding(.horizontal, 12)
                        .padding(.bottom, 80) // Add extra padding to keep it above the toolbar
                    }
                    .background(Color(.systemBackground))
                }
            }
            .navigationTitle(Config.defaultProjectName)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(Config.defaultProjectName)
                        .font(.headline)
                        .onTapGesture {
                            hideKeyboard()
                        }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { 
                        withAnimation(.spring(duration: 0.4)) {
                            showingSettings = true
                        }
                    }) {
                        AvatarView(login: authViewModel.currentUser?.login)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .refreshable {
                await viewModel.refresh()
            }
            .sheet(isPresented: $showingQuickAdd) {
                QuickAddView(viewModel: viewModel, title: $inlineAddTitle)
            }
            .onChange(of: submitTrigger) { _, _ in
                submitInlineAdd()
            }
            .task {
                await viewModel.loadTodos()
            }
        }
        
        // Settings overlay from top
        if showingSettings {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(duration: 0.4)) {
                        showingSettings = false
                    }
                }
            
            SettingsDropdownView(isPresented: $showingSettings)
                .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}
    
    private func hideKeyboard() {
        isAddFieldFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private var todoList: some View {
        List {
            ForEach(viewModel.todos.filter { !$0.isCompleted }) { todo in
                TodoRowView(todo: todo, viewModel: viewModel)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
            .onMove { from, to in
                Task {
                    await viewModel.moveTodo(from: from, to: to)
                }
            }
            
            // Spacer to prevent list content from being hidden by inline add view
            Color.clear
                .frame(height: 80)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .scrollDismissesKeyboard(.immediately)
        .animation(.spring(duration: 0.4), value: viewModel.todos)
    }
    
    private func submitInlineAdd() {
        let trimmedTitle = inlineAddTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        
        viewModel.createTodo(
            title: trimmedTitle,
            dueDate: nil,
            priority: .none
        )
        
        // Reset form
        inlineAddTitle = ""
        
        // Keep keyboard open for rapid entry
        isAddFieldFocused = true
    }
}

struct EmptyTodoView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 64))
                .foregroundStyle(.green.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("All caught up!")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Type below to add your first todo")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct SettingsDropdownView: View {
    @Binding var isPresented: Bool
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 0) {
            SettingsView()
                .frame(maxHeight: UIScreen.main.bounds.height * 0.7)
            
            // Bottom drag indicator bar
            Capsule()
                .fill(Color(.systemGray3))
                .frame(width: 36, height: 5)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Color(.systemGroupedBackground))
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        .offset(y: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.height < 0 {
                        dragOffset = value.translation.height
                    }
                }
                .onEnded { value in
                    if value.translation.height < -100 {
                        withAnimation(.spring(duration: 0.4)) {
                            isPresented = false
                        }
                    } else {
                        withAnimation(.spring(duration: 0.3)) {
                            dragOffset = 0
                        }
                    }
                }
        )
        .padding(.horizontal, 8)
        .ignoresSafeArea(edges: .top)
    }
}

#Preview {
    @Previewable @State var submitTrigger = false
    TodoListView(submitTrigger: $submitTrigger)
        .environmentObject(AuthViewModel())
        .environmentObject(TodoListViewModel())
}
