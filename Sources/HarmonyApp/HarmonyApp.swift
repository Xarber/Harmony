// SPDX-License-Identifier: AGPL-3.0-only
import SwiftUI
import HarmonyCore
import UniformTypeIdentifiers

@main struct HarmonyApp: App {
    @State private var model = AppModel()
    var body: some Scene {
        WindowGroup {
            Group {
                if model.store != nil { RootView(model: model) }
                else { ContentUnavailableView("Library unavailable", systemImage: "externaldrive.badge.exclamationmark", description: Text(model.error ?? "Harmony could not open its storage.")) }
            }
            .tint(.harmony).task { await model.reload(); await model.player?.restore() }
            .onOpenURL { url in model.importFiles([url]) }
            .alert("Harmony", isPresented: Binding(get: { model.error != nil }, set: { if !$0 { model.error = nil } })) { Button("OK") { model.error = nil } } message: { Text(model.error ?? "") }
            .preferredColorScheme(model.appearance == "dark" ? .dark : model.appearance == "light" ? .light : nil)
        }
        #if os(macOS)
        .defaultSize(width: 1120, height: 780)
        #endif
    }
}
extension Color { static let harmony = Color(red: 98/255, green: 105/255, blue: 245/255) }

struct ExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json, .plainText, .data] }
    var data: Data
    init(data: Data = Data()) { self.data = data }
    init(configuration: ReadConfiguration) throws { data = configuration.file.regularFileContents ?? Data() }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}

@MainActor @Observable final class AppModel {
    let isQA = CommandLine.arguments.contains("--qa-library")
    let store: LibraryStore?
    let player: PlaybackController?
    var tracks: [Track] = []
    var playlists: [Playlist] = []
    var ideas: [Idea] = []
    var error: String?
    var importing = false
    var importProgress = 0.0
    var importMessage = ""
    var importTask: Task<Void, Never>?
    var appearance = UserDefaults.standard.string(forKey: "appearance") ?? "system" { didSet { UserDefaults.standard.set(appearance, forKey: "appearance") } }
    var preview: Playlist?
    var artwork: [UUID: URL] = [:]
    var files: [UUID: [AudioFile]] = [:]
    var exportDocument: ExportDocument?
    var exportName = "Harmony"
    var exportType: UTType = .json
    var showingExport = false
    init() {
        do {
            var root = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("Harmony", isDirectory: true)
            #if DEBUG
            if let flag = CommandLine.arguments.firstIndex(of: "--qa-library"), CommandLine.arguments.indices.contains(flag + 1) {
                root = URL(fileURLWithPath: CommandLine.arguments[flag + 1], isDirectory: true)
            }
            #endif
            let store = try LibraryStore(root: root); self.store = store; player = PlaybackController(store: store)
        } catch { store = nil; player = nil; self.error = error.localizedDescription }
    }
    func perform(_ body: @escaping () async throws -> Void) {
        Task { do { try await body(); await reload() } catch { self.error = error.localizedDescription } }
    }
    func reload() async {
        guard let store else { return }
        do {
            tracks = try await store.tracks(limit: 100_000); playlists = try await store.playlists(); ideas = try await store.ideas()
            var art: [UUID: URL] = [:]; var audio: [UUID: [AudioFile]] = [:]
            for track in tracks {
                art[track.id] = try await store.artworkURL(for: track); audio[track.id] = try await store.files(for: track.id)
            }
            artwork = art; files = audio
        } catch { self.error = error.localizedDescription }
    }
    func importFiles(_ urls: [URL]) {
        guard let store, !importing else { return }; importing = true; importProgress = 0
        importTask = Task {
            var failures: [String] = []; var added = 0; var duplicates = 0
            for (index, url) in urls.enumerated() {
                if Task.isCancelled { break }
                importMessage = url.lastPathComponent
                do {
                    let ext = url.pathExtension.lowercased()
                    if let format = PlaylistFormat(rawValue: ext) {
                        let access = url.startAccessingSecurityScopedResource(); defer { if access { url.stopAccessingSecurityScopedResource() } }
                        guard urls.count == 1 else { throw HarmonyError.invalid("Import playlist files individually to review their matches.") }
                        preview = try PlaylistParser.parse(Data(contentsOf: url), format: format, name: url.deletingPathExtension().lastPathComponent)
                    } else {
                        let result = try await store.importAudio(url)
                        if result.duplicate { duplicates += 1 } else { added += 1 }
                    }
                } catch is CancellationError { break }
                catch { failures.append("\(url.lastPathComponent): \(error.localizedDescription)") }
                importProgress = Double(index + 1) / Double(max(1, urls.count))
            }
            importMessage = "\(added) imported · \(duplicates) duplicates"; importing = false; importTask = nil
            await reload()
            if !failures.isEmpty { error = failures.joined(separator: "\n") }
        }
    }
    func export(_ data: Data, name: String, type: UTType = .json) { exportDocument = ExportDocument(data: data); exportName = name; exportType = type; showingExport = true }
    func favorite(_ track: Track) {
        perform { guard let store = self.store else { return }; var changed = track; changed.favorite.toggle(); try await store.update(changed) }
    }
    func exportPlaylist(_ playlist: Playlist, format: PlaylistFormat) {
        do {
            var copy = playlist
            for index in copy.entries.indices {
                if let id = copy.entries[index].trackID, let file = files[id]?.first { copy.entries[index].sourcePath = file.relativePath }
            }
            export(try PlaylistParser.export(copy, format: format), name: "\(playlist.name).\(format.rawValue)", type: format == .json ? .json : .plainText)
        } catch { self.error = error.localizedDescription }
    }
}
