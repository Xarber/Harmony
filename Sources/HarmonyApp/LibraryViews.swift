// SPDX-License-Identifier: AGPL-3.0-only
import SwiftUI
import HarmonyCore
import UniformTypeIdentifiers

struct RootView: View {
    @Bindable var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("onboarded") private var onboarded = false
    @AppStorage("lastSeenVersion") private var lastVersion = ""
    @State private var tab = 0
    @State private var importing = false
    @State private var expanded = false
    @State private var settings = false
    @State private var whatsNew = false
    var body: some View {
        TabView(selection: $tab) {
            NavigationStack { HomeView(model: model, importing: $importing) }.tabItem { Label("Home", systemImage: "house.fill") }.tag(0)
            NavigationStack { LibraryView(model: model, importing: $importing) }.tabItem { Label("Library", systemImage: "square.stack.fill") }.tag(1)
            NavigationStack { SearchView(model: model) }.tabItem { Label("Search", systemImage: "magnifyingglass") }.tag(2)
            NavigationStack { TransfersView(model: model) }.tabItem { Label("Downloads", systemImage: "arrow.down.circle.fill") }.tag(3)
        }
        .safeAreaInset(edge: .bottom) {
            if let player = model.player, let track = player.currentTrack {
                HStack(spacing: 14) {
                    Button { expanded = true } label: {
                        HStack { ArtworkView(url: model.artwork[track.id], size: 46); VStack(alignment: .leading) { Text(track.title).font(.headline).lineLimit(1); Text(track.artist ?? "Unknown artist").font(.caption).foregroundStyle(.secondary).lineLimit(1) }; Spacer() }
                    }.buttonStyle(.plain).accessibilityLabel("Open Now Playing, \(track.title)")
                    Button { player.toggle() } label: { Image(systemName: player.isPlaying ? "pause.fill" : "play.fill").frame(width: 44, height: 44) }.accessibilityLabel(player.isPlaying ? "Pause" : "Play")
                    Button { Task { await player.next() } } label: { Image(systemName: "forward.fill").frame(width: 44, height: 44) }.accessibilityLabel("Next track")
                }.padding(10).harmonyFloatingSurface().padding(.horizontal).padding(.bottom, 4)
                .transition(.opacity)
            }
        }
        .overlay(alignment: .top) {
            if model.importing {
                VStack { HStack { Text("Importing music").font(.headline); Spacer(); Button("Cancel") { model.importTask?.cancel() } }; ProgressView(value: model.importProgress); Text(model.importMessage).font(.caption).lineLimit(1) }.padding().background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16)).padding()
            }
        }
        .animation(HarmonyMotion.stateChange(reduced: reduceMotion), value: model.player?.currentTrack?.id)
        .animation(HarmonyMotion.stateChange(reduced: reduceMotion), value: model.importing)
        .toolbar { ToolbarItem { Button { settings = true } label: { Label("Settings", systemImage: "gearshape") } } }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.audio, .data], allowsMultipleSelection: true) { result in
            switch result { case .success(let urls): model.importFiles(urls); case .failure(let error): model.error = error.localizedDescription }
        }
        .fileExporter(isPresented: $model.showingExport, document: model.exportDocument, contentType: model.exportType, defaultFilename: model.exportName) { result in if case .failure(let error) = result { model.error = error.localizedDescription } }
        .sheet(isPresented: $expanded) { if let player = model.player { PlayerView(model: model, player: player).frame(minWidth: 340, minHeight: 560) } }
        .sheet(isPresented: $settings) { NavigationStack { SettingsView(model: model) }.frame(minWidth: 340, minHeight: 560) }
        .sheet(item: $model.preview) { playlist in NavigationStack { PlaylistPreview(model: model, original: playlist) }.frame(minWidth: 340, minHeight: 560) }
        .sheet(isPresented: Binding(get: { !onboarded }, set: { onboarded = !$0 })) {
            VStack(spacing: 28) {
                Image(systemName: "waveform.circle.fill").font(.system(size: 92)).foregroundStyle(Color.harmony)
                Text("Your music.\nIn perfect harmony.").font(.largeTitle.bold()).multilineTextAlignment(.center)
                Text("A home for the music you own.").foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 18) {
                    Label("Import from Files. Originals stay safe.", systemImage: "folder")
                    Label("Listen offline, without an account.", systemImage: "headphones")
                    Label("Audio stays in Harmony’s private storage.", systemImage: "lock.shield")
                }
                Button("Import your music") { onboarded = true; importing = true }.buttonStyle(.borderedProminent).controlSize(.large)
                Button("Start with an empty library") { onboarded = true }.buttonStyle(.plain)
            }.padding(36).frame(minWidth: 340, minHeight: 540).interactiveDismissDisabled()
        }
        .onAppear { if lastVersion.isEmpty { lastVersion = "0.1.0" } else if lastVersion != "0.1.0" { whatsNew = true; lastVersion = "0.1.0" } }
        .sheet(isPresented: $whatsNew) { ChangelogView() }
    }
}

