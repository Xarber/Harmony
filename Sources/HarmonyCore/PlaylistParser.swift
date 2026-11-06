// SPDX-License-Identifier: AGPL-3.0-only
import Foundation
#if canImport(FoundationXML)
import FoundationXML
#endif

public enum PlaylistFormat: String, CaseIterable, Sendable { case m3u, m3u8, pls, csv, json, xspf, text }
public enum PlaylistParser {
    public static func parse(_ data: Data, format: PlaylistFormat, name: String) throws -> Playlist {
        guard data.count <= 10_000_000 else { throw HarmonyError.invalid("Playlist exceeds the 10 MB limit.") }
        guard let text = String(data: data, encoding: .utf8) else { throw HarmonyError.invalid("Use a UTF-8 playlist file.") }
        if format == .json {
            let value = try JSONDecoder().decode(Playlist.self, from: data)
            guard value.entries.count <= 100_000, Set(value.entries.map(\.id)).count == value.entries.count,
                  value.entries.allSatisfy({ !$0.title.isEmpty && ($0.duration == nil || ($0.duration!.isFinite && $0.duration! >= 0)) }) else {
                throw HarmonyError.invalid("Invalid playlist entries or duplicate entry identifiers.")
            }
            return value
        }
        if format == .xspf {
            guard !text.uppercased().contains("<!DOCTYPE"), !text.uppercased().contains("<!ENTITY") else { throw HarmonyError.invalid("XML entities are not allowed.") }
            let delegate = XSPFReader(); let parser = XMLParser(data: data)
            parser.shouldResolveExternalEntities = false; parser.delegate = delegate
            guard parser.parse() else { throw HarmonyError.invalid("Invalid XSPF playlist.") }
            return Playlist(name: name, entries: delegate.entries)
        }
        if text.contains("#EXT-X-") { throw HarmonyError.unsupported("HLS streaming manifests are not local playlists.") }
        let lines = text.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        var entries: [PlaylistEntry] = []
        switch format {
        case .m3u, .m3u8:
            var pending: PlaylistEntry?
            for line in lines where !line.isEmpty {
                if line.hasPrefix("#EXTINF:") {
                    let pieces = line.dropFirst(8).split(separator: ",", maxSplits: 1, omittingEmptySubsequences: false)
                    pending = entry(String(pieces.last ?? ""))
                    if let raw = pieces.first, let duration = Double(raw), duration >= 0 { pending?.duration = duration }
                } else if !line.hasPrefix("#") {
                    var item = pending ?? PlaylistEntry(title: URL(fileURLWithPath: line).deletingPathExtension().lastPathComponent)
                    item.sourcePath = line; entries.append(item); pending = nil
                }
            }
        case .pls:
            var values: [Int: [String: String]] = [:]
            let regex = try NSRegularExpression(pattern: #"^(File|Title|Length)(\d+)=(.*)$"#, options: .caseInsensitive)
            for line in lines {
                guard let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) else { continue }
                func part(_ i: Int) -> String { Range(match.range(at: i), in: line).map { String(line[$0]) } ?? "" }
                if let index = Int(part(2)) { values[index, default: [:]][part(1).lowercased()] = part(3) }
            }
            entries = values.keys.sorted().compactMap { index in
                guard let row = values[index], let file = row["file"] else { return nil }
                var item = entry(row["title"] ?? URL(fileURLWithPath: file).deletingPathExtension().lastPathComponent)
                item.sourcePath = file; item.duration = row["length"].flatMap(Double.init).flatMap { $0 >= 0 ? $0 : nil }; return item
            }
        case .csv:
            let rows = try csvRows(text)
            guard let header = rows.first else { break }
            let keys = header.map { $0.lowercased().trimmingCharacters(in: .whitespaces) }
            guard keys.contains("title") else { throw HarmonyError.invalid("CSV must contain a title column; artist and duration are optional.") }
            for row in rows.dropFirst() where row.contains(where: { !$0.isEmpty }) {
                func field(_ key: String) -> String? { keys.firstIndex(of: key).flatMap { row.indices.contains($0) ? row[$0] : nil } }
                guard let title = field("title"), !title.isEmpty else { continue }
                entries.append(PlaylistEntry(title: title, artist: field("artist"), duration: field("duration").flatMap(Double.init), sourcePath: field("path")))
            }
        case .text: entries = lines.filter { !$0.isEmpty }.map(entry)
        default: break
        }
        guard entries.count <= 100_000 else { throw HarmonyError.invalid("Too many playlist items.") }
        return Playlist(name: name, entries: entries)
    }
    private static func entry(_ line: String) -> PlaylistEntry {
        for separator in [" — ", " – ", " - "] {
            if let range = line.range(of: separator) { return PlaylistEntry(title: String(line[range.upperBound...]), artist: String(line[..<range.lowerBound])) }
        }
        return PlaylistEntry(title: line)
    }
    private static func csvRows(_ text: String) throws -> [[String]] {
        var rows: [[String]] = []; var row: [String] = []; var field = ""; var quoted = false
        let chars = Array(text); var i = 0
        while i < chars.count {
            let c = chars[i]
            if c == "\"" {
                if quoted && i + 1 < chars.count && chars[i + 1] == "\"" { field.append("\""); i += 1 }
                else { quoted.toggle() }
            } else if c == "," && !quoted { row.append(field); field = "" }
            else if (c == "\n" || c == "\r\n" || c == "\r") && !quoted { row.append(field); rows.append(row); row = []; field = "" }
            else { field.append(c) }
            i += 1
        }
        guard !quoted else { throw HarmonyError.invalid("Unclosed CSV quotation.") }
        if !field.isEmpty || !row.isEmpty { row.append(field); rows.append(row) }; return rows
    }
    public static func export(_ playlist: Playlist, format: PlaylistFormat) throws -> Data {
        func clean(_ text: String) -> String { text.replacingOccurrences(of: "\n", with: " ").replacingOccurrences(of: "\r", with: " ") }
        func csv(_ text: String) -> String { "\"" + text.replacingOccurrences(of: "\"", with: "\"\"") + "\"" }
        func xml(_ text: String) -> String { text.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "<", with: "&lt;").replacingOccurrences(of: ">", with: "&gt;").replacingOccurrences(of: "\"", with: "&quot;") }
        let text: String
        switch format {
        case .json: return try JSONEncoder().encode(playlist)
        case .csv: text = "title,artist,duration,path\n" + playlist.entries.map { [csv($0.title), csv($0.artist ?? ""), $0.duration.map(String.init(describing:)) ?? "", csv($0.sourcePath ?? "")].joined(separator: ",") }.joined(separator: "\n")
        case .m3u, .m3u8: text = "#EXTM3U\n" + playlist.entries.map { "#EXTINF:\(Int($0.duration ?? -1)),\(clean($0.artist ?? "")) - \(clean($0.title))\n\(clean($0.sourcePath ?? "harmony-missing:\($0.id)"))" }.joined(separator: "\n")
        case .xspf: text = "<?xml version=\"1.0\"?><playlist version=\"1\" xmlns=\"http://xspf.org/ns/0/\"><title>\(xml(playlist.name))</title><trackList>" + playlist.entries.map { "<track><title>\(xml($0.title))</title><creator>\(xml($0.artist ?? ""))</creator><location>\(xml($0.sourcePath ?? ""))</location></track>" }.joined() + "</trackList></playlist>"
        case .pls: text = "[playlist]\n" + playlist.entries.enumerated().map { "File\($0.offset + 1)=\(clean($0.element.sourcePath ?? "harmony-missing:\($0.element.id)"))\nTitle\($0.offset + 1)=\(clean($0.element.title))" }.joined(separator: "\n") + "\nNumberOfEntries=\(playlist.entries.count)\nVersion=2"
        case .text: text = playlist.entries.map { "\($0.artist ?? "") — \($0.title)" }.joined(separator: "\n")
        }
        return Data(text.utf8)
    }
}
private final class XSPFReader: NSObject, XMLParserDelegate {
    var entries: [PlaylistEntry] = []; private var current: PlaylistEntry?; private var text = ""
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String]) {
        text = ""; if elementName == "track" { current = PlaylistEntry(title: "Unknown title") }
    }
    func parser(_ parser: XMLParser, foundCharacters string: String) { text += string }
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        switch elementName {
        case "title": current?.title = text
        case "creator": current?.artist = text
        case "location": current?.sourcePath = text
        case "duration": current?.duration = Double(text).map { $0 / 1000 }
        case "track": if let current { entries.append(current) }; current = nil
        default: break
        }; text = ""
    }
}
