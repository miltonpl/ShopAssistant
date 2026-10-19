//
//  ChatAgentFeature.swift
//  GlintAI
//
//  Created by Milton Palaguachi on 10/17/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct ChatAgentFeature {
    @ObservableState
    struct State: Equatable {
        var currentInput = ""
        var coversationText = ""
        var discoveredProducts: [Product] = []
        var pendingProducts: [Product] = [] // 1. Silent buffer for products arriving during a run
        var isStreaming = false
    }
    
    enum Action {
        case task                       // Runs once on appearance to listen to products
        case catalogUpdated([Product])  // Fires whenever the agent discovers products
        case inputChanged(String)
        case sendButtonTapped
        case textTokenReceived(String)   // Handle incremental text updates from LLM
        case streamFinished(Result<Void, Error>)
    }
    
    @Dependency(\.shoppingAgent) var shoppingAgent

    var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .task:
                // 2. Long-lived background listener for catalog items
                let fetchStream = shoppingAgent.catalogStream
                return .run { send in
                    for await products in fetchStream() {
                        await send(.catalogUpdated(products))
                    }
                }
                
            case let .catalogUpdated(products):
                // 3. Silently buffer products as they are found by tools
                state.pendingProducts.append(contentsOf: products)
                return .none
            case let .inputChanged(input):
                state.currentInput = input
                return .none
            case .sendButtonTapped:
                guard !state.currentInput.isEmpty else {
                    return .none
                }
                let prompt = state.currentInput
                state.currentInput = ""
                state.isStreaming = true
                state.coversationText = "\nUser: \(prompt)\n Sparky: "

                // Clear out pending products from the previous turn so we only show new ones
                state.pendingProducts.removeAll()

                // 2. Consume the shot-live LLM token stream within a .run loop
                let excutableRequest = shoppingAgent.processRequest
    
                return .run { send in
                    do {
                        let tokenStream = excutableRequest(prompt)
                        for try await token in tokenStream {
                            await send(.textTokenReceived(token))
                        }
                        await send(.streamFinished(.success(())))
                    } catch {
                        await send(.streamFinished(.failure(error)))
                    }
                }
            case let .textTokenReceived(token):
                state.coversationText = token
                return .none
            case .streamFinished(.success):
                state.isStreaming = false

                // 4. 🔥 FLUSH THE BUFFER: Release all products collected during this turn to the UI!
                state.discoveredProducts = state.pendingProducts
                state.pendingProducts.removeAll()
                return .none
            case let .streamFinished(.failure(error)):
                state.isStreaming = false
                state.pendingProducts.removeAll()
                state.coversationText = "\n[Error: \(error.localizedDescription)]"
                return .none
            }
        }
    }
}
