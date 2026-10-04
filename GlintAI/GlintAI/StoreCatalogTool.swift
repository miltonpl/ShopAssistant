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
    typealias Output = String  // Can be a String or any Encodable / @Generable struct
    
    // Required protocol properties
    var name: String = "search_store_catalog"
    var description: String = "Searches the store catalog inventory for items matching a specific theme, occasion, or item keyword."
    
    // RECRUITER FLEX: Infer the required parameters schema automatically using the Swift macro type metadata
    var parameters: GenerationSchema {
        StoreSearchArguments.generationSchema
    }
    
    // Callback to update your SwiftUI logic
    let onCatalogFound: @Sendable ([Product]) -> Void
    
    // The required execution callback matching your associated types
    @MainActor
    func call(arguments: StoreSearchArguments) async throws -> String {
        let matches = MockStoreCatalog.search(query: arguments.searchQuery)

        onCatalogFound(matches)

        let encoder = JSONEncoder()
        if let data = try? encoder.encode(matches), let jsonString = String(data: data, encoding: .utf8) {
            return jsonString
        }
        return "[]"
    }
}
