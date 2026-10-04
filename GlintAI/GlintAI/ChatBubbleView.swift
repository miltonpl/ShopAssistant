//
//  ChatBubbleView.swift
//  GlintAI
//
//  Created by Milton Palaguachi on 9/29/26.
//

import SwiftUI

struct ChatBubbleView: View {
    let message: ChatMessage
    
    var body: some View {
        VStack(alignment: message.isUser ? .trailing : .leading, spacing: 8) {
            // The Chat Bubble Bubble Wrapper
            Text(message.text)
                .font(.body)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(message.isUser ? Color.blue : Color(.systemGray6))
                .foregroundColor(message.isUser ? .white : .primary)
                .clipShape(ChatBubbleShape(isUser: message.isUser))
                .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)
            
            // If the AI tool found store inventory matches, render the inline Carousel
            if !message.items.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Found in Store Inventory:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(message.items) { item in
                                ProductCardView(product: item)
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 4)
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity), removal: .opacity))
            }
        }
    }
}

// 📦 Reusable Product Card Component
struct ProductCardView: View {
    let product: Product
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Placeholder Image Slot
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
                .frame(height: 90)
                .overlay(
                    Image(systemName: "cart.badge.questionmark")
                        .foregroundColor(.secondary)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(product.name)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(product.category)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(String(format: "$%.2f", product.price))
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                    .padding(.top, 2)
            }
            
            Button(action: {
                // Handle Add to Cart logic
            }) {
                Text("Add to Cart")
                    .font(.caption)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(Color.yellow)
                    .foregroundColor(.black)
                    .cornerRadius(6)
            }
            .padding(.top, 4)
        }
        .padding(10)
        .frame(width: 150)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

// 📐 Custom Shape for dynamic message styling (Tailored corners)
struct ChatBubbleShape: Shape {
    let isUser: Bool
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: isUser ?
                [.topLeft, .topRight, .bottomLeft] :
                [.topLeft, .topRight, .bottomRight],
            cornerRadii: CGSize(width: 16, height: 16)
        )
        return Path(path.cgPath)
    }
}
