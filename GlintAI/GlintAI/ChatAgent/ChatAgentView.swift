//
//  ChatAgentView.swift
//  GlintAI
//
//  Created by Milton Palaguachi on 10/17/26.
//

import ComposableArchitecture
import SwiftUI

struct ChatAgentView: View {
//    let store: StoreOf<ChatAgentFeature>
    // Automatically pull the store out of the SwiftUI envirenment
    @Environment(StoreOf<ChatAgentFeature>.self) var store
    
    var body: some View {
        // 1. Add Perception Tracking to guarantee layout row reference on mutations
        // 🔍 ADD THIS PRINT:
        let _ = print("🔄 View body re-evaluated! Current product count: \(store.discoveredProducts.count)")
        VStack(spacing: 0) { // Clear layout padding loops
            ScrollView {
                Text(store.coversationText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }

            // Horizontal drawer that naturally expands as the agent tools discover products
            Group {
                if !store.discoveredProducts.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(store.discoveredProducts) { product in
                                VStack(alignment: .leading, spacing: 4){
                                    Text(product.name).font(.headline)
                                    Text(String(format: "$%.2f", product.price))
                                }
                                .padding()
                                .background(Color.blue.opacity(0.2))
                                .foregroundStyle(.primary)
                                .clipShape(.capsule(style: .circular))
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 80)
                    .background(Color.red.opacity(0.1))
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.default, value: store.discoveredProducts)

            // Input Controls layout line
            HStack {
                TextField(
                    "Ask Sparky something...",
                    text: Binding(
                        get: { store.currentInput },
                        set: { store.send(.inputChanged($0)) }
                    )
                )
                .textFieldStyle(.roundedBorder)

                Button(action: { store.send(.sendButtonTapped)}, label: {
                    if store.isStreaming {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.up.circle.fill").font(.title2)
                    }
                })
                .disabled(store.isStreaming || store.currentInput.isEmpty)
            }
            .padding()
        }
        .navigationTitle("Sparky")
        .navigationBarTitleDisplayMode(.inline)
        // Starts the backing catalog AsyncStream observation loop immediately
        .task { await store.send(.task).finish() }
    }
}

#Preview {
    let store =  Store(
        initialState: ChatAgentFeature.State(),
        reducer: {
            // 1. Specify the feature reducer running this enviroment
            ChatAgentFeature()
        }, withDependencies: { dependency in
            // 2. Inject your preview agent dependency override here
            dependency.shoppingAgent = ShoppingAgentClient.previewValue
        }
    )

    ChatAgentView().environment(store)
}

/*
 1. Store(initialState: ...): We wrap the feature inside a Store shell, setting up an empty starting state (ChatAgentFeature.State()).
 2. withDependencies: Instead of passing the dependency into the Reducer struct as a parameter, TCA uses Swift's native dependency injection environment. The trailing withDependencies block allows you to intercept the macro environment and swap out the live agent for your mock previewValue cleanly.
 This setup allows your canvas preview to instantly render without launching any heavy real-world execution pipelines!
 Does the canvas live preview load up correctly now with this Store declaration, or are you encountering any type resolution errors with the previewValue mock structure?
 */