struct ArtworkView: View {
    var url: URL?
    var size: CGFloat = 64
    var body: some View {
        Group {
            if let url, let image = image(url) { image.resizable().scaledToFill() }
            else { ZStack { LinearGradient(colors: [.harmony.opacity(0.85), .indigo.opacity(0.5), .purple.opacity(0.35)], startPoint: .topLeading, endPoint: .bottomTrailing); Image(systemName: "waveform").font(.system(size: size * 0.32, weight: .medium)).foregroundStyle(.white.opacity(0.85)) } }
        }.frame(width: size, height: size).clipShape(RoundedRectangle(cornerRadius: max(8, size * 0.13))).accessibilityHidden(true)
    }
    private static let thumbnails = NSCache<NSString, CGImage>()
    private func image(_ url: URL) -> Image? {
        let key = "\(url.path)-\(Int(size * 2))" as NSString
        if let cached = Self.thumbnails.object(forKey: key) { return Image(decorative: cached, scale: 2) }
        Self.thumbnails.totalCostLimit = 32 * 1024 * 1024
        // ImageIO decodes a thumbnail rather than a full-resolution cover for each row.
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil), let cg = CGImageSourceCreateThumbnailAtIndex(source, 0, [kCGImageSourceCreateThumbnailFromImageAlways: true, kCGImageSourceThumbnailMaxPixelSize: Int(size * 2), kCGImageSourceCreateThumbnailWithTransform: true] as CFDictionary) else { return nil }
        Self.thumbnails.setObject(cg, forKey: key, cost: cg.bytesPerRow * cg.height)
        return Image(decorative: cg, scale: 2)
    }
}
import ImageIO

struct TrackRow: View {
    var track: Track
    var model: AppModel
    @State private var editing = false
    var body: some View {
        HStack(spacing: 14) {
            Button { Task { await model.player?.start(model.tracks, at: track.id) } } label: {
                HStack(spacing: 14) {
                    ArtworkView(url: model.artwork[track.id], size: 48)
                    VStack(alignment: .leading, spacing: 4) { Text(track.title).font(.body.weight(.medium)).foregroundStyle(.primary).lineLimit(1); Text(track.artist ?? "Unknown artist").font(.subheadline).foregroundStyle(.secondary).lineLimit(1) }
                    Spacer()
                }.contentShape(Rectangle())
            }.buttonStyle(.plain)
            if track.favorite { Image(systemName: "heart.fill").foregroundStyle(Color.harmony).accessibilityLabel("Favorite") }
            Text(clock(track.duration ?? 0)).font(.caption.monospacedDigit()).foregroundStyle(.secondary)
            Menu {
                Button("Play next", systemImage: "text.line.first.and.arrowtriangle.forward") { model.player?.add(track.id, next: true) }
                Button("Add to queue", systemImage: "text.badge.plus") { model.player?.add(track.id) }
                Button(track.favorite ? "Remove favorite" : "Favorite", systemImage: "heart") { model.favorite(track) }
                Menu("Add to playlist") { ForEach(model.playlists) { playlist in Button(playlist.name) { model.perform { var copy = playlist; copy.entries.append(PlaylistEntry(title: track.title, artist: track.artist, trackID: track.id, duration: track.duration)); try await model.store?.save(copy) } } } }
                Button("Metadata & lyrics", systemImage: "slider.horizontal.3") { editing = true }
                Button("Export audio", systemImage: "square.and.arrow.up") { model.perform { if let url = try await model.store?.exportAudio(track.id) { let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                    guard size < 256_000_000 else { throw HarmonyError.unsupported("In-app file export is limited to 256 MB in this preview. The managed original is preserved.") }
                    let data = try Data(contentsOf: url); model.export(data, name: "\(track.title).\(url.pathExtension)", type: .audio) } } }
                Button("Remove from library", systemImage: "trash", role: .destructive) { model.perform { try await model.store?.removeTrack(track.id) } }
            } label: { Image(systemName: "ellipsis").frame(width: 44, height: 44) }.menuStyle(.borderlessButton).fixedSize().accessibilityLabel("Actions for \(track.title)")
        }.padding(.vertical, 5)
        .sheet(isPresented: $editing) { NavigationStack { MetadataView(model: model, original: track) }.frame(minWidth: 340, minHeight: 580) }
    }
}
func clock(_ seconds: Double) -> String { guard seconds.isFinite else { return "–:––" }; let s = Int(max(0, seconds)); return String(format: "%d:%02d", s / 60, s % 60) }

