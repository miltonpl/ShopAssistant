# GlintAI - On-Device LLM Shopping Assistant 🛍️🤖

GlintAI is a native iOS application leveraging Apple's **FoundationModels** framework (introduced for on-device Apple Intelligence) to power an intelligent shopping assistant. It features strongly-typed tool execution, concurrent async streaming for text and product catalogs, and fully local, privacy-first reasoning on Apple Silicon.

---

## Architecture Highlights

### 1. Strongly-Typed Tool Execution (`@Generable`)
GlintAI utilizes Swift macros (`@Generable` and `@Guide`) to define type-safe tool schemas at compile time, eliminating runtime JSON schema errors:
* **`StoreSearchArguments`**: Strongly-typed argument schemas validated directly by the local LLM runtime.
* **`StoreCatalogTool`**: Conforms to the `Tool` protocol, returning live product matching catalogs.

### 2. Strategy Pattern & Agent Polymorphism
The app implements the `ShoppingAgentServices` protocol, allowing dynamic switching between agent architectures at runtime:
* **`AutonomousShoppingAgent`**: Autonomous multi-step tool execution loops driven by `LanguageModelSession`.
* **`StreamingShoppingAgent`**: Specialized deterministic pipelines and streaming workflows.

### 3. Concurrent Dual-Stream Coordination
`StreamingChatViewModel` coordinates two independent asynchronous sequences simultaneously:
1. **Text Generation Stream**: Consumes `AsyncThrowingStream<String, Error>` from `processRequest(_:)` to stream incremental tokens into chat bubbles in real time.
2. **Catalog Product Stream**: Concurrently listens to `AsyncStream<[Product]>` (`catalogStream`), instantly rendering interactive product cards the moment tools discover items.

---

## Core Components

### `StreamingChatViewModel.swift`
The central coordinator managing state on the `@MainActor`:

```swift
@MainActor
class StreamingChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var currentInput: String = ""
    @Published var isTyping: Bool = false
    @Published var autonomousAgent: Bool = false {
        didSet { updateAgent() }
    }
    
    // Coordinates concurrent text tokens and product catalog streams
    func handleSend() { ... }
}
```

---

## Error Handling & Resiliency

GlintAI handles edge cases specific to on-device AI model deployment:
* **Asset Availability**: Gracefully catches `LanguageModelSession.GenerationError.assetsUnavailable` to prompt users when Apple Intelligence model weights are still downloading or storage is constrained.
* **Task Cancellation**: Prevents race conditions and orphaned background work by canceling active tasks when users submit rapid follow-up queries or navigate away.

---

## Requirements

* **iOS / iPadOS / macOS**: Compatible with systems supporting Apple Intelligence and the `FoundationModels` framework.
* **Xcode**: 16.0 or newer.
* **Swift**: Swift 6 strict concurrency enabled.

---

## License
This project is proprietary and built for demonstration of Apple on-device machine learning workflows.