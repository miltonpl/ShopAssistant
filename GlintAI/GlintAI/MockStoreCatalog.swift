//
//  MockStoreCatalog.swift
//  GlintAI
//
//  Created by Milton Palaguachi on 9/29/26.
//

import Foundation

struct Product: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let category: String
    let price: Double
    let description: String
}

// Quick mock store catalog for the demo
struct MockStoreCatalog {
    static let items = [
        Product(id: "1", name: "Dino Party Plates (10pk)", category: "Party Supplies", price: 12.99, description: "Green dinosaur themed sturdy paper plates."),
        Product(id: "2", name: "Green Napkins (50pk)", category: "Party Supplies", price: 4.50, description: "Dark green cocktail napkins matching a jungle theme."),
        Product(id: "3", name: "Dinosaur Cake Topper", category: "Bakery", price: 8.99, description: "T-Rex sparkling cake topper decoration."),
        Product(id: "4", name: "Taco Shells (12pk)", category: "Pantry", price: 3.29, description: "Crunchy corn taco shells."),
        Product(id: "5", name: "Mild Taco Seasoning", category: "Pantry", price: 1.19, description: "Classic Mexican spice mix blend.")
    ]
    
    static func search(query: String) -> [Product] {
        let lowercaseQuery = query.lowercased()
        return items.filter {
            $0.name.lowercased().contains(lowercaseQuery) ||
            $0.description.lowercased().contains(lowercaseQuery) ||
            $0.category.lowercased().contains(lowercaseQuery)
        }
    }
}
