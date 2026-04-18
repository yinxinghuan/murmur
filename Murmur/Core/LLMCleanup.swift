import Foundation

enum PolishStyle: String, CaseIterable {
    case spoken     // 口语：最小干预，只加标点
    case natural    // 自然：去口语词，修标点
    case concise    // 精简：压缩冗余，直达意图
    case structured // 结构化：多步骤转有序列表
    case custom     // 自定义：用户写 prompt
}

final class LLMCleanup: Sendable {
    private let baseURL = "http://localhost:11434"

    private let sharedRules = """
        - 禁止翻译！中文输入必须输出中文。英文输入必须输出英文。
        - 中英混合文本保持各自语言不变
        - 代码相关的技术术语保持原样
        - 中文文本用中文标点（。，！？）
        - 只输出处理后的文本，不要加引号
        """

    private let spokenPrompt = """
        只加标点符号。不删除任何词，不改写，不翻译。原文怎么说就怎么输出，只在合适的位置加上标点。
        输入什么语言就输出什么语言！只输出结果。
        """

    private let naturalPrompt = """
        你是标点修正工具。你的任务：
        1. 删除句首的口语词（嗯、啊、那个）
        2. 删除句子之间的连接词（就是、然后、所以说、基本上）
        3. 在合适位置加标点（，。！？）
        绝对禁止的事：
        - 禁止改写任何词语！原文用什么词就保留什么词！
        - 禁止翻译！禁止把英文术语翻译成中文！
        - 禁止添加原文没有的内容！
        - 禁止把原文的词替换成同义词！
        输入什么语言就输出什么语言！只输出结果。
        """

    private let concisePrompt = """
        精简这段语音转写，只保留核心意图。
        规则：
        - 删除所有冗余、重复、口语词（嗯、啊、那个、就是、然后、所以说、基本上）
        - 用最短的表达传达完整意思
        - 禁止添加原文没有的内容
        - 输出必须比输入短
        - 保留所有英文术语原样！不要把英文翻译成中文！
        - 禁止翻译成英文！输入什么语言就输出什么语言！
        """

    private let structuredPrompt = """
        整理这段语音转写为结构化格式。
        规则：
        - 多个事项用编号列表，单个事项用一句简洁的话
        - 删除所有口语词和冗余
        - 禁止添加原文没有的内容或解释
        - 保留所有英文术语原样！不要把英文翻译成中文！
        - 禁止翻译成英文！输入什么语言就输出什么语言！
        """

    /// Build the full prompt for a given style
    private func buildPrompt(style: PolishStyle, customPrompt: String, protectedTerms: [String]) -> String {
        let stylePrompt: String
        switch style {
        case .spoken: stylePrompt = spokenPrompt
        case .natural: stylePrompt = naturalPrompt
        case .concise: stylePrompt = concisePrompt
        case .structured: stylePrompt = structuredPrompt
        case .custom:
            stylePrompt = customPrompt.isEmpty ? naturalPrompt : customPrompt
        }

        var prompt = stylePrompt + "\n" + sharedRules

        if !protectedTerms.isEmpty {
            let termList = protectedTerms.joined(separator: ", ")
            prompt += """

            CRITICAL — The following terms MUST be preserved exactly as-is (do NOT translate, correct spelling, or modify them in any way):
            \(termList)
            """
        }

        return prompt
    }

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
    /// Max output length multiplier per style.
    /// Natural should never add content; concise/structured may reformat.
    private func maxLengthMultiplier(for style: PolishStyle) -> Double {
        switch style {
        case .spoken: return 1.2
        case .natural: return 1.5
        case .concise: return 1.5
        case .structured: return 2.0  // numbered lists add formatting overhead
        case .custom: return 2.0
        }
    }

    func cleanup(
        text: String,
        model: String = "qwen2.5:1.5b",
        style: PolishStyle = .natural,
        customPrompt: String = "",
        protectedTerms: [String] = []
    ) async -> String {
        guard let url = URL(string: "\(baseURL)/api/generate") else { return text }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let prompt = buildPrompt(style: style, customPrompt: customPrompt, protectedTerms: protectedTerms)
        let body: [String: Any] = [
            "model": model,
            "prompt": "\(prompt)\n\nTranscript: \(text)",
            "stream": false,
            "options": [
                "temperature": 0.1,
                "num_predict": max(100, Int(Double(text.count) * maxLengthMultiplier(for: style)))
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

                // Sanity checks: output should not be much longer than input
                guard !cleaned.isEmpty else { return text }
                let maxLen = Int(Double(text.count) * maxLengthMultiplier(for: style))
                if cleaned.count > maxLen {
                    owLog("[LLM] Discarded: output too long (\(cleaned.count) vs input \(text.count), max \(maxLen))")
                    return text
                }

                // Language guard: if input has Chinese but output lost it, LLM translated — discard
                let inputHasChinese = text.unicodeScalars.contains { $0.value >= 0x4E00 && $0.value <= 0x9FFF }
                let outputHasChinese = cleaned.unicodeScalars.contains { $0.value >= 0x4E00 && $0.value <= 0x9FFF }
                if inputHasChinese && !outputHasChinese {
                    owLog("[LLM] Discarded: LLM translated Chinese to English")
                    return text
                }

                return cleaned
            }
        } catch {
            // Silently fall back to raw text
        }

        return text
    }
}
