//
//  AutonomousShoppingAgent.swift
//  GlintAI
//
//  Created by Milton Palaguachi on 10/8/26.
//

import Foundation
import FoundationModels

class AutonomousShoppingAgent {
    private let session: LanguageModelSession
    var onCatalogFound: (@Sendable([Product]) -> Void)?

    init() {
        var priceCheckTool = PriceCheckTool()
        self.session = LanguageModelSession(
            model: .default,
            tools: [StoreCatalogTool(), priceCheckTool]
        )
        priceCheckTool.onCatalogFound  = { [weak self] products in
            guard let self else { return }
            Task { @MainActor in
                self.onCatalogFound?(products)
            }
        }
    }

    func processRequest(_ pront: String) async throws -> sending LanguageModelSession.ResponseStream<String> {
        // The model automatically decides the step order:
        // Turn 1: Calls `search_inventory(keyword: "party")` -> receives ["SKU-101", "SKU-204"]
        // Turn 2: Sees product IDs, calls `check_prices(itemIDs: ["SKU-101", "SKU-204"])`
        // Turn 3: Synthesizes final user-facing recommendation based on prices
        return session.streamResponse(to: pront)
    }
}
