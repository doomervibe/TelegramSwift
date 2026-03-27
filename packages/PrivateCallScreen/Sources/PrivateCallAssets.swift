//
//  PrivateCallAssets.swift
//  PrivateCallScreen
//
//  SPM/Xcode кладёт `Assets.xcassets` в отдельный `*.bundle` в Resources приложения.
//  `Bundle(for:)` при линковке в основной dylib часто даёт `Bundle.main`, где этих путей нет —
//  тогда `NSImage` без растра и `precomposed` падает на `cgImage!`.
//

import AppKit

private final class PrivateCallResourceBundleToken {}

enum PrivateCallAssets {

    private static let rasterBaseName: [String: String] = [
        "ic_settings": "callsettings",
        "ic_microphoneoff": "ic_call_microphoneoff",
        "ic_decline": "xmark",
    ]

    private static let rasterStemOverrides: [String: [String]] = [
        "ic_add_people": ["ic_addPeople@2x (2)", "ic_addPeople (2)"],
    ]

    /// SPM `Assets.xcassets` in this package often ship without raster files (only `Contents.json`).
    /// The macOS app’s catalog already contains matching call UI templates — load those when bundle PNG lookup fails.
    private static let mainAppCatalogName: [String: String] = [
        "ic_video": "Icon_CallVideo_Window",
        "ic_screen": "Icon_CallScreenSharing",
        "ic_mute": "Icon_CallMic_Window",
        "ic_accept": "Icon_CallAccept_Window",
        "ic_redial": "Icon_CallOutgoing",
        "ic_decline": "Icon_CallDecline_Window",
        "ic_settings": "Icon_CallScreenSettings",
        "ic_add_people": "Icon_GroupInfoAddMember",
        "ic_microphoneoff": "Icon_Call_MicroOff",
    ]

    private static func imagesetSubdirectories(_ imagesetName: String) -> [String] {
        [
            "Resources/Assets.xcassets/\(imagesetName).imageset",
            "Assets.xcassets/\(imagesetName).imageset",
            "\(imagesetName).imageset",
        ]
    }

    private static let searchBundles: [Bundle] = {
        var result: [Bundle] = []
        var seen = Set<ObjectIdentifier>()

        func append(_ b: Bundle) {
            let o = ObjectIdentifier(b)
            guard !seen.contains(o) else { return }
            seen.insert(o)
            result.append(b)
        }

        append(Bundle.module)
        append(Bundle(for: PrivateCallResourceBundleToken.self))
        append(Bundle.main)

        if let r = Bundle.main.resourceURL,
           let urls = try? FileManager.default.contentsOfDirectory(at: r, includingPropertiesForKeys: nil) {
            for u in urls where u.pathExtension == "bundle" {
                let n = u.lastPathComponent.lowercased()
                if n.contains("privatecall") || n.contains("private_call") || n.contains("callscreen") {
                    if let b = Bundle(url: u) {
                        append(b)
                    }
                }
            }
        }

        return result
    }()

    /// Гарантированно даёт bitmap-representation (в отличие от пустого `NSImage(size:)` и ненадёжного `lockFocus`).
    private static func fallbackBitmap() -> NSImage {
        let s = NSSize(width: 24, height: 24)
        return NSImage(size: s, flipped: false) { rect in
            NSColor.white.setFill()
            rect.fill()
            return true
        }
    }

    private static func loadPNG(bundle b: Bundle, imagesetName: String, stems: [String]) -> NSImage? {
        let subdirs = imagesetSubdirectories(imagesetName)
        for sub in subdirs {
            for stem in stems {
                if let path = b.path(forResource: stem, ofType: "png", inDirectory: sub),
                   let img = NSImage(contentsOfFile: path) {
                    return img
                }
            }
        }
        for stem in stems {
            if let path = b.path(forResource: stem, ofType: "png"),
               let img = NSImage(contentsOfFile: path) {
                return img
            }
        }
        return nil
    }

    private static func hasBitmapContent(_ image: NSImage) -> Bool {
        guard image.size.width > 0, image.size.height > 0,
              image.size.width.isFinite, image.size.height.isFinite else {
            return false
        }
        if !image.representations.isEmpty {
            return true
        }
        var r = CGRect(origin: .zero, size: image.size)
        return image.cgImage(forProposedRect: &r, context: nil, hints: nil) != nil
    }

    private static func imageFromMainAppCatalog(_ imagesetName: String) -> NSImage? {
        guard let catalog = mainAppCatalogName[imagesetName],
              let img = NSImage(named: catalog),
              hasBitmapContent(img) else {
            return nil
        }
        return img
    }

    static func image(named imagesetName: String) -> NSImage {
        if let stems = rasterStemOverrides[imagesetName] {
            for b in searchBundles {
                if let img = loadPNG(bundle: b, imagesetName: imagesetName, stems: stems) {
                    return img
                }
            }
        }

        let base = rasterBaseName[imagesetName] ?? imagesetName
        let stems = ["\(base)@2x", base]
        for b in searchBundles {
            if let img = loadPNG(bundle: b, imagesetName: imagesetName, stems: stems) {
                return img
            }
        }

        if let img = imageFromMainAppCatalog(imagesetName) {
            return img
        }

        return fallbackBitmap()
    }
}
