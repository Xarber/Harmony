// SPDX-License-Identifier: AGPL-3.0-only
import SwiftUI
import HarmonyCore
import UniformTypeIdentifiers

struct SettingsView: View {
    @Bindable var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var phase
    @State private var access = DeveloperAccess()
    @State private var importingBackup = false
    var body: some View {
        Form {
            Section("Your library") {
                LabeledContent("Tracks", value: model.tracks.count.formatted())
                LabeledContent("Audio storage", value: ByteCountFormatter.string(fromByteCount: model.files.values.flatMap { $0 }.reduce(0) { $0 + $1.byteCount }, countStyle: .file))
                Button("Export library metadata", systemImage: "square.and.arrow.up") { model.perform { guard let data = try await model.store?.exportMetadata() else { return }; model.export(data, name: "Harmony-library.json") } }
                Button("Restore library metadata", systemImage: "square.and.arrow.down") { importingBackup = true }
                Text("Metadata backups contain tracks and playlists. Audio files, artwork, lyrics and credentials are excluded. Export audio individually from a song’s menu.").font(.caption).foregroundStyle(.secondary)
            }
            Section("Appearance") { Picker("Theme", selection: $model.appearance) { Text("System").tag("system"); Text("Light").tag("light"); Text("Dark").tag("dark") } }
            Section("Privacy & integrations") {
                Label("No accounts or listening analytics", systemImage: "lock.shield")
                DisclosureGroup("External services") { Text("MusicBrainz searches run only when you tap Search in Metadata Studio. Direct downloads run only for URLs you explicitly authorize. Spotify, MusicKit, fingerprinting and hosted synchronization are not connected in this version.") }
                Button("Clear listening history") { model.perform { try await model.store?.clearHistory() } }
            }
            Section("About Harmony") {
                NavigationLink { ChangelogView() } label: { Label("What’s New", systemImage: "sparkles") }
                HStack { Text("Version"); Spacer(); Button("0.1.0 (1)") { access.tapVersion() }.buttonStyle(.plain).accessibilityHint("Tap three times for developer options") }
                Text("Your music. In perfect harmony.\nOpenRecode · AGPL-3.0-only").font(.footnote).foregroundStyle(.secondary)
            }
            if access.enabled() {
                Section("Developer options") {
                    NavigationLink { IdeasView(model: model) } label: { Label("Ideas", systemImage: "lightbulb") }
                    LabeledContent("Database schema", value: "1")
                    LabeledContent("Audio engine", value: "AVPlayer")
                    LabeledContent("Runtime", value: "\(ProcessInfo.processInfo.operatingSystemVersionString)")
                    LabeledContent("Build commit", value: Bundle.main.object(forInfoDictionaryKey: "HarmonyCommit") as? String ?? "development / unbundled")
                    Text("\(model.tracks.count) tracks · \(model.playlists.count) playlists · \(model.ideas.count) ideas").font(.caption)
                }
            }
        }.navigationTitle("Settings").toolbar { Button("Done") { dismiss() } }
        .onChange(of: phase) { _, value in if value == .active { access.expire() } }
        .onDisappear { access.reset() }
        .simultaneousGesture(TapGesture().onEnded { access.interact() })
        .task(id: access.lastInteraction) { guard access.lastInteraction != nil else { return }; try? await Task.sleep(for: .seconds(30)); if !Task.isCancelled { access.expire() } }
        .fileImporter(isPresented: $importingBackup, allowedContentTypes: [.json]) { result in
            do {
                let url = try result.get(); let access = url.startAccessingSecurityScopedResource(); defer { if access { url.stopAccessingSecurityScopedResource() } }
                let data = try Data(contentsOf: url); guard data.count < 50_000_000 else { throw HarmonyError.invalid("Backup exceeds 50 MB.") }
                model.perform { let added = try await model.store?.restoreMetadata(data) ?? 0; model.error = "Restored \(added) missing metadata records. Existing records were preserved. Import the corresponding audio files to listen." }
            } catch { model.error = error.localizedDescription }
        }
    }
}
struct ChangelogView: View {
    var body: some View {
        List {
            if let catalog = ReleaseCatalog.bundled {
                ForEach(catalog.releases) { release in
                    Section("\(release.version) · \(release.channel.capitalized) · \(release.date)") {
                        ForEach(release.highlights.indices, id: \.self) { index in
                            Label(release.highlights[index].title, systemImage: release.highlights[index].icon)
                        }
                        DisclosureGroup("Fixes & Improvements") { ForEach(release.fixes, id: \.self) { Text($0) } }
                        DisclosureGroup("Compatibility & limitations") { ForEach(release.limitations, id: \.self) { Text($0) } }
                    }
                }
            } else { Text("Release metadata is unavailable in this build.") }
            Section { Text("Unreleased development build. Full validation status is recorded in the project roadmap.").foregroundStyle(.secondary) }
        }.navigationTitle("What’s New")
    }
}
struct IdeasView: View {
    var model: AppModel
    @State private var search = ""
    @State private var status = "all"
    @State private var editing: Idea?
    @State private var importing = false
    @State private var pending: IdeasExport?
    var body: some View {
        List {
            Picker("Status", selection: $status) { Text("All").tag("all"); ForEach(IdeaStatus.allCases, id: \.self) { Text($0.rawValue).tag($0.rawValue) } }
            ForEach(filtered) { idea in
                Button { editing = idea } label: { HStack { Image(systemName: idea.category == "Bug Fix" ? "ladybug" : "lightbulb").foregroundStyle(Color.harmony); VStack(alignment: .leading, spacing: 4) { Text(idea.title).font(.headline); Text("\(idea.status.rawValue) · \(idea.category) · \(idea.priority)").font(.caption).foregroundStyle(.secondary) } } }
                    .contextMenu { Button("Duplicate") { var copy = idea; copy.id = UUID(); copy.title += " copy"; copy.createdAt = Date(); copy.updatedAt = Date(); model.perform { try await model.store?.saveIdea(copy) } }; Button("Delete", role: .destructive) { model.perform { try await model.store?.deleteIdea(idea.id) } } }
            }
        }.navigationTitle("Ideas").searchable(text: $search)
        .toolbar {
            Button { editing = Idea(title: "") } label: { Label("New idea", systemImage: "plus") }
            Menu { Button("Export JSON") { do { model.export(try JSONEncoder().encode(IdeasExport(ideas: model.ideas)), name: "Harmony-ideas.json") } catch { model.error = error.localizedDescription } }; Button("Import JSON") { importing = true } } label: { Image(systemName: "square.and.arrow.up") }
        }
        .sheet(item: $editing) { idea in IdeaEditor(model: model, initial: idea) }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            do { let url = try result.get(); let access = url.startAccessingSecurityScopedResource(); defer { if access { url.stopAccessingSecurityScopedResource() } }; let data = try Data(contentsOf: url); guard data.count <= 10_000_000 else { throw HarmonyError.invalid("Ideas file exceeds 10 MB.") }; let value = try JSONDecoder().decode(IdeasExport.self, from: data); _ = try value.validated(); pending = value } catch { model.error = error.localizedDescription }
        }
        .confirmationDialog("Merge \(pending?.ideas.count ?? 0) incoming ideas? Existing identifiers will be preserved without replacement.", isPresented: Binding(get: { pending != nil }, set: { if !$0 { pending = nil } }), titleVisibility: .visible) {
            Button("Add new ideas only") { if let incoming = pending { model.perform { _ = try await model.store?.importIdeas(incoming) } }; pending = nil }; Button("Cancel", role: .cancel) { pending = nil }
        }
    }
    private var filtered: [Idea] { model.ideas.filter { (status == "all" || $0.status.rawValue == status) && (search.isEmpty || $0.title.localizedStandardContains(search) || $0.description.localizedStandardContains(search)) }.sorted { $0.updatedAt > $1.updatedAt } }
}
struct IdeaEditor: View {
    var model: AppModel
    let initial: Idea
    @State private var idea: Idea
    @Environment(\.dismiss) private var dismiss
    init(model: AppModel, initial: Idea) { self.model = model; self.initial = initial; _idea = State(initialValue: initial) }
    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $idea.title)
                TextEditor(text: $idea.description).frame(minHeight: 160)
                Picker("Category", selection: $idea.category) { ForEach(["Feature", "Improvement", "Bug Fix", "UI/UX", "Performance", "Other"], id: \.self) { Text($0) } }
                Picker("Priority", selection: $idea.priority) { ForEach(["Low", "Normal", "High", "Critical"], id: \.self) { Text($0) } }
                Picker("Status", selection: $idea.status) { ForEach(IdeaStatus.allCases, id: \.self) { Text($0.rawValue).tag($0) } }
                TextField("Implementation reference", text: Binding(get: { idea.implementationReference ?? "" }, set: { idea.implementationReference = $0.isEmpty ? nil : $0 }))
                LabeledContent("Created", value: idea.createdAt.formatted())
            }.navigationTitle("Idea").toolbar { Button("Cancel") { dismiss() }; Button("Save") { idea.updatedAt = Date(); let copy = idea; model.perform { try await model.store?.saveIdea(copy) }; dismiss() }.disabled(idea.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
        }.frame(minWidth: 340, minHeight: 500)
    }
}