struct HomeView: View {
    var model: AppModel
    @Binding var importing: Bool
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) { Text("HARMONY").font(.caption.weight(.bold)).tracking(3).foregroundStyle(Color.harmony); Text("Make room\nfor your music.").font(.system(.largeTitle, design: .rounded).weight(.bold)); Text("Your collection. Always with you.").foregroundStyle(.secondary) }
                    Spacer(); Image(systemName: "waveform").font(.system(size: 68, weight: .light)).foregroundStyle(Color.harmony).padding(.top, 30).accessibilityHidden(true)
                }
                HStack(spacing: 24) { stat("Songs", value: model.tracks.count); stat("Albums", value: Set(model.tracks.compactMap(\.album)).count); stat("Playlists", value: model.playlists.count) }.padding(24).frame(maxWidth: .infinity, alignment: .leading).background(Color.harmony.opacity(0.08), in: RoundedRectangle(cornerRadius: 22))
                if model.tracks.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Label("A library that belongs to you", systemImage: "music.note.house").font(.title2.bold())
                        Text("Bring your MP3, M4A, FLAC or other supported audio files. Harmony reads their tags and keeps a private copy for offline listening.").foregroundStyle(.secondary)
                        Button { importing = true } label: { Label("Import music", systemImage: "plus.circle.fill") }.buttonStyle(.borderedProminent).controlSize(.large)
                    }.padding(26).frame(maxWidth: .infinity, alignment: .leading).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
                } else {
                    HStack { Text("Recently added").font(.title2.bold()); Spacer(); Button { importing = true } label: { Label("Import", systemImage: "plus") } }
                    ForEach(model.tracks.sorted { $0.addedAt > $1.addedAt }.prefix(8)) { TrackRow(track: $0, model: model) }
                    let recent = model.tracks.filter { $0.lastPlayedAt != nil }.sorted { ($0.lastPlayedAt ?? .distantPast) > ($1.lastPlayedAt ?? .distantPast) }
                    if !recent.isEmpty { Text("Played recently").font(.title2.bold()); ForEach(recent.prefix(4)) { TrackRow(track: $0, model: model) } }
                }
                Label("Offline by nature. No account required.", systemImage: "checkmark.shield").font(.footnote).foregroundStyle(.secondary)
            }.padding(28).frame(maxWidth: 980, alignment: .leading).frame(maxWidth: .infinity)
        }.navigationTitle(model.isQA ? "Home · Test library" : "Home")
    }
    private func stat(_ label: String, value: Int) -> some View { VStack(alignment: .leading, spacing: 5) { Text(value.formatted()).font(.title.bold()); Text(label).font(.caption).foregroundStyle(.secondary) }.frame(maxWidth: .infinity, alignment: .leading) }
}

