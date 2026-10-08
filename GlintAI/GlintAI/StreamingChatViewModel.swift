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

    private var agent: AutonomousShoppingAgent?//ShoppingAgent?
    private var temporarySessionItems: [Product] = []

    init() {
        setupShoppingAgen()
    }

    private func setupShoppingAgen() {
        // Tie into our local search catalog tool from the previous step
//        let priceCheckTool = PriceCheckTool { [weak self] products in
//            // Safely hop back to the Main Actor asynchronously
//            Task { @MainActor [weak self] in
//                self?.temporarySessionItems.append(contentsOf: products)
//            }
//        }
        agent = AutonomousShoppingAgent()
        agent?.onCatalogFound = { products in
            // Safely hop back to the Main Actor asynchronously
            Task { @MainActor [weak self] in
                self?.temporarySessionItems.append(contentsOf: products)
            }
        }
//        agent = ShoppingAgent(priceTool: priceCheckTool)
    }

    func sendMessage() async {
        guard !currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let userText = currentInput
        
        // 1. Post user message and reset input bar
        messages.append(ChatMessage(isUser: true, text: userText))
        currentInput = ""
        isTyping = true
        temporarySessionItems = []

        // 2. Initialize a blank placeholder message block for the AI's response
        let aiMessageIndex = messages.count
        messages.append(ChatMessage(isUser: false, text: ""))
        
        guard let agent else {
            isTyping = false
            return
        }

        do {
            // 3. RECIPY FOR SUCCESS: Use Apple's streaming API wrapper
            // Note: If using the beta/released API, verify if the stream endpoint is named `streamResponse` or `generateTokens`
            let responseStream = try await agent.processRequest(userText)// session.streamResponse(to: userText)
            
            isTyping = false // Turn off global loading spinner since words are arriving
            
            // 4. Concurrently consume the asynchronous token sequence
            for try await token in responseStream {
                // Safely update the placeholder message block text line on the main thread
                messages[aiMessageIndex].text = token.content
            }

            // 5. Once the stream ends, inject any structured product cards collected by our tools
            if !temporarySessionItems.isEmpty {
                messages[aiMessageIndex].items = temporarySessionItems
            }

        } catch LanguageModelSession.GenerationError.assetsUnavailable{
            messages[aiMessageIndex].text = "❌ Apple Intelligence model assets are downloading or unavailable. Please ensure Apple Intelligence is active in Settings and your device has enough storage."
            isTyping = false
        } catch {
            messages[aiMessageIndex].text = "Error streaming on-device engine: \(error.localizedDescription)"
            isTyping = false
        }
        dump(messages)
    }
}
