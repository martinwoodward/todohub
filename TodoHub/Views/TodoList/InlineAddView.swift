//
//  InlineAddView.swift
//  TodoHub
//
//  Copyright (c) 2025 Martin Woodward
//  Licensed under MIT License
//

import SwiftUI
import Speech
import AVFoundation

struct InlineAddView: View {
    @ObservedObject var viewModel: TodoListViewModel
    var isFocused: FocusState<Bool>.Binding
    
    @State private var title = ""
    @State private var isExpanded = false
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
    
    var body: some View {
        VStack(spacing: 0) {
            // Main input row
            HStack(alignment: .bottom, spacing: 12) {
                // Text field
                TextEditor(text: $title)
                    .font(.body)
                    .frame(minHeight: 20, maxHeight: 80)
                    .fixedSize(horizontal: false, vertical: true)
                    .focused(isFocused)
                    .scrollContentBackground(.hidden)
                    .overlay(alignment: .topLeading) {
                        if title.isEmpty {
                            Text("Add a todo...")
                                .font(.body)
                                .foregroundStyle(.tertiary)
                                .allowsHitTesting(false)
                        }
                    }
                
                // Microphone button for voice dictation
                Button(action: toggleRecording) {
                    Image(systemName: isRecording ? "mic.fill" : "mic")
                        .font(.body)
                        .foregroundStyle(isRecording ? .blue : .secondary)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                
                // Expand/collapse button
                Button(action: { 
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                
                // Submit button
                Button(action: submit) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(canSubmit ? .green : Color(.systemGray4))
                }
                .buttonStyle(.plain)
                .disabled(!canSubmit)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Expanded options
            if isExpanded {
                Divider()
                    .padding(.horizontal, 16)
                
                HStack(spacing: 12) {
                    // Due date button
                    Button(action: { showDatePicker.toggle() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption)
                            if let date = dueDate {
                                Text(date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                
                                // Clear button
                                Button(action: { dueDate = nil }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            } else {
                                Text("Date")
                                    .font(.caption)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(dueDate != nil ? Color.blue.opacity(0.15) : Color(.systemGray5))
                        .foregroundStyle(dueDate != nil ? .blue : .primary)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    
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
                        HStack(spacing: 4) {
                            Image(systemName: priority.icon)
                                .font(.caption)
                            Text(priority.rawValue)
                                .font(.caption)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(priority != .none ? priority.color.opacity(0.15) : Color(.systemGray5))
                        .foregroundStyle(priority != .none ? priority.color : .primary)
                        .clipShape(Capsule())
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                
                // Date picker (if showing)
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
                    .padding(.horizontal, 16)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: -2)
        .animation(.easeInOut(duration: 0.2), value: showDatePicker)
        .alert("Voice Recognition Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var canSubmit: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func submit() {
        guard canSubmit else { return }
        
        viewModel.createTodo(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            dueDate: dueDate,
            priority: priority
        )
        
        // Reset form
        title = ""
        dueDate = nil
        priority = .none
        showDatePicker = false
        
        // Optionally collapse after submit
        if isExpanded {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded = false
            }
        }
        
        // Keep keyboard open for rapid entry
        isFocused.wrappedValue = true
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
    @Previewable @FocusState var focused: Bool
    VStack {
        Spacer()
        InlineAddView(viewModel: TodoListViewModel(), isFocused: $focused)
            .padding()
    }
}
