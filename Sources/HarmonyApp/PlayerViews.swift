// SPDX-License-Identifier: AGPL-3.0-only
import SwiftUI
import HarmonyCore
#if os(iOS)
import AVKit
#endif
struct PlayerView: View {
    var model: AppModel
    @Bindable var player: PlaybackController
    @Environment(\.dismiss) private var dismiss
    @State private var page = "Player"
    @State private var scrubbing = false
    @State private var scrubPosition: Double = 0
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Picker("Now Playing view", selection: $page) { Text("Player").tag("Player"); Text("Lyrics").tag("Lyrics"); Text("Queue").tag("Queue") }.pickerStyle(.segmented)
                    if page == "Player" {
                        ArtworkView(url: player.currentTrack.flatMap { model.artwork[$0.id] }, size: 280).shadow(color: .harmony.opacity(0.18), radius: 28, y: 14).padding(.vertical, 12)
                        VStack(spacing: 8) { Text(player.currentTrack?.title ?? "Nothing playing").font(.title2.bold()).multilineTextAlignment(.center); Text(player.currentTrack?.artist ?? "Unknown artist").font(.title3).foregroundStyle(.secondary); Text(player.currentTrack?.album ?? "").font(.subheadline).foregroundStyle(.secondary) }
                        HStack { if let track = player.currentTrack { Button { model.favorite(track) } label: { Label("Favorite", systemImage: model.tracks.first(where: { $0.id == track.id })?.favorite == true ? "heart.fill" : "heart") } }; Spacer(); Menu { Button("Sleep in 15 minutes") { player.sleepDeadline = Date().addingTimeInterval(900) }; Button("Sleep in 30 minutes") { player.sleepDeadline = Date().addingTimeInterval(1800) }; Button("Stop after this track") { player.stopAfterTrack = true }; Button("Cancel sleep timer") { player.sleepDeadline = nil; player.stopAfterTrack = false } } label: { Label("Sleep", systemImage: player.sleepDeadline != nil || player.stopAfterTrack ? "moon.fill" : "moon") } }.font(.callout)
                    } else if page == "Lyrics" { LyricsView(player: player).frame(minHeight: 300) }
                    else { queueView }
                    VStack(spacing: 4) {
                        Slider(value: Binding(get: { scrubbing ? scrubPosition : player.position }, set: { scrubPosition = $0 }), in: 0...max(1, player.duration), onEditingChanged: { editing in
                            if editing { scrubPosition = player.position; scrubbing = true }
                            else { player.seek(to: scrubPosition); scrubbing = false }
                        }).accessibilityLabel("Playback position")
                        HStack { Text(clock(scrubbing ? scrubPosition : player.position)); Spacer(); Text("−" + clock(player.duration - (scrubbing ? scrubPosition : player.position))) }.font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                    }
                    HStack(spacing: 30) {
                        Button { player.setShuffle(!player.queue.shuffle) } label: { Image(systemName: "shuffle").foregroundStyle(player.queue.shuffle ? Color.harmony : .secondary) }.accessibilityLabel("Shuffle \(player.queue.shuffle ? "on" : "off")")
                        Button { Task { await player.previous() } } label: { Image(systemName: "backward.fill").font(.title) }.accessibilityLabel("Previous")
                        Button { player.toggle() } label: { Image(systemName: player.isPlaying ? "pause.fill" : "play.fill").font(.system(size: 30)).frame(width: 76, height: 76).foregroundStyle(.white).background(Color.harmony, in: Circle()) }.accessibilityLabel(player.isPlaying ? "Pause" : "Play")
                        Button { Task { await player.next() } } label: { Image(systemName: "forward.fill").font(.title) }.accessibilityLabel("Next")
                        Button { player.cycleRepeat() } label: { Image(systemName: player.queue.repeatMode == .one ? "repeat.1" : "repeat").foregroundStyle(player.queue.repeatMode == .off ? .secondary : Color.harmony) }.accessibilityLabel("Repeat \(player.queue.repeatMode.rawValue)")
                    }.buttonStyle(.plain)
                    if let error = player.errorMessage { Label(error, systemImage: "exclamationmark.triangle").font(.callout).foregroundStyle(.red) }
                    #if os(iOS)
                    RoutePicker().frame(height: 44).accessibilityLabel("Audio output and AirPlay")
                    #endif
                }.padding(28).frame(maxWidth: 580).frame(maxWidth: .infinity)
            }.background(LinearGradient(colors: [.harmony.opacity(0.12), .clear], startPoint: .top, endPoint: .bottom))
            .navigationTitle("Now Playing").toolbar { Button("Done") { dismiss() } }
        }
    }
    private var queueView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack { Text("Up next").font(.title2.bold()); Spacer(); Button("Save playlist") { let entries = player.queue.items.compactMap { item -> PlaylistEntry? in guard let track = model.tracks.first(where: { $0.id == item.trackID }) else { return nil }; return PlaylistEntry(title: track.title, artist: track.artist, trackID: track.id) }; model.perform { try await model.store?.save(Playlist(name: "Saved queue", entries: entries)) } }; Button("Clear") { player.clearQueue() } }
            ForEach(Array(player.queue.items.enumerated()), id: \.element.id) { index, item in
                HStack {
                    Image(systemName: index == player.queue.index ? "waveform" : "music.note").foregroundStyle(Color.harmony)
                    Text(model.tracks.first(where: { $0.id == item.trackID })?.title ?? "Missing track"); Spacer()
                    Button { player.moveQueueItem(from: index, to: max(0, index - 1)) } label: { Image(systemName: "arrow.up") }.accessibilityLabel("Move up")
                    Button { player.moveQueueItem(from: index, to: min(player.queue.items.count - 1, index + 1)) } label: { Image(systemName: "arrow.down") }.accessibilityLabel("Move down")
                    Button { Task { await player.removeQueueItem(item.id) } } label: { Image(systemName: "minus.circle") }.accessibilityLabel("Remove from queue")
                }
            }
        }.frame(minHeight: 280, alignment: .top)
    }
}
struct LyricsView: View {
    var player: PlaybackController
    @State private var follow = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        if let document = player.lyrics, !document.lines.isEmpty {
            let lines = document.lines
            let active = document.activeIndex(at: player.position)
            VStack {
                Toggle("Follow playback", isOn: $follow).font(.caption)
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 24) {
                            ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                                Button { if let time = line.time { player.seek(to: max(0, time + document.offset)) } } label: { Text(line.text.isEmpty ? "♪" : line.text).font(.title2.bold()).foregroundStyle(active == index || active == nil ? .primary : .secondary).frame(maxWidth: .infinity, alignment: .leading) }.buttonStyle(.plain).id(index).disabled(line.time == nil)
                            }
                        }.padding(.vertical, 24)
                    }.frame(height: 300).onChange(of: active) { _, value in if follow, let value { withAnimation(reduceMotion ? nil : .easeOut(duration: 0.25)) { proxy.scrollTo(value, anchor: .center) } } }
                }
            }
        } else { ContentUnavailableView("Lyrics live here", systemImage: "quote.bubble", description: Text("Open a song’s Metadata & Lyrics editor to add your own text or LRC file.")) }
    }
}
#if os(iOS)
struct RoutePicker: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView { let view = AVRoutePickerView(); view.prioritizesVideoDevices = false; return view }
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}
#endif
