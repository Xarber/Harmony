// SPDX-License-Identifier: AGPL-3.0-only
import Foundation
public enum RepeatMode: String, Codable, CaseIterable, Sendable { case off, all, one }
public struct QueueItem: Identifiable, Codable, Hashable, Sendable {
    public var id = UUID()
    public var trackID: UUID
    public init(trackID: UUID) { self.trackID = trackID }
}
public struct PlaybackQueue: Codable, Sendable {
    public var items: [QueueItem] = []
    public var index: Int = 0
    public var repeatMode: RepeatMode = .off
    public var shuffle = false
    public var position: Double = 0
    public init() {}
    public var current: UUID? { items.indices.contains(index) ? items[index].trackID : nil }
    public mutating func replace(_ ids: [UUID], start: Int = 0) { items = ids.map { QueueItem(trackID: $0) }; index = max(0, min(start, items.count - 1)); position = 0 }
    public mutating func next(automatic: Bool = false) -> Bool {
        position = 0
        guard !items.isEmpty else { return false }
        if automatic && repeatMode == .one { return true }
        if shuffle && items.count > 1 {
            let others = items.indices.filter { $0 != index }; index = others.randomElement() ?? index; return true
        }
        if index + 1 < items.count { index += 1; return true }
        if repeatMode == .all { index = 0; return true }; return false
    }
    public mutating func previous() { position = 0; if index > 0 { index -= 1 } else if repeatMode == .all && !items.isEmpty { index = items.count - 1 } }
    public mutating func append(_ id: UUID, next: Bool = false) { items.insert(QueueItem(trackID: id), at: next ? min(index + 1, items.count) : items.count) }
    public mutating func remove(_ id: UUID) {
        guard let at = items.firstIndex(where: { $0.id == id }) else { return }
        items.remove(at: at)
        if at < index { index -= 1 }; index = min(index, max(0, items.count - 1))
    }
    public mutating func move(from: Int, to: Int) {
        guard items.indices.contains(from), to >= 0, to < items.count else { return }
        let playingID = items.indices.contains(index) ? items[index].id : nil
        let value = items.remove(at: from); items.insert(value, at: to)
        if let playingID, let current = items.firstIndex(where: { $0.id == playingID }) { index = current }
    }
}
