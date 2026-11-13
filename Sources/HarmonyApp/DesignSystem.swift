// SPDX-License-Identifier: AGPL-3.0-only
import SwiftUI

/// Shared, restrained motion. Playback clocks, scrubbing and keyboard commands stay immediate.
enum HarmonyMotion {
    static func stateChange(reduced: Bool) -> Animation { reduced ? .linear(duration: 0.1) : .spring(response: 0.3, dampingFraction: 1) }
    static func feedback(reduced: Bool) -> Animation { .easeOut(duration: reduced ? 0.1 : 0.16) }
}
struct HarmonyPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(HarmonyMotion.feedback(reduced: reduceMotion), value: configuration.isPressed)
    }
}
struct HarmonyFloatingSurface: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    @ViewBuilder func body(content: Content) -> some View {
        if reduceTransparency || contrast == .increased {
            content.background(.background, in: RoundedRectangle(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(.primary.opacity(0.3)))
        } else if #available(iOS 26.0, macOS 26.0, *) {
            content.glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
        } else {
            content.background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        }
    }
}
extension View { func harmonyFloatingSurface() -> some View { modifier(HarmonyFloatingSurface()) } }
