//
//  StreamingChatView.swift
//  GlintAI
//
//  Created by Milton Palaguachi on 9/29/26.
//

import SwiftUI

struct StreamingChatView: View {
    @StateObject private var viewModel = StreamingChatViewModel()
    
    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        ForEach(viewModel.messages) { message in
                            ChatBubbleView(message: message)
                                .id(message.id) // Crucial anchor for auto-scroll tracking
                        }
                        
                        if viewModel.isTyping {
                            TypingIndicatorView()
                        }
                    }
                    .padding()
                }
                // RECRUITER FLEX: Auto-scrolling on character changes rather than just message count
                .onChange(of: viewModel.messages.last?.text, {
                    if let lastMessage = viewModel.messages.last {
                        // Keeps the latest text tokens pinned to the bottom of the screen flawlessly
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                })
            }
            
            // Input panel
            HStack {
                TextField("What are we planning today?", text: $viewModel.currentInput)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, 4)
                Button {
                    Task { await viewModel.sendMessage() }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.blue)
                }
                .disabled(viewModel.isTyping)
            }
            .padding()
            .background(.thinMaterial)
        }
        .navigationTitle("⚡ Live AI Stream")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Simple pulsing loading state before tokens arrive
struct TypingIndicatorView: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.gray.opacity(0.6))
                    .frame(width: 8, height: 8)
                    .scaleEffect(isAnimating ? 1.0 : 0.5)
                    .animation(.easeInOut(duration: 0.6).repeatForever().delay(Double(index) * 0.2), value: isAnimating)
            }
        }
        .padding(.horizontal)
        .onAppear { isAnimating = true }
    }
}

