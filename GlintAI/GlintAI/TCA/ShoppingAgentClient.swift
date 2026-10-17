//
//  ShoppingAgentClient.swift
//  GlintAI
//
//  Created by Milton Palaguachi on 10/17/26.
//

import ComposableArchitecture
import Foundation

@DependencyClient
struct ShoppingAgentClient: Sendable {
    // Exposes the live LLM token stream for a prompt
    var prcessRequest: @Sendable (_ pront: String) -> AsyncThrowingStream<String, Error> = { _ in .finished() }
    // Exposes the underlying product catalog stream
    var catalogStream: @Sendable () -> AsyncStream<[Product]> = { .finished }
}
// Let's register our actual StreamingShoppingAget logic within the DependecyKey Layer
// This keeps the implementation swappable for previews and unit tests:
extension ShoppingAgentClient: DependencyKey {
    static let liveValue: ShoppingAgentClient = {
        // Instantiate your core agent machinery
        let agent = StreamingShoppingAgent()
        return ShoppingAgentClient(prcessRequest: { prompt in
            agent.processRequest(prompt)
        }, catalogStream: {
            agent.catalogStream
        })
    }()

    // Crucial for SwiftUI prviews or testing without making live LLM calls
    static let previewValue = ShoppingAgentClient(
        prcessRequest: { pront in
            AsyncThrowingStream{ continuation in
                continuation.yield("Hi")
                continuation.yield("I found some ")
                continuation.yield("great items for you.")
                continuation.finish()
            }
        },
        catalogStream: {
            AsyncStream { continuation in
                continuation.yield(
                    [Product(
                        id: "1",
                        name: "Potatos",
                        category: "Grocery",
                        price: 2.99,
                        quantity: 1,
                        description: "5 LB Potatos ",
                        discount: "25 %")
                    ]
                )
                continuation.finish()
            }
        }
    )
}

extension DependencyValues {
    var shoppingAgent: ShoppingAgentClient {
        get { self[ShoppingAgentClient.self] }
        set { self[ShoppingAgentClient.self] = newValue }
    }
}
