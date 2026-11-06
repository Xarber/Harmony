// SPDX-License-Identifier: AGPL-3.0-only
import SwiftUI
import HarmonyCore
import UniformTypeIdentifiers
struct MetadataView: View {
    var model: AppModel
    var original: Track
    @Environment(\.dismiss) private var dismiss
    @State private var track: Track
    @State private var lyrics = ""
    @State private var offset: Double = 0
    @State private var selectingLyrics = false
    @State private var selectingArtwork = false
    @State private var candidates: [MetadataCandidate] = []
    @State private var lookingUp = false
    @State private var oldLyrics = ""
    init(model: AppModel, original: Track) { self.model = model; self.original = original; _track = State(initialValue: original) }
    var body: some View {
        Form {
            Section("Recording") {
                field("Title", value: $track.title)
                optional("Artist", value: $track.artist); optional("Album", value: $track.album)
                optional("Album artist", value: $track.albumArtist); optional("Genre", value: $track.genre)
                optional("Composer", value: $track.composer); optional("Release date", value: $track.releaseDate)
                optional("ISRC", value: $track.isrc); optional("MusicBrainz recording ID", value: $track.recordingID)
                optional("Comments", value: $track.comments)
                Toggle("Favorite", isOn: $track.favorite)
            }
            Section("Artwork") { HStack { ArtworkView(url: model.artwork[track.id], size: 90); Button("Choose artwork") { selectingArtwork = true } } }
            Section("Metadata lookup") {
                DisclosureGroup("What is shared?") { Text("A search sends the title and artist to MusicBrainz. Audio stays on your device. Results are suggestions; existing fields change only when you choose a candidate and save.") }
                Button { lookingUp = true; model.perform { defer { lookingUp = false }; candidates = try await MusicBrainzProvider.shared.search(title: track.title, artist: track.artist) } } label: { Label(lookingUp ? "Searching…" : "Search MusicBrainz", systemImage: "magnifyingglass") }.disabled(lookingUp)
                ForEach(candidates) { candidate in
                    Button { track.title = candidate.title; track.artist = candidate.artist; track.recordingID = candidate.id; track.provenance["title"] = "MusicBrainz · user approved"; track.provenance["artist"] = "MusicBrainz · user approved" } label: { VStack(alignment: .leading) { Text(candidate.title); Text("\(candidate.artist ?? "Unknown artist") · \(clock(candidate.duration ?? 0))").font(.caption).foregroundStyle(.secondary) } }
                }
            }
            Section("Lyrics · stored locally") {
                Button("Import LRC or text file", systemImage: "doc.badge.plus") { selectingLyrics = true }
                TextEditor(text: $lyrics).frame(minHeight: 200).font(.body.monospaced())
                HStack { Text("Timing offset"); TextField("Seconds", value: $offset, format: .number).frame(width: 80); Text("sec").foregroundStyle(.secondary) }
                HStack { Button("Undo text edit") { swap(&lyrics, &oldLyrics) }; Button("Stamp current playback time") { let timestamp = LRC.export([LyricLine(time: model.player?.position ?? 0, text: "")]); lyrics += "\n" + timestamp } }
                Text("Use [mm:ss.xx] before each line. Positive offset delays the lyrics. Only export lyrics you have permission to share.").font(.caption).foregroundStyle(.secondary)
                Button("Export lyrics") { model.export(Data(lyrics.utf8), name: "\(track.title).lrc", type: .plainText) }
            }
            Section("Audio file") {
                ForEach(model.files[track.id] ?? []) { file in
                    LabeledContent("File", value: file.originalName)
                    LabeledContent("Container", value: file.container.uppercased())
                    LabeledContent("Size", value: ByteCountFormatter.string(fromByteCount: file.byteCount, countStyle: .file))
                    LabeledContent("Duration", value: clock(track.duration ?? 0))
                }
                Text("Edits update Harmony’s database. Embedded file tags and original audio are preserved.").font(.caption).foregroundStyle(.secondary)
            }
            Section("Metadata sources") { ForEach(track.provenance.keys.sorted(), id: \.self) { key in LabeledContent(key.capitalized, value: track.provenance[key] ?? "") } }
        }.navigationTitle("Metadata & Lyrics")
        .toolbar { Button("Cancel") { dismiss() }; Button("Save") {
            let raw = lyrics; let correction = offset; var edited = track
            if edited.title != original.title { edited.provenance["title"] = "User edited" }
            if edited.artist != original.artist { edited.provenance["artist"] = "User edited" }
            if edited.album != original.album { edited.provenance["album"] = "User edited" }
            model.perform { try await model.store?.update(edited); try await model.store?.saveLyrics(LyricsDocument(raw: raw, offset: correction), for: edited.id); await model.player?.refreshLyrics() }; dismiss()
        }.disabled(track.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
        .task { if let document = try? await model.store?.lyrics(for: track.id) { lyrics = document.raw; offset = document.offset; oldLyrics = lyrics } }
        .fileImporter(isPresented: $selectingLyrics, allowedContentTypes: [.plainText, .data]) { result in
            do { let url = try result.get(); let access = url.startAccessingSecurityScopedResource(); defer { if access { url.stopAccessingSecurityScopedResource() } }; let data = try Data(contentsOf: url); guard data.count < 2_000_000, let text = String(data: data, encoding: .utf8) else { throw HarmonyError.invalid("Use a UTF-8 lyrics file under 2 MB.") }; oldLyrics = lyrics; lyrics = text } catch { model.error = error.localizedDescription }
        }
        .fileImporter(isPresented: $selectingArtwork, allowedContentTypes: [.png, .jpeg, .heic, .webP]) { result in
            switch result { case .success(let url): model.perform { try await model.store?.setArtwork(url, for: track.id) }; case .failure(let error): model.error = error.localizedDescription }
        }
    }
    private func field(_ label: String, value: Binding<String>) -> some View { TextField(label, text: value) }
    private func optional(_ label: String, value: Binding<String?>) -> some View { TextField(label, text: Binding(get: { value.wrappedValue ?? "" }, set: { value.wrappedValue = $0.isEmpty ? nil : $0 })) }
}
