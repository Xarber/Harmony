#!/usr/bin/env python3
# SPDX-License-Identifier: AGPL-3.0-only
"""Generate original, very quiet QA audio and user-owned sample lyrics; never auto-import."""
from pathlib import Path
import wave, math, struct
folder = Path('.build/Fixtures'); folder.mkdir(parents=True, exist_ok=True)
for title, hz in [('First Light', 440), ('Quiet Current', 330)]:
    with wave.open(str(folder / (title + '.wav')), 'wb') as f:
        f.setnchannels(1); f.setsampwidth(2); f.setframerate(44100)
        f.writeframes(b''.join(struct.pack('<h', int(600 * math.sin(i * 2 * math.pi * hz / 44100))) for i in range(44100 * 12)))
(folder/'Original lyrics.lrc').write_text('[00:00.00]A quiet wave begins\n[00:04.00]A little room for light\n[00:08.00]The sound comes home again\n')
(folder/'Fixture playlist.m3u8').write_text('#EXTM3U\n#EXTINF:12,OpenRecode — First Light\nFirst Light.wav\n#EXTINF:12,OpenRecode — Quiet Current\nQuiet Current.wav\n#EXTINF:-1,Original Artist — Missing recording\nmissing.wav\n')
print(folder.resolve())
