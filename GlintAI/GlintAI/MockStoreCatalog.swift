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
    let quantity: Int
    let description: String
    let discount: String
}

// Quick mock store catalog for the demo
struct MockStoreCatalog {
    static let items = [
        Product(
            id: "SKU-1001",
            name: "Dino Party Plates (10pk)",
            category: "Party Supplies",
            price: 12.99,
            quantity: 1,
            description: "Green dinosaur themed sturdy paper plates.",
            discount: "10%"
        ),
        Product(
            id: "SKU-10012",
            name: "Green Napkins (50pk)",
            category: "Party Supplies",
            price: 4.50,
            quantity: 1,
            description: "Dark green cocktail napkins matching a jungle theme.",
        discount: "none"
        ),
        Product(
            id: "SKU-10013",
            name: "Dinosaur Cake Topper",
            category: "Bakery", price: 8.99,
            quantity: 1,
            description: "T-Rex sparkling cake topper decoration.",
            discount: "2%"
        ),
        Product(
            id: "SKU-10014",
            name: "Taco Shells (12pk)",
            category: "Pantry", price: 3.29,
            quantity: 1,
            description: "Crunchy corn taco shells.",
            discount: "none"
        ),
        Product(
            id: "SKU-10015",
            name: "Mild Taco Seasoning",
            category: "Pantry",
            price: 1.19,
            quantity: 1,
            description: "Classic Mexican spice mix blend.",
            discount: "20%"
        )
    ]
    
    static func search(query: String) -> [Product] {
        let lowercaseQuery = query.lowercased()
        return items.filter {
            $0.name.lowercased().contains(lowercaseQuery) ||
            $0.description.lowercased().contains(lowercaseQuery) ||
            $0.category.lowercased().contains(lowercaseQuery)
        }
    }

    static func priceLookUp(itemIDs: [String]) async -> [Product] {
        let itemIDsSet = Set(itemIDs)
        var result = [Product]()

        for id in itemIDsSet {
            for item in items {
                if item.id == id {
                    result.append(item)
                    break
                }
            }
        }

        return result
    }
}
