//
//  ContentView.swift
//  GlintAI
//
//  Created by Milton Palaguachi on 9/29/26.
//

import ComposableArchitecture
import SwiftUI

struct ContentView: View {
    // Create a single s
    @State private var store =  Store(
        initialState: ChatAgentFeature.State(),
        reducer: {
            ChatAgentFeature()
        },
        withDependencies: {
            $0.shoppingAgent = ShoppingAgentClient.liveValue
        }
    )

    var body: some View {
        WelcomeView()
            .environment(store)
    }
}

#Preview {
    ContentView()
}
