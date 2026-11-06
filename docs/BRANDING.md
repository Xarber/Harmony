# Harmony identity

The user supplied the name Harmony and tagline “Your music. In perfect harmony.” Both are preserved. No global trademark availability or legal clearance is claimed.

Accent #6269F5; gradient light #858AFF and deep #464DCE; white/light foreground, with native system foreground/background colors for accessibility. Typography is the platform system font with rounded large headlines. Controls use SF Symbols provided by the OS; no proprietary music-service artwork is bundled.

The editable SVG master is assets/branding/harmony-icon.svg. Stable groups: background, resonance, shadow, symbol and highlight, with reusable gradient definitions. The symbol combines an H with a central waveform. Its geometry remains independent from background/embellishments. PNG sizes 32, 180, 192, 512 and 1024 are reproducible using `swift scripts/export-branding.swift`. The native renderer is a simplified flat export of the master geometry; highlights/shadow are retained in the editable SVG. PNG pixel sizes were checked, including an opaque 1024×1024 iOS asset. The final raster was visually inspected after correcting an unsupported bitmap-context export.

The app uses neutral gradient artwork placeholders only for missing covers; they are not album covers or real screenshots. Light/dark UI uses system materials and user-selectable appearance. Dedicated dark/tinted app-icon exports, layered Apple Icon Composer assets, splash branding, repository banner and social previews remain incomplete. Do not present ordinary flat PNGs as completed platform-layered icon deliverables. Android adaptive/PWA icons are outside the current supported platform scope.
