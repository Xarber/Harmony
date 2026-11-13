# Interface design

Harmony uses system typography, the original layered H waveform and a violet accent. The web separates navigation, library content and playback controls. Text labels accompany navigation symbols. Icon-only player actions have accessible names. The guide keeps explanatory content in its reading flow. Editors group instructions near their fields and use an inline status message.

| Before | After | Why |
| --- | --- | --- |
| Native mini-player used regular material on every supported OS | Liquid Glass on iOS and macOS 26+, regular material on older systems, solid contrast treatment for accessibility | Floating controls remain distinct and legible |
| Playback transport used a plain style | 160 ms press feedback and opacity-only feedback with Reduce Motion | Shows when the control has registered a press |
| Mobile web tabs overflowed at 390 px | Four equal columns with icons above labels | All destinations remain visible |
| Web lyrics were parsed on each playback update | Parse when the track or its lyrics change | Playback updates only adjust the current line |

Native transitions use a critically damped spring for discrete state changes and a short fade with Reduce Motion. Browser buttons use 160 ms press feedback. Dialogs and the landing/library transition use a 220 ms ease-out. Keyboard navigation is immediate. Playhead updates remain tied to audio time. There is no looping decorative motion. Web supports dark and light modes, reduced motion, reduced transparency and increased contrast. Physical-device motion and accessibility validation remain open.

Design guidance consulted included Apple Design, Emil Design Engineering and Animate. Platform references include [Apple's Liquid Glass documentation](https://developer.apple.com/documentation/SwiftUI/Applying-Liquid-Glass-to-custom-views).