@MainActor @Observable final class DownloadModel {
    var source = ""
    var authorized = false
    var status = ""
    var progress: Double?
    var received: Int64 = 0
    var running = false
    var task: Task<Void, Never>?
    func start(model: AppModel) {
        guard authorized, let url = URL(string: source), !running else { return }
        running = true; status = "Downloading"; progress = nil
        task = Task {
            let destination = FileManager.default.temporaryDirectory.appendingPathComponent("HarmonyTransfers/\(UUID()).\(url.pathExtension)")
            defer { try? FileManager.default.removeItem(at: destination); running = false; task = nil }
            do {
                let transfer = try DirectDownload(source: url, destination: destination) { value in Task { @MainActor in self.progress = value.fraction; self.received = value.received } }
                let local = try await transfer.run(); try Task.checkCancellation(); status = "Importing"
                _ = try await model.store?.importAudio(local); status = "Completed · available offline"; await model.reload()
            } catch is CancellationError { status = "Cancelled" }
            catch { status = "Failed: \(error.localizedDescription)" }
        }
    }
}
struct TransfersView: View {
    var model: AppModel
    @State private var download = DownloadModel()
    var body: some View {
        Form {
            Section("Bring authorized audio home") {
                Label("Direct audio download", systemImage: "arrow.down.circle").font(.title2.bold())
                TextField("https://example.org/my-recording.mp3", text: $download.source)
                Toggle("I own this recording or have permission to download it", isOn: $download.authorized)
                Button(download.running ? "Downloading…" : "Download & import") { download.start(model: model) }.disabled(download.running || !download.authorized || download.source.isEmpty)
                if download.running { if let progress = download.progress { ProgressView(value: progress) } else { ProgressView() }; Text(ByteCountFormatter.string(fromByteCount: download.received, countStyle: .file)); Button("Cancel", role: .cancel) { download.task?.cancel() } }
                if !download.status.isEmpty { Text(download.status).font(.callout) }
            }
            Section("Fetch-compatible processing") {
                DisclosureGroup("Connection status: not configured") { Text("Harmony includes a versioned Fetch adapter for capabilities and job creation, polling and cancellation. No live Fetch server has been connected or verified. Core playback remains fully local. See docs/FETCH_INTEGRATION.md for the proposed contract.") }
            }
            Section { Label("Playlist links import track lists; they do not grant access to protected audio.", systemImage: "info.circle").font(.footnote).foregroundStyle(.secondary) }
        }.navigationTitle("Downloads")
    }
}
