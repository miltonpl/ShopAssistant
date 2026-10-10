//
//  AutonomousShoppingAgent.swift
//  GlintAI
//
//  Created by Milton Palaguachi on 10/8/26.
//

import Foundation
import FoundationModels

protocol ShoppingAgentServices {
    /// A steam that emits groups of products as they are found during a request.
    var catalogStream: AsyncStream<[Product]> { get }

    /// Process the incomeing prompt and stream back the text responses.
    func processRequest(_ pront: String) -> AsyncThrowingStream<String, Error>
}

class AutonomousShoppingAgent: ShoppingAgentServices {
    private let session: LanguageModelSession
    let catalogStream: AsyncStream<[Product]>

    init() {
        // 1. Uncouple the stream from its internal structural producer
        let (stream, continuation) = AsyncStream<[Product]>.makeStream()
        self.catalogStream = stream
        // 2. Pass the continuation directly to your stateless struct tool.
        var priceCheckTool = PriceCheckTool(catalogContinuation: continuation)
        // 3. Register your tools within your multi-turn language session
        self.session = LanguageModelSession(
            model: .default,
            tools: [StoreCatalogTool(), priceCheckTool]
        )
    }

    func processRequest(_ pront: String) -> AsyncThrowingStream<String, Error> {
        // The model automatically decides the step order:
        // Turn 1: Calls `search_inventory(keyword: "party")` -> receives ["SKU-101", "SKU-204"]
        // Turn 2: Sees product IDs, calls `check_prices(itemIDs: ["SKU-101", "SKU-204"])`
        // Turn 3: Synthesizes final user-facing recommendation based on prices
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let modelStream = session.streamResponse(to: pront)
                    for try await fragment in modelStream {
                        continuation.yield(fragment.content)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
