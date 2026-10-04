//
//  WelcomeView.swift
//  GlintAI
//
//  Created by Milton Palaguachi on 10/1/26.
//

import SwiftUI

enum DestinedScreen {
    case chat
    case setting
    case notification
}

struct WelcomeView: View {
    @State private var navigationPath = [DestinedScreen]()

    var body: some View {
        NavigationStack(path: $navigationPath) { // Wraps the root view to enable navigation
            
            VStack(alignment: .center, spacing: 30) {
                Spacer()
                Image("logo")
                    .resizable() // Allows the image to scale
                    .scaledToFit() // Maintains original aspect ration without cropping
                    .frame(maxWidth: 300, maxHeight: 300)
                    .padding(.horizontal, 40)
                VStack {
                    WelcomeMiddleView()
                    Spacer()
                    WelcomeBottomView {
                        navigationPath.append(.chat)
                    }
                }
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 30)
            .navigationDestination(for: DestinedScreen.self) { screen in
                switch screen {
                case .chat:
                    StreamingChatView()
                case .setting:
                    StreamingChatView()
                case .notification:
                    StreamingChatView()
                }
            }
        }
    }
}

struct WelcomeMiddleView: View {
    var body: some View {
        VStack(alignment: .center) {
            HStack(alignment: .center, spacing: 4) {
                Text("Your")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.brown, .clear)
                Text("AI Glint.")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.blue)
            }
            Text("Always On. Always Smart.")
                .lineLimit(2)
                .font(.title)
                .bold()
        }
    }
}

struct WelcomeBottomView: View {
    var onAction: () -> Void

    var body: some View {
        Button {
            dump("Hit top")
            onAction()
        } label: {
            Image(systemName: "ellipsis.message")
                .resizable()
                .scaledToFit()
                .frame(minWidth: 20, maxWidth: 45, minHeight: 20, maxHeight: 45)
        }
    }
}
