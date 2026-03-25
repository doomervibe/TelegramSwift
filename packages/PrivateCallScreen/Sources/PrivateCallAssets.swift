//
//  PrivateCallAssets.swift
//  PrivateCallScreen
//
//  Loads images via the target bundle instead of SwiftPM `Bundle.module` + `ImageResource`,
//  which can hit `_assertionFailure` at runtime when the synthesized resource bundle
//  is not embedded next to the dylib (see crash in PeerCallScreenView.init loading .icSettings).
//

import AppKit

private final class PrivateCallResourceBundleToken {}

enum PrivateCallAssets {
    static let bundle = Bundle(for: PrivateCallResourceBundleToken.self)

    /// Base PNG filename inside `*.imageset` (most match `imagesetName`; `ic_settings` uses `callsettings`).
    private static let rasterBaseName: [String: String] = [
        "ic_settings": "callsettings"
    ]

    static func image(named imagesetName: String) -> NSImage {
        let b = bundle
        let base = rasterBaseName[imagesetName] ?? imagesetName
        let subdirs = [
            "Resources/Assets.xcassets/\(imagesetName).imageset",
            "Assets.xcassets/\(imagesetName).imageset",
            "\(imagesetName).imageset",
        ]
        for sub in subdirs {
            for stem in ["\(base)@2x", base] {
                if let path = b.path(forResource: stem, ofType: "png", inDirectory: sub),
                   let img = NSImage(contentsOfFile: path) {
                    return img
                }
            }
        }
        // Flattened / alternate SPM resource layout
        for stem in ["\(base)@2x", base] {
            if let path = b.path(forResource: stem, ofType: "png"),
               let img = NSImage(contentsOfFile: path) {
                return img
            }
        }
        return NSImage(size: NSSize(width: 24, height: 24))
    }
}
