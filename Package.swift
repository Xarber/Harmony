// swift-tools-version: 6.2
// SPDX-License-Identifier: AGPL-3.0-only
import PackageDescription
let package = Package(
    name: "Harmony", platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "HarmonyCore", targets: ["HarmonyCore"]), .executable(name: "Harmony", targets: ["HarmonyApp"])],
    targets: [
        .systemLibrary(name: "CSQLite", pkgConfig: "sqlite3"),
        .target(name: "HarmonyCore", dependencies: ["CSQLite"]),
        .executableTarget(name: "HarmonyApp", dependencies: ["HarmonyCore"], exclude: ["Assets.xcassets"], resources: [.process("Resources")], swiftSettings: [.defaultIsolation(MainActor.self)]),
        .testTarget(name: "HarmonyCoreTests", dependencies: ["HarmonyCore"])
    ], swiftLanguageModes: [.v6]
)
