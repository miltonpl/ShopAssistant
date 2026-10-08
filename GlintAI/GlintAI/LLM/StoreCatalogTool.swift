//
//  StoreCatalogTool.swift
//  GlintAI
//
//  Created by Milton Palaguachi on 9/29/26.
//

import Foundation
import FoundationModels

// 1. Define your strongly-typed input arguments using the @Generable macro
@Generable
struct StoreSearchArguments: Equatable {
    @Guide(description: "The shopping search terms. E.g., 'dinosaur decorations' or 'ground beef'")
    var searchQuery: String
}


// 2. Conform your tool to the protocol completely
struct StoreCatalogTool: Tool {
    
    // Explicit Protocol Associated Types
    typealias Arguments = StoreSearchArguments
    typealias Output = [String]  // Can be a String or any Encodable / @Generable struct
    
    // Required protocol properties
    var name: String = "search_store_catalog"
    var description: String = "Searches the store catalog inventory for items matching a specific theme, occasion, or item keyword."
    
    // RECRUITER FLEX: Infer the required parameters schema automatically using the Swift macro type metadata
    var parameters: GenerationSchema {
        StoreSearchArguments.generationSchema
    }

    // The required execution callback matching your associated types
    @MainActor
    func call(arguments: StoreSearchArguments) async throws -> [String] {
        let matches = MockStoreCatalog.search(query: arguments.searchQuery)
        return matches.map { $0.id }
    }
}

// Tool 2: Check live pricing & discount for specific item IDs
@Generable
struct PriceCheckArgs: Equatable {
    @Guide(description: "List of SKU IDs to check price for.")
    var itemIDs: [String]
}

struct PriceCheckTool: Tool {
    typealias Arguments = PriceCheckArgs
    typealias Output = String
    
    var name = "check_price"
    var description = "Retrieves item details like name, price, and current discount for the given item IDs."
    var parameters: GenerationSchema { PriceCheckArgs.generationSchema }

    // Callback to update your SwiftUI logic
    var onCatalogFound: (@Sendable([Product]) -> Void)?

    @MainActor
    func call(arguments: PriceCheckArgs) async throws -> String {
        let items = MockStoreCatalog.priceLookUp(itemIDs: arguments.itemIDs)

        onCatalogFound?(items)

        let json = JSONEncoder()
        guard let data = try? json.encode(items), let jsonData = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return jsonData
    }
}
