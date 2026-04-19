import Foundation

enum PolishStyle: String, CaseIterable {
    case auto       // 自动：根据内容智能选择处理方式
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

    private let autoPrompt = """
        清理这段语音转写文本。采用融合式格式——一段话中可能同时包含自然叙述和列举，两部分都要保留：
        处理方式：
        - 删除口语词（嗯、啊、那个、就是、然后、所以说、基本上）
        - 在合适位置加标点
        - 如果内容很短或很简单，只加标点，几乎不改
        - 如果说话人在列举多个事项，把列举部分整理为编号列表，但保留列举前后的自然叙述
        - 口头序号（第一、第二、首先、其次、然后）转为阿拉伯数字编号（1. 2. 3.）
        - 例如输入"我觉得有三个问题第一性能差第二太复杂所以要改"应输出"我觉得有三个问题：\n1. 性能差\n2. 太复杂\n所以要改。"
        规则：
        - 保留说话人的原始用词，不要替换成同义词
        - 禁止添加原文没有的内容
        - 中文文字之间不要加空格！只在中英文交界处加空格
        - 保留所有英文术语原样！不要把英文翻译成中文！
        - 禁止翻译！输入什么语言就输出什么语言！
        - 只输出处理后的结果
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
        整理这段语音转写为结构化格式。采用融合式——保留自然叙述部分，只对列举部分结构化：
        - 把列举的事项整理为编号列表（1. 2. 3.）
        - 口头序号（第一、第二、首先、其次、然后）转为阿拉伯数字编号
        - 保留列举前后的自然叙述，不要丢弃
        - 如果原文没有列举内容，只清理标点和口语词
        - 删除口语词（嗯、啊、那个、就是、然后）
        - 保留说话人的原始用词，不要改写
        - 禁止添加原文没有的内容或解释
        - 保留所有英文术语原样！不要把英文翻译成中文！
        - 禁止翻译成英文！输入什么语言就输出什么语言！
        """

    /// Build the full prompt for a given style
    private func buildPrompt(style: PolishStyle, text: String, customPrompt: String, protectedTerms: [String]) -> String {
        let stylePrompt: String
        switch style {
        case .auto: stylePrompt = autoPrompt
        case .spoken: stylePrompt = spokenPrompt
        case .natural: stylePrompt = naturalPrompt
        case .concise: stylePrompt = concisePrompt
        case .structured: stylePrompt = structuredPrompt
        case .custom:
            stylePrompt = customPrompt.isEmpty ? naturalPrompt : customPrompt
        }

        var prompt = stylePrompt + "\n" + sharedRules

        if !protectedTerms.isEmpty {
            let termList = protectedTerms.joined(separator: "、")
            prompt += "\n如果原文中出现以下词汇，保持原样不要修改：\(termList)"
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
        case .auto: return 2.0
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

        let prompt = buildPrompt(style: style, text: text, customPrompt: customPrompt, protectedTerms: protectedTerms)
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

                return Self.removeSpacesBetweenChinese(cleaned)
            }
        } catch {
            // Silently fall back to raw text
        }

        return text
    }

    /// Remove spaces between Chinese characters (LLM sometimes adds word-level spaces)
    /// Preserves spaces around English words and numbers.
    private static let cjkPunctBefore: Set<Character> = Set(Array("，。！？、；：\u{201C}\u{201D}\u{2018}\u{2019}）】」"))
    private static let cjkPunctAfter: Set<Character> = Set(Array("，。！？、；：\u{201C}\u{201D}\u{2018}\u{2019}（【「"))

    private static func isCJK(_ c: Character) -> Bool {
        guard let sv = c.unicodeScalars.first else { return false }
        return sv.value >= 0x4E00 && sv.value <= 0x9FFF
    }

    private static func removeSpacesBetweenChinese(_ text: String) -> String {
        var result = ""
        let chars = Array(text)
        for i in 0..<chars.count {
            let c = chars[i]
            if c == " " && i > 0 && i < chars.count - 1 {
                let prev = chars[i - 1]
                let next = chars[i + 1]
                if (isCJK(prev) || cjkPunctBefore.contains(prev)) &&
                   (isCJK(next) || cjkPunctAfter.contains(next)) {
                    continue
                }
            }
            result.append(c)
        }
        return result
    }
}