struct LibraryView: View {
    var model: AppModel
    @Binding var importing: Bool
    @State private var section = "Songs"
    @State private var newPlaylist = false
    @State private var name = ""
    @State private var pasteImport = false
    var body: some View {
        List {
            Picker("Browse", selection: $section) { ForEach(["Songs", "Albums", "Artists", "Genres", "Favorites", "Playlists"], id: \.self) { Text($0) } }.pickerStyle(.menu)
            if section == "Playlists" {
                Button("Create playlist", systemImage: "plus") { newPlaylist = true }
                Button("Import track list", systemImage: "text.badge.plus") { pasteImport = true }
                ForEach(model.playlists) { playlist in NavigationLink { PlaylistDetail(model: model, playlistID: playlist.id) } label: { Label { VStack(alignment: .leading) { Text(playlist.name); Text("\(playlist.entries.count) tracks").font(.caption).foregroundStyle(.secondary) } } icon: { Image(systemName: "music.note.list").foregroundStyle(Color.harmony) } } }
                .onDelete { indices in model.perform { for index in indices { try await model.store?.deletePlaylist(model.playlists[index].id) } } }
            } else if ["Albums", "Artists", "Genres"].contains(section) {
                ForEach(groups, id: \.self) { group in NavigationLink { List(filtered(group)) { TrackRow(track: $0, model: model) }.navigationTitle(group) } label: { HStack { ArtworkView(url: filtered(group).first.flatMap { model.artwork[$0.id] }, size: 52); VStack(alignment: .leading) { Text(group).font(.headline); Text("\(filtered(group).count) songs").font(.caption).foregroundStyle(.secondary) } } } }
            } else { ForEach(section == "Favorites" ? model.tracks.filter(\.favorite) : model.tracks) { TrackRow(track: $0, model: model) } }
        }
        .overlay { if model.tracks.isEmpty && section != "Playlists" { ContentUnavailableView("Your library starts here", systemImage: "music.note", description: Text("Import audio files to listen offline." )).padding(.top, 60) } }
        .navigationTitle("Library").toolbar { Button { importing = true } label: { Label("Import", systemImage: "plus") } }
        .alert("New playlist", isPresented: $newPlaylist) { TextField("Name", text: $name); Button("Create") { let title = name.trimmingCharacters(in: .whitespacesAndNewlines); if !title.isEmpty { model.perform { try await model.store?.save(Playlist(name: title)) }; name = "" } }; Button("Cancel", role: .cancel) {} }
        .sheet(isPresented: $pasteImport) { PastePlaylistView(model: model) }
    }
    private var groups: [String] { Set(model.tracks.map { section == "Albums" ? ($0.album ?? "Unknown album") : section == "Artists" ? ($0.artist ?? "Unknown artist") : ($0.genre ?? "Uncategorized") }).sorted() }
    private func filtered(_ group: String) -> [Track] { model.tracks.filter { (section == "Albums" ? ($0.album ?? "Unknown album") : section == "Artists" ? ($0.artist ?? "Unknown artist") : ($0.genre ?? "Uncategorized")) == group } }
}
struct SearchView: View {
    var model: AppModel
    @State private var query = ""
    var body: some View {
        List {
            ForEach(results) { TrackRow(track: $0, model: model) }
            ForEach(model.playlists.filter { query.isEmpty || $0.name.localizedStandardContains(query) }) { playlist in NavigationLink(playlist.name) { PlaylistDetail(model: model, playlistID: playlist.id) } }
        }.searchable(text: $query, prompt: "Songs, artists, albums, genres, files").navigationTitle("Search")
            .overlay { if results.isEmpty && !query.isEmpty { ContentUnavailableView.search(text: query) } }
    }
    private var results: [Track] { model.tracks.filter { track in query.isEmpty || [track.title, track.artist ?? "", track.album ?? "", track.genre ?? "", model.files[track.id]?.first?.originalName ?? ""].contains { $0.localizedStandardContains(query) } } }
}
