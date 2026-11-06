// SPDX-License-Identifier: AGPL-3.0-only
import Foundation
import Observation
/// Ephemeral developer entry, independent of music data and reusable across UI surfaces.
@MainActor @Observable public final class DeveloperAccess {
    private var taps = 0
    public private(set) var lastInteraction: Date?
    public init() {}
    public func enabled(at now: Date = Date()) -> Bool { lastInteraction.map { now.timeIntervalSince($0) < 30 } ?? false }
    public func tapVersion(at now: Date = Date()) {
        taps += 1
        if taps >= 3 { taps = 0; lastInteraction = now }
    }
    public func interact(at now: Date = Date()) { if enabled(at: now) { lastInteraction = now } }
    public func expire(at now: Date = Date()) { if !enabled(at: now) { reset() } }
    public func reset() { taps = 0; lastInteraction = nil }
}
