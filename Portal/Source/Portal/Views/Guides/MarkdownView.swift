import SwiftUI
import UIKit

struct MarkdownView: View {
    let parsed: ParsedGuideContent

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(parsed.elements) { element in
                render(element)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func render(_ element: GuideElement) -> some View {
        switch element {
        case .heading(let level, let text, let isAccent):
            Text(text)
                .font(headingFont(level))
                .fontWeight(.bold)
                .foregroundColor(isAccent ? Color.accentColor : Color.primary)
                .padding(.top, level == 1 ? 6 : 2)
                .textSelection(.enabled)
                .contextMenu {
                    copyButton(plainText(for: element))
                }

        case .paragraph(let content):
            Text(attributedInline(content))
                .font(.body)
                .foregroundColor(Color.primary)
                .textSelection(.enabled)
                .contextMenu {
                    copyButton(plainText(for: element))
                }

        case .codeBlock(let language, let code):
            VStack(alignment: .leading, spacing: 8) {
                if let language, !language.isEmpty {
                    Text(language.uppercased())
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Color.secondary)
                }

                ScrollView(.horizontal, showsIndicators: true) {
                    Text(code)
                        .font(.system(.body, design: .monospaced))
                        .padding(12)
                        .textSelection(.enabled)
                }
                .background(Color.secondary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .contextMenu {
                copyButton(code)
            }

        case .listItem(let level, let content):
            HStack(alignment: .top, spacing: 10) {
                Text("•")
                    .foregroundColor(Color.secondary)
                Text(attributedInline(content))
                    .foregroundColor(Color.primary)
                    .textSelection(.enabled)
            }
            .padding(.leading, CGFloat(level) * 18)
            .contextMenu {
                copyButton(plainText(for: element))
            }

        case .blockquote(let content):
            HStack(alignment: .top, spacing: 12) {
                Rectangle()
                    .fill(Color.secondary.opacity(0.5))
                    .frame(width: 4)

                Text(attributedInline(content))
                    .italic()
                    .foregroundColor(Color.primary)
                    .textSelection(.enabled)
            }
            .padding(.vertical, 4)
            .contextMenu {
                copyButton(plainText(for: element))
            }

        case .image(let url, let altText):
            VStack(alignment: .leading, spacing: 8) {
                AsyncImage(url: URL(string: url)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    case .failure:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.secondary.opacity(0.12))
                            .frame(maxWidth: .infinity)
                            .frame(height: 160)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 32))
                                    .foregroundColor(Color.secondary)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }

                if let altText, !altText.isEmpty {
                    Text(altText)
                        .font(.caption)
                        .foregroundColor(Color.secondary)
                        .textSelection(.enabled)
                }
            }
            .contextMenu {
                copyButton(plainText(for: element))
            }

        case .link(let url, let text):
            if let u = URL(string: url) {
                Link(destination: u) {
                    HStack(spacing: 6) {
                        Text(text)
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                    }
                }
                .foregroundColor(Color.blue)
                .contextMenu {
                    copyButton(text)
                    Button("Copy URL") { UIPasteboard.general.string = url }
                }
            } else {
                Text(text)
                    .foregroundColor(Color.secondary)
                    .textSelection(.enabled)
                    .contextMenu {
                        copyButton(text)
                    }
            }
        }
    }

    private func copyButton(_ text: String) -> some View {
        Button("Copy") {
            UIPasteboard.general.string = text
        }
    }

    private func headingFont(_ level: Int) -> Font {
        switch level {
        case 1: return .title
        case 2: return .title2
        case 3: return .title3
        default: return .headline
        }
    }

    private func attributedInline(_ content: [InlineContent]) -> AttributedString {
        var md = ""

        for part in content {
            switch part {
            case .text(let t):
                md += t
            case .accentText(let t):
                md += t
            case .link(let url, let text):
                md += "[\(escapeMarkdown(text))](\(url))"
            case .accentLink(let url, let text):
                md += "[\(escapeMarkdown(text))](\(url))"
            }
        }

        if let a = try? AttributedString(markdown: md, options: .init(interpretedSyntax: .full)) {
            var out = a
            for run in out.runs {
                if run.link != nil {
                    out[run.range].foregroundColor = Color.blue
                }
            }
            return out
        }

        return AttributedString(md)
    }

    private func plainText(for element: GuideElement) -> String {
        switch element {
        case .heading(_, let text, _):
            return text

        case .paragraph(let content):
            return stripInlineMarkdown(inlinePlainText(content))

        case .codeBlock(_, let code):
            return code

        case .image(let url, let altText):
            if let altText, !altText.isEmpty {
                return "\(altText)\n\(url)"
            }
            return url

        case .link(let url, let text):
            return "\(text)\n\(url)"

        case .listItem(_, let content):
            return stripInlineMarkdown(inlinePlainText(content))

        case .blockquote(let content):
            return stripInlineMarkdown(inlinePlainText(content))
        }
    }

    private func inlinePlainText(_ content: [InlineContent]) -> String {
        var s = ""
        for part in content {
            switch part {
            case .text(let t):
                s += t
            case .accentText(let t):
                s += t
            case .link(let url, let text):
                s += text
                if !url.isEmpty { s += " (\(url))" }
            case .accentLink(let url, let text):
                s += text
                if !url.isEmpty { s += " (\(url))" }
            }
        }
        return s
    }

    private func stripInlineMarkdown(_ text: String) -> String {
        var t = text
        let removals = ["**", "__", "*", "_", "`", "~~"]
        for r in removals { t = t.replacingOccurrences(of: r, with: "") }

        if let regex = try? NSRegularExpression(pattern: #"\[([^\]]+)\]\(([^)]+)\)"#) {
            let range = NSRange(t.startIndex..., in: t)
            t = regex.stringByReplacingMatches(in: t, range: range, withTemplate: "$1 ($2)")
        }

        return t
    }

    private func escapeMarkdown(_ s: String) -> String {
        s
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "[", with: "\\[")
            .replacingOccurrences(of: "]", with: "\\]")
            .replacingOccurrences(of: "(", with: "\\(")
            .replacingOccurrences(of: ")", with: "\\)")
    }
}
