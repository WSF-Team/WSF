import Foundation

struct GuideIndexItem: Codable, Identifiable, Hashable {
    var id: String { fileName }
    let fileTitle: String
    let fileName: String

    enum CodingKeys: String, CodingKey {
        case fileTitle = "file_title"
        case fileName = "file_name"
    }
}

struct ParsedGuideContent: Hashable {
    var elements: [GuideElement]
}

enum GuideElement: Identifiable, Hashable {
    case heading(level: Int, text: String, isAccent: Bool)
    case paragraph(content: [InlineContent])
    case codeBlock(language: String?, code: String)
    case image(url: String, altText: String?)
    case link(url: String, text: String)
    case listItem(level: Int, content: [InlineContent])
    case blockquote(content: [InlineContent])

    var id: String {
        switch self {
        case .heading(let level, let text, let isAccent):
            return "h-\(level)-\(isAccent)-\(text)"
        case .paragraph(let content):
            return "p-\(content.map(\.id).joined(separator: "|"))"
        case .codeBlock(let language, let code):
            return "c-\(language ?? "")-\(code.hashValue)"
        case .image(let url, let altText):
            return "i-\(url)-\(altText ?? "")"
        case .link(let url, let text):
            return "l-\(url)-\(text)"
        case .listItem(let level, let content):
            return "li-\(level)-\(content.map(\.id).joined(separator: "|"))"
        case .blockquote(let content):
            return "bq-\(content.map(\.id).joined(separator: "|"))"
        }
    }
}

enum InlineContent: Identifiable, Hashable {
    case text(String)
    case link(url: String, text: String)
    case accentText(String)
    case accentLink(url: String, text: String)

    var id: String {
        switch self {
        case .text(let t): return "t-\(t)"
        case .link(let u, let t): return "ln-\(u)-\(t)"
        case .accentText(let t): return "at-\(t)"
        case .accentLink(let u, let t): return "al-\(u)-\(t)"
        }
    }
}

enum GuideParser {
    static func parse(markdown: String) -> ParsedGuideContent {
        var elements: [GuideElement] = []
        let lines = markdown.components(separatedBy: .newlines)

        var i = 0
        while i < lines.count {
            let line = lines[i]

            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                i += 1
                continue
            }

            if line.hasPrefix("#") {
                if let h = parseHeading(line) { elements.append(h) }
                i += 1
                continue
            }

            if line.hasPrefix("```") {
                let (block, consumed) = parseCodeBlock(lines: lines, startIndex: i)
                if let block {
                    elements.append(block)
                    i += consumed
                    continue
                }
            }

            if line.hasPrefix(">") {
                elements.append(parseBlockquote(line))
                i += 1
                continue
            }

            if isBulletList(line) {
                elements.append(parseListItem(line))
                i += 1
                continue
            }

            if let match = line.range(of: #"^\s*\d+\.\s"#, options: .regularExpression) {
                let level = countLeadingSpaces(line) / 2
                let text = String(line[match.upperBound...])
                elements.append(.listItem(level: level, content: parseInlineContent(text)))
                i += 1
                continue
            }

            if line.trimmingCharacters(in: .whitespaces).hasPrefix("![") {
                if let img = parseImage(line) {
                    elements.append(img)
                    i += 1
                    continue
                }
            }

            let content = parseInlineContent(line)
            if !content.isEmpty {
                elements.append(.paragraph(content: content))
            }
            i += 1
        }

