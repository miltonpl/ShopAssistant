//
//  ChatAgentFeature.swift
//  GlintAI
//
//  Created by Milton Palaguachi on 10/17/26.
//

import ComposableArchitecture
import Foundation
// The macro automatically regerates the conformance.
// Do NOT add ": Reducer" or an extension implementing Reducer her.

@Reducer
struct ChatAgentFeature {
    @ObservableState
    struct State: Equatable {
        var currentInput = ""
        var coversationText = ""
        var discoveredProducts: [Product] = []
        var isStreaming = false
    }
    
    enum Action {
        case task                       // Trigger when view appears to start background
        case catalogUpdated([Product])  // Trigger when tools discover new products
        case inputChanged(String)
        case sendButtonTapped
        case textTokenReceived(String)   // Handle incremental text updates from LLM
        case streamFinished(Result<Void,Error>)
    }
    
    @Dependency(\.shoppingAgent) var shoppingAgent
    var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .task:
                // 1. Hook up the long-lived side channel stream for catalog items discovered by the agent tools
                let fetchStream = shoppingAgent.catalogStream
                return .run { send in
                    for await products in fetchStream() {
                        await send(.catalogUpdated(products))
                    }
                }
            case let .catalogUpdated(products):
                dump(products)
                state.discoveredProducts.append(contentsOf: products)
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
                state.coversationText += "\nUser: \(prompt)\n Sparky: "
                // 2. Consume the shot-live LLM token stream within a .run loop
                let excutableRequest = shoppingAgent.prcessRequest
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
                state.coversationText += token
                return .none
            case .streamFinished(.success):
                state.isStreaming = false
                return .none
            case let .streamFinished(.failure(error)):
                state.isStreaming = false
                state.coversationText += "\n[Error: \(error.localizedDescription)]"
                return .none
            }
        }
    }
}
