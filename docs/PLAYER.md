# Playback

One main-actor `PlaybackController` owns AVPlayer, queue, current recording, actual clock, lyrics and system-media state. Mini-player, full player and lyrics read the same owner. Generation tokens discard obsolete asynchronous loads; item completion observers are scoped to the active item. Errors are visible rather than silently skipping missing audio.

The queue stores distinct occurrence IDs even when a track appears twice. Supported operations include play/pause, seek, next/previous, play-next, append, move/remove, clear, queue-to-playlist, shuffle and repeat off/all/one. Shuffle chooses another occurrence; it is not yet a no-repeat shuffled cycle. Previous seeks to the beginning after three seconds. At the queue end the player pauses and resets rather than starting a new queue unexpectedly.

Queue, index, clock, repeat and shuffle are periodically saved in SQLite. Restoration is paused. The runtime Mac test proves import, clock advancement, pause, seek, resume and paused restoration with a generated WAV. Listening counts currently increment at playback start rather than a scrobble threshold. Disable-history preferences and more precise play accounting remain roadmap work.

## iOS integrations implemented, not device-verified

- AVAudioSession playback/long-form category is activated on explicit play.
- UIBackgroundModes includes audio.
- MPNowPlayingInfoCenter receives recording metadata, artwork, rate and time.
- Remote commands support play, pause, toggle, next, previous and position changes.
- Interruptions pause; resume only when previously playing and the system permits it.
- Old-device route removal pauses playback.
- AVRoutePickerView exposes supported AirPlay/system route selection.

These require full Xcode and real iPhone validation. Lock-screen controls, Control Center, screen-off playback, calls/Siri, wired and Bluetooth disconnection, AirPlay and long background sessions were not verified during initial development. Mac UI playback does not establish these behaviors.

## Lyrics and sleep

Lyrics resolve against AVPlayer's clock, never a free-running lyrics timer. Seeking/pausing naturally update selection. Users can disable follow scrolling, tap timed lines to seek and use reduced-motion rendering. The sleep menu offers 15/30 minutes or stop after this track. The deadline is checked using wall-clock time on player callbacks; sleep behavior in suspended/background states needs device testing. Stop after playlist is equivalent to normal repeat-off queue completion, not an independent timer setting.

## Advanced processing

EQ, ReplayGain, crossfade, guaranteed gapless transitions, bit-perfect output and adjustable speed are not implemented. AVPlayer is a system playback pipeline and may resample according to the output route. Do not describe a converted lossy recording as newly lossless.
