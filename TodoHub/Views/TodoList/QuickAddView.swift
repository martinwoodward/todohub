//
//  QuickAddView.swift
//  TodoHub
//
//  Copyright (c) 2025 Martin Woodward
//  Licensed under MIT License
//

import SwiftUI
import Speech
import AVFoundation

struct QuickAddView: View {
    @ObservedObject var viewModel: TodoListViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var dueDate: Date?
    @State private var priority: Priority = .none
    @State private var showDatePicker = false
    @State private var isRecording = false
    @State private var speechRecognizer = SFSpeechRecognizer(locale: Locale.current)
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    @State private var audioEngine = AVAudioEngine()
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var silenceTimer: Timer?
    @State private var hasReceivedSpeech = false
    @State private var isStoppingIntentionally = false
    
    @FocusState private var isTitleFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Title input with microphone
                HStack(alignment: .bottom, spacing: 12) {
                    TextEditor(text: $title)
                        .font(.title3)
                        .frame(minHeight: 24, maxHeight: 100)
                        .fixedSize(horizontal: false, vertical: true)
                        .focused($isTitleFocused)
                        .scrollContentBackground(.hidden)
                        .overlay(alignment: .topLeading) {
                            if title.isEmpty {
                                Text("What do you need to do?")
                                    .font(.title3)
                                    .foregroundStyle(.tertiary)
                                    .allowsHitTesting(false)
                            }
                        }
                    
                    // Microphone button for voice dictation
                    Button(action: toggleRecording) {
                        Image(systemName: isRecording ? "mic.fill" : "mic")
                            .font(.title2)
                            .foregroundStyle(isRecording ? .blue : .secondary)
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.plain)
                }
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
                    .disabled(!canSubmit)
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
            .alert("Voice Recognition Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    private var canSubmit: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func submit() {
        guard canSubmit else { return }
        
        // Create todo optimistically (no async needed)
        viewModel.createTodo(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            dueDate: dueDate,
            priority: priority
        )
        
        // Dismiss immediately - creation happens in background
        dismiss()
    }
    
    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        // Check if speech recognizer is available
        guard speechRecognizer != nil else {
            errorMessage = "Speech recognition is not available for your language."
            showErrorAlert = true
            return
        }
        
        // Request speech recognition authorization
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    do {
                        try self.startSpeechRecognition()
                    } catch {
                        self.errorMessage = "Failed to start recording: \(error.localizedDescription)"
                        self.showErrorAlert = true
                    }
                case .denied:
                    self.errorMessage = "Speech recognition access was denied. Please enable it in Settings."
                    self.showErrorAlert = true
                case .restricted:
                    self.errorMessage = "Speech recognition is restricted on this device."
                    self.showErrorAlert = true
                case .notDetermined:
                    self.errorMessage = "Speech recognition permission not determined."
                    self.showErrorAlert = true
                @unknown default:
                    self.errorMessage = "Unknown speech recognition error."
                    self.showErrorAlert = true
                }
            }
        }
    }
    
    private func startSpeechRecognition() throws {
        // Cancel any ongoing task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true
        
        // Get the input node
        let inputNode = audioEngine.inputNode
        
        // Create recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                DispatchQueue.main.async {
                    self.hasReceivedSpeech = true
                    self.title = result.bestTranscription.formattedString
                    self.resetSilenceTimer()
                }
            }
            
            if let error = error {
                // Quietly stop if intentionally stopping or no speech was received
                if self.isStoppingIntentionally || !self.hasReceivedSpeech {
                    self.stopRecording()
                    return
                }
                DispatchQueue.main.async {
                    self.errorMessage = "Voice recognition error: \(error.localizedDescription)"
                    self.showErrorAlert = true
                }
                self.stopRecording()
            } else if result?.isFinal == true {
                self.stopRecording()
            }
        }
        
        // Configure the microphone input
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        isRecording = true
        hasReceivedSpeech = false
        isStoppingIntentionally = false
        resetSilenceTimer()
    }
    
    private func resetSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
            DispatchQueue.main.async {
                self.isStoppingIntentionally = true
                self.stopRecording()
            }
        }
    }
    
    private func stopRecording() {
        silenceTimer?.invalidate()
        silenceTimer = nil
        
        guard isRecording else { return }
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        // End audio gracefully - don't cancel the task so transcription finalizes
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        // Don't cancel the task - let it finalize and keep the transcribed text
        // The task will complete naturally after endAudio()
        recognitionTask = nil
        
        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        
        isRecording = false
    }
}

#Preview {
    QuickAddView(viewModel: TodoListViewModel())
}
