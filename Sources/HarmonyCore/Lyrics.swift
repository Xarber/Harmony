// SPDX-License-Identifier: AGPL-3.0-only
import Foundation

public enum LRC {
    public static func parse(_ text: String) -> [LyricLine] {
        let pattern = #"\[(\d{1,3}):(\d{2})(?:[.:](\d{1,3}))?\]"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let offsetRegex = try? NSRegularExpression(pattern: #"\[offset:([+-]?\d+)\]"#, options: .caseInsensitive)
        var offset: Double = 0
        if let match = offsetRegex?.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)), let range = Range(match.range(at: 1), in: text) {
            offset = (Double(text[range]) ?? 0) / 1000
        }
        var timed: [LyricLine] = []; var plain: [LyricLine] = []
        for raw in text.components(separatedBy: .newlines) {
            let line = raw.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty else { continue }
            let matches = regex.matches(in: line, range: NSRange(line.startIndex..., in: line))
            if matches.isEmpty {
                if !line.hasPrefix("[") { plain.append(LyricLine(time: nil, text: line)) }; continue
            }
            guard let last = matches.last, let end = Range(last.range, in: line)?.upperBound else { continue }
            let content = String(line[end...]).trimmingCharacters(in: .whitespaces)
            for match in matches {
                func value(_ i: Int) -> String { Range(match.range(at: i), in: line).map { String(line[$0]) } ?? "" }
                guard let minutes = Double(value(1)), let seconds = Double(value(2)), seconds < 60 else { continue }
                let fraction = value(3)
                let time = minutes * 60 + seconds + (fraction.isEmpty ? 0 : (Double("0." + fraction) ?? 0)) + offset
                timed.append(LyricLine(time: max(0, time), text: content))
            }
        }
        return timed.isEmpty ? plain : timed.enumerated().sorted { a, b in
            a.element.time == b.element.time ? a.offset < b.offset : (a.element.time ?? 0) < (b.element.time ?? 0)
        }.map(\.element)
    }
    public static func export(_ lines: [LyricLine]) -> String {
        lines.map { line in
            guard let time = line.time else { return line.text }
            let ticks = Int((max(0, time) * 100).rounded())
            return String(format: "[%02d:%02d.%02d]", ticks / 6000, (ticks / 100) % 60, ticks % 100) + line.text
        }.joined(separator: "\n")
    }
}
