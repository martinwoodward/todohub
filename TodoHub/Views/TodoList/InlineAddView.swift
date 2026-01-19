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
import AudioToolbox

struct InlineAddView: View {
    @ObservedObject var viewModel: TodoListViewModel
    var isFocused: FocusState<Bool>.Binding
    @Binding var title: String
    let onExpandTapped: () -> Void
    
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
                            .padding(.leading, 5)
                            .padding(.top, 8)
                            .allowsHitTesting(false)
                    }
                }
            
            // Expand button - opens detailed view
            Button(action: onExpandTapped) {
                Image(systemName: "chevron.up")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            
            // Microphone button for voice dictation
            Button(action: toggleRecording) {
                Image(systemName: isRecording ? "mic.fill" : "mic")
                    .font(.body)
                    .foregroundStyle(isRecording ? .blue : .secondary)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: -2)
        .alert("Voice Recognition Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
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
        
        // Play start sound (system "begin recording" sound)
        AudioServicesPlaySystemSound(1113)
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
        
        // Play stop sound (system "end recording" sound)
        AudioServicesPlaySystemSound(1114)
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        // End audio gracefully
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask = nil
        
        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        
        isRecording = false
    }
}

#Preview {
    @Previewable @FocusState var focused: Bool
    @Previewable @State var title = ""
    VStack {
        Spacer()
        InlineAddView(viewModel: TodoListViewModel(), isFocused: $focused, title: $title, onExpandTapped: {})
            .padding()
    }
}
