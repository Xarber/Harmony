// SPDX-License-Identifier: AGPL-3.0-only
import SwiftUI
import HarmonyCore

struct PlaylistDetail: View {
    var model: AppModel
    var playlistID: UUID
    @State private var adding = false
    @State private var renaming = false
    @State private var name = ""
    var playlist: Playlist? { model.playlists.first { $0.id == playlistID } }
    var body: some View {
        Group {
            if let playlist {
                List {
                    Section {
                        TextField("Description", text: Binding(get: { playlist.description }, set: { value in save { $0.description = value } }))
                        Button("Play available tracks", systemImage: "play.fill") {
                            let tracks = playlist.entries.compactMap { entry in model.tracks.first { $0.id == entry.trackID } }
                            Task { await model.player?.start(tracks) }
                        }.disabled(playlist.entries.allSatisfy { $0.trackID == nil })
                    }
                    ForEach(playlist.entries) { entry in
                        if let track = model.tracks.first(where: { $0.id == entry.trackID }) { TrackRow(track: track, model: model) }
                        else { Label { VStack(alignment: .leading) { Text(entry.title); Text("\(entry.artist ?? "Unknown artist") · Missing audio").font(.caption).foregroundStyle(.secondary) } } icon: { Image(systemName: "icloud.slash").foregroundStyle(.secondary) } }
                    }.onDelete { indices in save { $0.entries.remove(atOffsets: indices) } }.onMove { source, target in save { $0.entries.move(fromOffsets: source, toOffset: target) } }
                }.navigationTitle(playlist.name)
                .toolbar {
                    Button { adding = true } label: { Label("Add songs", systemImage: "plus") }
                    Menu {
                        Button("Rename") { name = playlist.name; renaming = true }
                        Button("Duplicate") { var copy = Playlist(name: playlist.name + " copy", entries: playlist.entries); copy.description = playlist.description; model.perform { try await model.store?.save(copy) } }
                        ForEach([PlaylistFormat.json, .m3u8, .csv, .xspf], id: \.self) { format in Button("Export \(format.rawValue.uppercased())") { model.exportPlaylist(playlist, format: format) } }
                    } label: { Image(systemName: "ellipsis.circle") }
                    #if os(iOS)
                    EditButton()
                    #endif
                }
            } else { ContentUnavailableView("Playlist unavailable", systemImage: "music.note.list") }
        }
        .alert("Rename playlist", isPresented: $renaming) { TextField("Name", text: $name); Button("Save") { if !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { save { $0.name = name } } }; Button("Cancel", role: .cancel) {} }
        .sheet(isPresented: $adding) {
            NavigationStack { List(model.tracks) { track in Button { save { $0.entries.append(PlaylistEntry(title: track.title, artist: track.artist, trackID: track.id, duration: track.duration)) } } label: { Label(track.title, systemImage: "plus.circle") } }.navigationTitle("Add songs").toolbar { Button("Done") { adding = false } } }.frame(minWidth: 340, minHeight: 480)
        }
    }
    private func save(_ edit: (inout Playlist) -> Void) { guard var copy = playlist else { return }; edit(&copy); model.perform { try await model.store?.save(copy) } }
}
struct PastePlaylistView: View {
    var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = "Imported playlist"
    @State private var text = ""
    var body: some View {
        NavigationStack {
            Form { TextField("Playlist name", text: $name); Section("One Artist — Title per line") { TextEditor(text: $text).frame(minHeight: 260) }; Text("This imports a track list. Audio acquisition is a separate step.").font(.footnote).foregroundStyle(.secondary) }
                .navigationTitle("Import track list").toolbar { Button("Cancel") { dismiss() }; Button("Preview") { do { let playlist = try PlaylistParser.parse(Data(text.utf8), format: .text, name: name); dismiss(); Task { @MainActor in model.preview = playlist } } catch { model.error = error.localizedDescription } }.disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
        }.frame(minWidth: 340, minHeight: 500)
    }
}
struct PlaylistPreview: View {
    var model: AppModel
    let original: Playlist
    @Environment(\.dismiss) private var dismiss
    @State private var selections: [UUID: UUID] = [:]
    @State private var excluded: Set<UUID> = []
    @State private var title = ""
    var body: some View {
        List {
            Section {
                TextField("Playlist name", text: $title)
                Label("\(original.entries.count) entries · order and duplicates preserved", systemImage: "list.number")
                Text("Choose a local recording for each entry. Unmatched items remain in your playlist without audio.").foregroundStyle(.secondary).font(.callout)
                Button(excluded.isEmpty ? "Deselect all" : "Select all") { excluded = excluded.isEmpty ? Set(original.entries.map(\.id)) : [] }
            }
            ForEach(Array(original.entries.enumerated()), id: \.element.id) { index, entry in
                VStack(alignment: .leading, spacing: 8) {
                    Toggle(isOn: Binding(get: { !excluded.contains(entry.id) }, set: { if $0 { excluded.remove(entry.id) } else { excluded.insert(entry.id) } })) { Text("\(index + 1). \(entry.title)").font(.headline); Text(entry.artist ?? "Unknown artist").font(.caption) }
                    let candidates = TrackMatcher.candidates(for: entry, in: model.tracks)
                    Picker("Recording", selection: Binding<UUID?>(get: { selections[entry.id] }, set: { selections[entry.id] = $0 })) {
                        Text("Unmatched · metadata only").tag(nil as UUID?)
                        ForEach(candidates) { candidate in Text("\(candidate.track.title) · \(candidate.track.artist ?? "Unknown artist") · \(Int(candidate.confidence * 100))%\(candidate.exact ? " · Exact" : " · Review")").tag(candidate.track.id as UUID?) }
                    }
                    if let selected = selections[entry.id], let candidate = candidates.first(where: { $0.id == selected }) { Text(candidate.explanation).font(.caption).foregroundStyle(.secondary) }
                    else if !candidates.isEmpty { Label(candidates.count > 1 ? "Multiple candidates — choose a recording" : "Probable match — confirmation required", systemImage: "questionmark.circle").font(.caption).foregroundStyle(.secondary) }
                }.padding(.vertical, 6)
            }
        }.navigationTitle("Review playlist")
        .toolbar { Button("Cancel") { dismiss() }; Button("Save playlist") {
            var copy = original; copy.name = title.isEmpty ? original.name : title
            copy.entries = original.entries.filter { !excluded.contains($0.id) }.map { entry in var updated = entry; updated.trackID = selections[entry.id]; return updated }
            model.perform { try await model.store?.save(copy) }; dismiss()
        } }
        .onAppear {
            title = original.name
            for entry in original.entries {
                let exact = TrackMatcher.candidates(for: entry, in: model.tracks).filter(\.exact)
                if exact.count == 1 { selections[entry.id] = exact[0].track.id }
            }
        }
    }
}
