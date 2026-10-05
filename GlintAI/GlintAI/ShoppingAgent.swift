//
//  ShoppingAgent.swift
//  GlintAI
//
//  Created by Milton Palaguachi on 10/4/26.
//

import Foundation
import FoundationModels

struct ShoppingAgent {
    let searchTool = StoreCatalogTool()
    let priceTool: PriceCheckTool

    private let session = LanguageModelSession(
        model: .default,
        instructions: "You are Sparky, an AI shopping helper. Keep responses short and conversational."
    )

    func executeWorkFlow(query: String) async throws -> sending LanguageModelSession.ResponseStream<String> {
        // Step 1: Execute Tool A
        let searchArgs = StoreSearchArguments(searchQuery: query)
        let itemsIDs = try await searchTool.call(arguments: searchArgs)

        guard !itemsIDs.isEmpty else {
            return session.streamResponse(
                to: "Inform the user clearly that no items were found matching '\(query)' in the store catalog."
            )
        }

        // Step 2: Feed Output directly into Tool B Input
        let priceArgs = PriceCheckArgs(itemIDs: itemsIDs)
        let rawProductJSON = try await priceTool.call(arguments: priceArgs)

        // Step 3: Construct prompt with pipeline context
        let promptWithContext = """
            User Request: \(query)
                
            Context Data (Retrieved from Catalog & Pricing):
            \(rawProductJSON)

        Construct responses short and conversational with item details.
        """
        return session.streamResponse(to: promptWithContext)
    }
}
