// SPDX-License-Identifier: AGPL-3.0-only
import Testing
import Foundation
import AVFoundation
@testable import HarmonyCore

private func temporary() throws -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("HarmonyTests-\(UUID())")
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true); return url
}
/// Original synthesized tone, generated for this suite. No third-party music or lyrics.
private func tone(_ root: URL, duration: Double = 2) throws -> URL {
    let url = root.appendingPathComponent("Original test tone.wav")
    let format = try #require(AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1))
    let buffer = try #require(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(44100 * duration)))
    buffer.frameLength = buffer.frameCapacity
    let channel = try #require(buffer.floatChannelData?[0])
    for index in 0..<Int(buffer.frameLength) { channel[index] = Float(sin(Double(index) * 2 * .pi * 440 / 44100) * 0.03) }
    let file = try AVAudioFile(forWriting: url, settings: format.settings); try file.write(from: buffer); return url
}
@Suite struct PlaylistTests {
    @Test func m3uPreservesOrderAndRepeatedOccurrences() throws {
        let text = "#EXTM3U\n#EXTINF:123,Artist — First\nfirst.mp3\n#EXTINF:123,Artist — First\nfirst.mp3\nother.mp3"
        let playlist = try PlaylistParser.parse(Data(text.utf8), format: .m3u8, name: "Mix")
        #expect(playlist.entries.count == 3)
        #expect(playlist.entries[0].title == "First")
        #expect(playlist.entries[0].id != playlist.entries[1].id)
        #expect(playlist.entries[2].sourcePath == "other.mp3")
    }
    @Test func rejectHLSAndEntities() {
        #expect(throws: (any Error).self) { try PlaylistParser.parse(Data("#EXTM3U\n#EXT-X-TARGETDURATION:10".utf8), format: .m3u8, name: "HLS") }
        #expect(throws: (any Error).self) { try PlaylistParser.parse(Data("<!DOCTYPE x [<!ENTITY test SYSTEM 'file:///etc/passwd'>]><playlist/>".utf8), format: .xspf, name: "Unsafe") }
    }
    @Test func csvSupportsQuotesCommasAndNewlines() throws {
        let text = "title,artist,duration\r\n\"Title, with comma\",\"Artist \"\"One\"\"\",25\r\n\"Line\nbreak\",B,30"
        let result = try PlaylistParser.parse(Data(text.utf8), format: .csv, name: "CSV")
        #expect(result.entries.count == 2)
        #expect(result.entries[0].title == "Title, with comma")
        #expect(result.entries[0].artist == "Artist \"One\"")
        #expect(result.entries[1].title == "Line\nbreak")
    }
    @Test func xspfAndPLS() throws {
        let xspf = "<playlist><trackList><track><title>First &amp; Last</title><creator>A</creator><duration>2500</duration><location>../file.mp3</location></track></trackList></playlist>"
        let playlist = try PlaylistParser.parse(Data(xspf.utf8), format: .xspf, name: "X")
        #expect(playlist.entries[0].duration == 2.5)
        #expect(playlist.entries[0].title == "First & Last")
        let pls = try PlaylistParser.parse(Data("[playlist]\nFile2=b.mp3\nTitle2=B\nFile1=a.mp3\nTitle1=A".utf8), format: .pls, name: "PLS")
        #expect(pls.entries.map(\.title) == ["A", "B"])
    }
    @Test(arguments: [PlaylistFormat.json, .csv, .xspf, .m3u8]) func exportRoundTrip(_ format: PlaylistFormat) throws {
        let playlist = Playlist(name: "Original", entries: [PlaylistEntry(title: "A & B", artist: "Artist", sourcePath: "audio.mp3")])
        let data = try PlaylistParser.export(playlist, format: format)
        let restored = try PlaylistParser.parse(data, format: format, name: "Restored")
        #expect(restored.entries.count == 1)
        #expect(restored.entries[0].title == playlist.entries[0].title)
    }
    @Test func plainTrackList() throws {
        let result = try PlaylistParser.parse(Data("Artist — Song\nArtist - Another".utf8), format: .text, name: "Pasted")
        #expect(result.entries.map(\.title) == ["Song", "Another"])
    }
}
@Suite struct LyricsAndMatchingTests {
    @Test func lrcRepeatedTimestampsOffsetAndFractions() {
        let lines = LRC.parse("[ar:Test]\n[offset:+500]\n[00:02.5][00:04.050]Original words\n[00:01.00]First line")
        #expect(lines.count == 3)
        #expect(lines.map(\.time) == [1.5, 3, 4.55])
        let doc = LyricsDocument(raw: "[00:01.00]One\n[00:02.00]Two", offset: 0.5)
        #expect(doc.activeIndex(at: 0) == nil)
        #expect(doc.activeIndex(at: 1.49) == nil)
        #expect(doc.activeIndex(at: 1.5) == 0)
        #expect(doc.activeIndex(at: 8) == 1)
    }
    @Test func invalidTimestampsAndPlainLyrics() {
        #expect(LRC.parse("[00:99.00]Invalid").isEmpty)
        #expect(LRC.parse("Original line\nAnother original line").allSatisfy { $0.time == nil })
        let lines = [LyricLine(time: 61.25, text: "Original words")]
        #expect(LRC.parse(LRC.export(lines))[0].time == 61.25)
    }
    @Test func titleAloneNeverExactAndVersionsStayDistinct() throws {
        let tracks = [Track(title: "Song", artist: "Artist", duration: 120), Track(title: "Song (Live)", artist: "Artist", duration: 120)]
        let matches = TrackMatcher.candidates(for: PlaylistEntry(title: "song"), in: tracks)
        #expect(matches.count == 1); #expect(matches[0].confidence == 0.35); #expect(!matches[0].exact)
        #expect(TrackMatcher.normalized("Café!") == "cafe")
        var exact = tracks[0]; exact.isrc = "ABC123"
        var entry = PlaylistEntry(title: "Song", duration: 120); entry.isrc = "ABC123"
        #expect(try #require(TrackMatcher.candidates(for: entry, in: [exact]).first).exact)
        entry.duration = 180
        #expect(!TrackMatcher.candidates(for: entry, in: [exact])[0].exact)
    }
    @Test func queueRepeatShuffleAndDuplicateItems() {
        let first = UUID(), second = UUID(); var queue = PlaybackQueue()
        queue.replace([first, first, second]); #expect(queue.items[0].id != queue.items[1].id)
        let advanced = queue.next(); #expect(advanced); #expect(queue.index == 1)
        queue.repeatMode = .one; let repeated = queue.next(automatic: true); #expect(repeated); #expect(queue.index == 1)
        queue.move(from: 1, to: 2); #expect(queue.index == 2); #expect(queue.current == first)
        queue.repeatMode = .all; let wrapped = queue.next(); #expect(wrapped); #expect(queue.index == 0)
        queue.shuffle = true; let shuffled = queue.next(); #expect(shuffled); #expect(queue.index != 0)
        let current = queue.items[queue.index].id; queue.remove(current); #expect(queue.items.count == 2)
        queue.replace([]); #expect(queue.current == nil); let emptyAdvanced = queue.next(); #expect(!emptyAdvanced)
    }
}
@Suite struct LibraryIntegrationTests {
    @Test func realAudioImportDuplicatesPersistenceAndExport() async throws {
        let root = try temporary(); defer { try? FileManager.default.removeItem(at: root) }
        let source = try tone(root); let libraryRoot = root.appendingPathComponent("Library")
        let store = try LibraryStore(root: libraryRoot)
        let imported = try await store.importAudio(source)
        #expect(!imported.duplicate); #expect(abs((imported.track.duration ?? 0) - 2) < 0.01)
        let duplicate = try await store.importAudio(source); #expect(duplicate.duplicate); #expect(duplicate.track.id == imported.track.id)
        #expect(try await store.count() == 1)
        #expect(FileManager.default.fileExists(atPath: source.path))
        let url = try #require(await store.audioURL(for: imported.track.id))
        #expect(url != source)
        #expect(try LibraryStore.digest(url) == LibraryStore.digest(source))
        let exported = try await store.exportAudio(imported.track.id)
        #expect(try LibraryStore.digest(exported) == LibraryStore.digest(source))
        let reopened = try LibraryStore(root: libraryRoot)
        #expect(try await reopened.count() == 1)
        var edited = imported.track; edited.artist = "Original test artist"; edited.album = "Generated fixtures"; edited.title = "Changed"
        try await reopened.update(edited)
        #expect(try await reopened.tracks(search: "Generated").count == 1)
        #expect(try await reopened.tracks(search: "%").isEmpty)
        #expect(try LibraryStore.digest(url) == LibraryStore.digest(source))
    }
    @Test func pathsAndInvalidMediaRejected() async throws {
        let root = try temporary(); defer { try? FileManager.default.removeItem(at: root) }
        let store = try LibraryStore(root: root.appendingPathComponent("Library"))
        do { _ = try await store.managedURL("../private.txt"); Issue.record("Traversal accepted") } catch {}
        let invalid = root.appendingPathComponent("invalid.mp3"); try Data("not audio".utf8).write(to: invalid)
        do { _ = try await store.importAudio(invalid); Issue.record("Invalid audio accepted") } catch {}
        #expect(try await store.count() == 0)
        #expect(FileManager.default.fileExists(atPath: invalid.path))
    }
    @Test func metadataBackupRestoreKeepsExistingRecordsAndMissingAudio() async throws {
        let root = try temporary(); defer { try? FileManager.default.removeItem(at: root) }
        let store = try LibraryStore(root: root.appendingPathComponent("One"))
        let track = try await store.importAudio(tone(root)).track
        let playlist = Playlist(name: "Repeated", entries: [PlaylistEntry(title: track.title, trackID: track.id), PlaylistEntry(title: track.title, trackID: track.id)])
        try await store.save(playlist)
        let data = try await store.exportMetadata()
        let restored = try LibraryStore(root: root.appendingPathComponent("Two"))
        #expect(try await restored.restoreMetadata(data) == 1)
        #expect(try await restored.restoreMetadata(data) == 0)
        #expect(try await restored.audioURL(for: track.id) == nil)
        #expect(try await restored.playlists()[0].entries.count == 2)
    }
    @Test func ideasMergeAndLyricsRevisionPersistence() async throws {
        let root = try temporary(); defer { try? FileManager.default.removeItem(at: root) }
        let store = try LibraryStore(root: root.appendingPathComponent("Library"))
        let idea = Idea(title: "Original idea")
        try await store.saveIdea(idea)
        var changed = idea; changed.title = "Conflicting imported title"
        #expect(try await store.importIdeas(IdeasExport(ideas: [changed, Idea(title: "Second")] )) == 1)
        #expect(try await store.ideas().contains { $0.title == "Original idea" })
        let track = try await store.importAudio(tone(root)).track
        try await store.saveLyrics(LyricsDocument(raw: "[00:01.0]Original line"), for: track.id)
        try await store.saveLyrics(LyricsDocument(raw: "[00:01.5]Revised original line"), for: track.id)
        #expect(try await store.lyrics(for: track.id)?.activeIndex(at: 1.5) == 0)
    }
    @Test @MainActor func actualPlayerClockPauseSeekAndRestoration() async throws {
        let root = try temporary(); defer { try? FileManager.default.removeItem(at: root) }
        let store = try LibraryStore(root: root.appendingPathComponent("Library"))
        let track = try await store.importAudio(tone(root, duration: 4)).track
        let player = PlaybackController(store: store); defer { player.shutdown() }
        await player.start([track])
        // Runtime playback, not just construction or compilation. Very quiet synthesized tone.
        for _ in 0..<30 { if player.position > 0.25 { break }; try await Task.sleep(for: .milliseconds(100)) }
        #expect(player.isPlaying); #expect(player.position > 0.25)
        player.pause(); let paused = player.position; try await Task.sleep(for: .milliseconds(300))
        #expect(!player.isPlaying); #expect(abs(player.position - paused) < 0.25)
        player.seek(to: 2); try await Task.sleep(for: .milliseconds(300)); #expect(abs(player.position - 2) < 0.25)
        player.play(); try await Task.sleep(for: .milliseconds(400)); #expect(player.position > 2)
        player.pause(); try await Task.sleep(for: .milliseconds(200))
        let restored = PlaybackController(store: store); defer { restored.shutdown() }; await restored.restore()
        #expect(restored.currentTrack?.id == track.id); #expect(!restored.isPlaying); #expect(restored.position > 2)
    }
}
