//
//  StreamingChatViewModel.swift
//  GlintAI
//
//  Created by Milton Palaguachi on 9/29/26.
//
import FoundationModels
import Combine
import SwiftUI

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let isUser: Bool
    var text: String // Marked as var so we can append streamed tokens smoothly
    var items: [Product] = []
}

@MainActor
class StreamingChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var currentInput: String = ""
    @Published var isTyping: Bool = false
    @Published var autonomousAgent: Bool = false {
        didSet {
            if autonomousAgent != oldValue {
                updateAgent()
            }
        }
    }

    private var agent: ShoppingAgentServices? = AutonomousShoppingAgent()
    private var temporarySessionItems: [Product] = []
    private var activeTask: Task<Void, Never>?

    func handleSend() {
        activeTask?.cancel()
        activeTask = Task {
            await sendMessage()
        }
    }

    func updateAgent() {
        if autonomousAgent {
            agent = AutonomousShoppingAgent()
        } else {
            agent = StreamingShoppingAgent()
        }
    }

    private func sendMessage() async {
        let trimmedInput = currentInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else { return }
        let userText = trimmedInput
        
        // 1. Post user message and reset input bar
        messages.append(ChatMessage(isUser: true, text: userText))
        currentInput = ""
        isTyping = true
        temporarySessionItems = []

        // 2. Initialize a blank placeholder message block for the AI's response
        let aiMessageIndex = messages.count
        messages.append(ChatMessage(isUser: false, text: ""))
        
        guard let agent else {
            messages[aiMessageIndex].text = "Error: Agent not initialized."
            isTyping = false
            return
        }
        Task { [weak self] in
            guard let self else { return }
            await listenRecomendedItems(index: aiMessageIndex)
        }

        do {
            // 3. RECIPY FOR SUCCESS: Use Apple's streaming API wrapper
            // Note: If using the beta/released API, verify if the stream endpoint is named `streamResponse` or `generateTokens`
            let responseStream = agent.processRequest(userText)// session.streamResponse(to: userText)
            
            isTyping = false // Turn off global loading spinner since words are arriving
            
            // 4. Concurrently consume the asynchronous token sequence
            for try await token in responseStream {
                // Safely update the placeholder message block text line on the main thread
                try Task.checkCancellation()
                messages[aiMessageIndex].text = token
            }

            // 5. Once the stream ends, inject any structured product cards collected by our tools
            if !temporarySessionItems.isEmpty {
                messages[aiMessageIndex].items = temporarySessionItems
            }

        } catch is CancellationError {
            // Task cancelled by user or subsequent message; clear or mark canceled
            messages[aiMessageIndex].text = "[Canceled]"
        } catch LanguageModelSession.GenerationError.assetsUnavailable{
            messages[aiMessageIndex].text = "❌ Apple Intelligence model assets are downloading or unavailable. Please ensure Apple Intelligence is active in Settings and your device has enough storage."
            isTyping = false
        } catch {
            messages[aiMessageIndex].text = "Error streaming on-device engine: \(error.localizedDescription)"
            isTyping = false
        }
        dump(messages)
    }

    private func listenRecomendedItems(index: Int) async {
        guard let agent else { return }
        for await products in agent.catalogStream {
            temporarySessionItems.append(contentsOf: products)
            messages[index].items = temporarySessionItems
        }
    }
}
