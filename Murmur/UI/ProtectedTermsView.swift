import SwiftUI

struct ProtectedTermsView: View {
    @Binding var terms: [String]
    let zh: Bool
    @State private var inputText = ""

    // Suggested terms — common technical terms that Whisper/LLM often mangle
    private static let suggestions = [
        "API", "JSON", "React", "Vue", "Python", "TypeScript",
        "Docker", "GitHub", "Kubernetes", "GraphQL", "WebSocket",
        "OAuth", "JWT", "Redis", "PostgreSQL", "MongoDB",
        "webpack", "npm", "Node.js", "Swift", "SwiftUI",
        "useState", "async", "await", "localhost", "CSS",
    ]

    /// Suggestions not already added
    private var availableSuggestions: [String] {
        Self.suggestions.filter { !terms.contains($0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Tag pills — flow layout
            if !terms.isEmpty {
                FlowLayout(spacing: 4) {
                    ForEach(terms, id: \.self) { term in
                        termPill(term)
                    }
                }
            }

            // Input field
            HStack(spacing: 6) {
                TextField(zh ? "添加术语，按回车确认" : "Add term, press Return",
                          text: $inputText)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12, design: .monospaced))
                    .onSubmit { addCurrentInput() }

                if !terms.isEmpty {
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) { terms.removeAll() }
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help(zh ? "清空所有" : "Clear all")
                }
            }

            // Quick-add suggestions
            if !availableSuggestions.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text(zh ? "快速添加" : "Quick add")
                        .font(.caption2).foregroundStyle(.tertiary)
                    FlowLayout(spacing: 3) {
                        ForEach(availableSuggestions.prefix(12), id: \.self) { term in
                            Button {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    terms.append(term)
                                }
                            } label: {
                                Text("+ \(term)")
                                    .font(.system(size: 10, design: .monospaced))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 0.5)
                                    )
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Text(zh ? "润色时保持这些术语不被修改" : "Keep these terms unchanged during text polish")
                .font(.caption2).foregroundStyle(.tertiary)
        }
    }

    // MARK: - Components

    private func termPill(_ term: String) -> some View {
        HStack(spacing: 3) {
            Text(term)
                .font(.system(size: 11, design: .monospaced))
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    terms.removeAll { $0 == term }
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.accentColor.opacity(0.1))
        )
    }

    // MARK: - Actions

    private func addCurrentInput() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        // Support comma-separated batch input
        let newTerms = trimmed.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !terms.contains($0) }
        guard !newTerms.isEmpty else { return }
        withAnimation(.easeInOut(duration: 0.15)) {
            terms.append(contentsOf: newTerms)
        }
        inputText = ""
    }
}

// MARK: - Flow Layout (wrapping horizontal layout)

struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var height: CGFloat = 0
        for (i, row) in rows.enumerated() {
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            height += rowHeight + (i > 0 ? spacing : 0)
        }
        return CGSize(width: proposal.width ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            var x = bounds.minX
            for subview in row {
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += rowHeight + spacing
        }
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubviews.Element]] {
        let maxWidth = proposal.width ?? .infinity
        var rows: [[LayoutSubviews.Element]] = [[]]
        var currentWidth: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentWidth + size.width > maxWidth && !rows[rows.count - 1].isEmpty {
                rows.append([])
                currentWidth = 0
            }
            rows[rows.count - 1].append(subview)
            currentWidth += size.width + spacing
        }
        return rows
    }
}
