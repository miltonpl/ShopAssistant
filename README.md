# ShopAssistant
Demo of Instore A
![Demo of my project](demos/glint_demo.gif)


Show how to implement multi-step agentic tool chaining using Swift FoundationModels.
In Apple's FoundationModels framework, multi-step agentic workflows can be implemented using two main patterns:

1. Automatic Tool Loop (Implicit Chaining): The LanguageModelSession inspects available tools, invokes them when requested by the model, appends the output back into the message turn history, and continues reasoning until it produces a final response.

2. Explicit Sequential Chaining (Pipeline Pattern): Directly routing the strongly typed output (Output) of one Tool into the input (Arguments) of another inside a structured workflow.

We will be implmenting the explicit sequestion chaining
```
struct ShoppingAgent {
    let searchTool = StoreCatalogTool()
    let priceTool: PriceCheckTool

    private let session = LanguageModelSession(
        model: .default,
        instructions: "You are Sparky, an AI shopping helper. Keep responses short and conversational."
    )

    func executeWorkFlow(query: String) async throws -> sending LanguageModelSession.ResponseStream<String> {
        // Step 1: Execute Tool A
        let searchArgs = StoreSearchArguments(searchQuery: query)
        let itemsIDs = try await searchTool.call(arguments: searchArgs)

        guard !itemsIDs.isEmpty else {
            return session.streamResponse(
                to: "Inform the user clearly that no items were found matching '\(query)' in the store catalog."
            )
        }

        // Step 2: Feed Output directly into Tool B Input
        let priceArgs = PriceCheckArgs(itemIDs: itemsIDs)
        let rawProductJSON = try await priceTool.call(arguments: priceArgs)

        // Step 3: Construct prompt with pipeline context
        let promptWithContext = """
            User Request: \(query)
                
            Context Data (Retrieved from Catalog & Pricing):
            \(rawProductJSON)

        Construct responses short and conversational with item details.
        """
        return session.streamResponse(to: promptWithContext)
    }
}
```