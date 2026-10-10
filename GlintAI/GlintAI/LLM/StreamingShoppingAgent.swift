//
//  ShoppingAgent.swift
//  GlintAI
//
//  Created by Milton Palaguachi on 10/4/26.
//

import Foundation
import FoundationModels

class StreamingShoppingAgent: ShoppingAgentServices {
    private let searchTool: StoreCatalogTool
    private var priceTool: PriceCheckTool
    let catalogStream: AsyncStream<[Product]>

    init() {
        self.searchTool = StoreCatalogTool()
        let (stream, continuation) = AsyncStream<[Product]>.makeStream()
        self.priceTool = PriceCheckTool(catalogContinuation: continuation)
        self.catalogStream = stream
    }

    private let session = LanguageModelSession(
        model: .default,
        instructions: "You are Sparky, an AI shopping helper. Keep responses short and conversational."
    )

    func processRequest(_ pront: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task{
                do {
                    // Step 1: Execute Tool A
                    let searchArgs = StoreSearchArguments(searchQuery: pront)
                    let itemsIDs = try await searchTool.call(arguments: searchArgs)

                    guard !itemsIDs.isEmpty else {
                        continuation.yield("No items match your query for \(pront)")
                        continuation.finish()
                        return
                    }
                    
                    // Step 2: Feed Output directly into Tool B Input
                    let priceArgs = PriceCheckArgs(itemIDs: itemsIDs)
                    let rawProductJSON = try await priceTool.call(arguments: priceArgs)

                    // Step 3: Construct prompt with pipeline context
                    let promptWithContext = """
                        User Request: \(pront)
                            
                        Context Data (Retrieved from Catalog & Pricing):
                        \(rawProductJSON)

                    Construct responses short and conversational with item details.
                    """
                    let modelStream = session.streamResponse(to: promptWithContext)

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
