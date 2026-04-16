import Foundation

final class LLMCleanup: Sendable {
    private let baseURL = "http://localhost:11434"

    private let cleanupPrompt = """
        Fix this voice dictation transcript. Rules:
        - Remove filler words (um, uh, like, you know, so, basically, actually, I mean, 嗯, 啊, 那个, 就是, 然后)
        - Fix grammar, spelling, and punctuation
        - Keep the EXACT meaning and tone — do NOT rephrase or add words
        - If it's code-related, preserve technical terms, variable names, function names exactly
        - For Chinese text: ALWAYS convert to Simplified Chinese (简体中文), fix punctuation (use 。，！？ etc.), do NOT translate to English
        - For mixed Chinese-English text: keep each part in its original language
        - Output ONLY the cleaned text, nothing else
        - Do NOT add quotes around the output
        """

    /// Check if Ollama is running and responsive
    static func checkAvailability() async -> Bool {
        guard let url = URL(string: "http://localhost:11434/api/tags") else { return false }
        var request = URLRequest(url: url)
        request.timeoutInterval = 2

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }

    /// Clean up transcribed text using local Ollama LLM
    func cleanup(text: String, model: String = "qwen2.5:1.5b") async -> String {
        guard let url = URL(string: "\(baseURL)/api/generate") else { return text }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let body: [String: Any] = [
            "model": model,
            "prompt": "\(cleanupPrompt)\n\nTranscript: \(text)",
            "stream": false,
            "options": [
                "temperature": 0.1,
                "num_predict": max(200, text.count * 2)
            ]
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: request)

            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return text }

            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let responseText = json["response"] as? String {
                let cleaned = responseText
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))

                // Sanity check: don't return empty or much longer than input
                if !cleaned.isEmpty && cleaned.count < text.count * 3 {
                    return cleaned
                }
            }
        } catch {
            // Silently fall back to raw text
        }

        return text
    }
}
