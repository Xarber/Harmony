// SPDX-License-Identifier: AGPL-3.0-only
import Foundation
struct ReleaseCatalog: Decodable {
    struct Release: Decodable, Identifiable {
        var id: String { version + "." + String(build) }
        struct Highlight: Decodable { var title: String; var icon: String }
        var version: String
        var build: Int
        var date: String
        var channel: String
        var highlights: [Highlight]
        var fixes: [String]
        var limitations: [String]
        var ideaIDs: [String]
    }
    var schemaVersion: Int
    var releases: [Release]
    static var bundled: ReleaseCatalog? {
        #if SWIFT_PACKAGE
        let bundle = Bundle.module
        #else
        let bundle = Bundle.main
        #endif
        guard let url = bundle.url(forResource: "releases", withExtension: "json"), let data = try? Data(contentsOf: url), let catalog = try? JSONDecoder().decode(Self.self, from: data), catalog.schemaVersion == 1 else { return nil }
        return catalog
    }
}
