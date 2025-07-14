import OpenAI
import Foundation

@main
struct OpenAIDemo {
    static func main() async throws {
        guard let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] else {
            print("Missing OPENAI_API_KEY")
            return
        }

        let openAI = OpenAI(apiToken: apiKey)
        let query = CreateModelResponseQuery(
            input: .textInput("Tell me a short joke about MMA"),
            model: .gpt4_1,
            stream: true
        )

        let stream = openAI.responses.createResponseStreaming(query: query)

        do {
            for try await event in stream {
                print(event)
            }
        } catch {
            print("Stream error: \(error)")
        }
    }
}