        return ParsedGuideContent(elements: elements)
    }

    private static func isBulletList(_ line: String) -> Bool {
        line.hasPrefix("- ") || line.hasPrefix("* ") || line.hasPrefix("+ ") ||
        line.hasPrefix("  - ") || line.hasPrefix("  * ") || line.hasPrefix("  + ") ||
        line.hasPrefix("    - ") || line.hasPrefix("    * ") || line.hasPrefix("    + ")
    }

    private static func countLeadingSpaces(_ line: String) -> Int {
        var c = 0
        for ch in line {
            if ch == " " { c += 1 } else { break }
        }
        return c
    }

    private static func parseHeading(_ line: String) -> GuideElement? {
        var level = 0
        var text = line
        while text.hasPrefix("#") {
            level += 1
            text = String(text.dropFirst())
        }
        text = text.trimmingCharacters(in: .whitespaces)
        if level <= 0 || text.isEmpty { return nil }

        var isAccent = false

        let accentPattern = #"^\[([^\]]+)\]\(accent://[^\)]*\)$"#
        let bracketOnlyPattern = #"^\[([^\]]+)\]$"#

        if let regex = try? NSRegularExpression(pattern: accentPattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           match.numberOfRanges >= 2,
           let r = Range(match.range(at: 1), in: text) {
            text = String(text[r])
            isAccent = true
        } else if let regex = try? NSRegularExpression(pattern: bracketOnlyPattern),
                  let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
                  match.numberOfRanges >= 2,
                  let r = Range(match.range(at: 1), in: text) {
            text = String(text[r])
        } else if text.hasPrefix("(accent://)") {
            text = String(text.dropFirst("(accent://)".count)).trimmingCharacters(in: .whitespaces)
            isAccent = true
        } else if text.contains("(accent://)") {
            text = text.replacingOccurrences(of: "(accent://)", with: "").trimmingCharacters(in: .whitespaces)
            isAccent = true
        } else if text.contains("accent://") {
            text = text.replacingOccurrences(of: "accent://", with: "").trimmingCharacters(in: .whitespaces)
            isAccent = true
        }

        if text.isEmpty { return nil }
        return .heading(level: level, text: text, isAccent: isAccent)
    }

    private static func parseCodeBlock(lines: [String], startIndex: Int) -> (GuideElement?, Int) {
        let first = lines[startIndex]
        let language = String(first.dropFirst(3).trimmingCharacters(in: .whitespaces))

        var codeLines: [String] = []
        var i = startIndex + 1
        while i < lines.count {
            let l = lines[i]
            if l.hasPrefix("```") {
                let code = codeLines.joined(separator: "\n")
                return (.codeBlock(language: language.isEmpty ? nil : language, code: code), i - startIndex + 1)
            }
            codeLines.append(l)
            i += 1
        }

        let code = codeLines.joined(separator: "\n")
        return (.codeBlock(language: language.isEmpty ? nil : language, code: code), max(1, i - startIndex))
    }

    private static func parseBlockquote(_ line: String) -> GuideElement {
        let t = line.dropFirst().trimmingCharacters(in: .whitespaces)
        return .blockquote(content: parseInlineContent(String(t)))
    }

    private static func parseListItem(_ line: String) -> GuideElement {
        let leadingSpaces = countLeadingSpaces(line)
        let level = leadingSpaces / 2

        var t = line.trimmingCharacters(in: .whitespaces)
        if t.hasPrefix("- ") || t.hasPrefix("* ") || t.hasPrefix("+ ") {
            t = String(t.dropFirst(2))
        }
        return .listItem(level: level, content: parseInlineContent(t))
    }

    private static func parseImage(_ line: String) -> GuideElement? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard let altStart = trimmed.range(of: "!["),
              let altEnd = trimmed.range(of: "](", range: altStart.upperBound..<trimmed.endIndex),
              let urlEnd = trimmed.range(of: ")", range: altEnd.upperBound..<trimmed.endIndex) else {
            return nil
        }

        let altText = String(trimmed[altStart.upperBound..<altEnd.lowerBound])
        var url = String(trimmed[altEnd.upperBound..<urlEnd.lowerBound])
        url = url.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: " ", with: "")
        return .image(url: url, altText: altText.isEmpty ? nil : altText)
    }

    private static func findMatchingBracket(in text: String, start: String.Index) -> String.Index? {
        var depth = 0
        var i = start
        while i < text.endIndex {
            if text[i] == "[" { depth += 1 }
            else if text[i] == "]" {
                depth -= 1
                if depth == 0 { return i }
            }
            i = text.index(after: i)
        }
        return nil
    }

    private static func parseInlineContent(_ text: String) -> [InlineContent] {
        var result: [InlineContent] = []
        var current = ""
        var i = text.startIndex

        while i < text.endIndex {
            if text[i] == "(" {
                let after = text.index(after: i)
                let check = String(text[after...])
                if check.hasPrefix("accent://"),
                   let close = text.range(of: ")", range: after..<text.endIndex) {
                    if !current.isEmpty {
                        result.append(.text(current))
                        current = ""
                    }
                    i = close.upperBound
                    continue
                }
            }

            if text[i] == "[" {
                if !current.isEmpty {
                    result.append(.text(current))
                    current = ""
                }

                if let closeBracket = findMatchingBracket(in: text, start: i),
                   closeBracket < text.endIndex,
                   text[closeBracket] == "]" {

                    let next = text.index(after: closeBracket)
                    if next < text.endIndex, text[next] == "(",
                       let closeParen = text.range(of: ")", range: next..<text.endIndex) {

                        let linkText = String(text[text.index(after: i)..<closeBracket])
                        let urlStart = text.index(after: next)
                        var url = String(text[urlStart..<closeParen.lowerBound]).trimmingCharacters(in: .whitespaces)
                        url = url.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "")

                        if url.hasPrefix("accent://") {
                            result.append(.accentLink(url: url, text: linkText))
                        } else {
                            result.append(.link(url: url, text: linkText))
                        }

                        i = closeParen.upperBound
                        continue
                    }
                }

                current.append(text[i])
                i = text.index(after: i)
                continue
            }

            current.append(text[i])
            i = text.index(after: i)
        }

        if !current.isEmpty {
            var remaining = current

            while let marker = remaining.range(of: "(accent://)") {
                let before = String(remaining[..<marker.lowerBound])
                if !before.isEmpty { result.append(.text(before)) }

                let afterMarker = marker.upperBound
                var end = afterMarker
                while end < remaining.endIndex {
                    if remaining[end].isWhitespace { break }
                    end = remaining.index(after: end)
                }

                let accentText = String(remaining[afterMarker..<end])
                if !accentText.isEmpty { result.append(.accentText(accentText)) }

                if end < remaining.endIndex {
                    remaining = String(remaining[end...])
                } else {
                    remaining = ""
                    break
                }
            }

            while let r = remaining.range(of: "accent://") {
                let before = String(remaining[..<r.lowerBound])
                if !before.isEmpty { result.append(.text(before)) }

                let after = r.upperBound
                var end = after
                while end < remaining.endIndex {
                    let ch = remaining[end]
                    if ch.isWhitespace || ch.isPunctuation { break }
                    end = remaining.index(after: end)
                }

                let accentText = String(remaining[after..<end])
                if !accentText.isEmpty { result.append(.accentText(accentText)) }

                if end < remaining.endIndex {
                    remaining = String(remaining[end...])
                } else {
                    remaining = ""
                    break
                }
            }

            if !remaining.isEmpty { result.append(.text(remaining)) }
        }

        return result.isEmpty ? [.text(text)] : result
    }
}
