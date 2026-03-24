//
//  FocusCategoryStripController.swift
//  Telegram
//
//  Focus fork: left-side category strip replacing the old folder sidebar.
//

import Cocoa
import TGUIKit
import SwiftSignalKit
import InAppSettings

// MARK: - Category enum

enum FocusCategory: Equatable {
    case inbox
    case digest        // kept for filter compat; not shown in strip
    case channels      // replaces digest in the strip (unread channels by default)
    case archive
    case saved
    case contacts
    case search
    case stories
    case settings
}

// MARK: - Strip button (simple NSView-based row)

private final class FocusStripButton: Control {
    private let bg = View()
    private let iconView = ImageView()
    private let labelView = TextView()
    private let badgeView = TextView()

    var onTap: (() -> Void)?

    required init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        bg.layer?.cornerRadius = 8
        bg.isEventLess = true
        addSubview(bg)
        addSubview(iconView)
        addSubview(labelView)
        addSubview(badgeView)
        labelView.isSelectable = false
        labelView.userInteractionEnabled = false
        badgeView.isSelectable = false
        badgeView.userInteractionEnabled = false

        set(handler: { [weak self] _ in self?.onTap?() }, for: .Click)
        set(handler: { [weak self] _ in
            guard let self = self, !self.isActive else { return }
            self.bg.backgroundColor = theme.colors.grayBackground
        }, for: .Hover)
        set(handler: { [weak self] _ in
            guard let self = self, !self.isActive else { return }
            self.bg.backgroundColor = .clear
        }, for: .Normal)
    }

    required init?(coder: NSCoder) { fatalError() }

    private var isActive: Bool = false

    func configure(label: String, symbolName: String, badgeCount: Int, isActive: Bool) {
        self.isActive = isActive
        let textColor = isActive ? theme.colors.accent : theme.colors.text
        bg.backgroundColor = isActive ? theme.colors.accent.withAlphaComponent(0.10) : .clear

        if let nsImg = makeIcon(named: symbolName, tint: textColor) {
            iconView.nsImage = nsImg
            iconView.isHidden = false
            iconView.setFrameSize(NSMakeSize(16, 16))
        } else {
            iconView.isHidden = true
        }

        let ll = TextViewLayout(.initialize(string: label, color: textColor, font: .medium(.text)))
        ll.measure(width: frame.width - 50)
        labelView.update(ll)

        if badgeCount > 0 {
            let bl = TextViewLayout(.initialize(string: "\(badgeCount)", color: theme.colors.grayText, font: .normal(11)))
            bl.measure(width: 36)
            badgeView.update(bl)
            badgeView.isHidden = false
        } else {
            badgeView.isHidden = true
        }
        needsLayout = true
    }

    override func layout() {
        super.layout()
        let h = frame.height
        iconView.setFrameOrigin(NSMakePoint(14, (h - 16) / 2))
        labelView.setFrameOrigin(NSMakePoint(40, (h - labelView.frame.height) / 2))
        if !badgeView.isHidden {
            badgeView.setFrameOrigin(NSMakePoint(frame.width - badgeView.frame.width - 10, (h - badgeView.frame.height) / 2))
        }
        bg.frame = NSMakeRect(6, 4, frame.width - 12, h - 8)
    }

    private func makeIcon(named symbolName: String, tint: NSColor) -> NSImage? {
        if #available(macOS 11.0, *) {
            guard let img = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil) else { return nil }
            if #available(macOS 12.0, *) {
                let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .regular)
                let configured = img.withSymbolConfiguration(config) ?? img
                return configured.withTint(tint)
            }
            return img.withTint(tint)
        }
        return nil
    }
}

// MARK: - Container view

final class FocusCategoryStripView: View {
    fileprivate let categoryStack = View()
    fileprivate let settingsRow = View()
    private let borderLine = View()

    static let topInset: CGFloat = 52
    static let rowHeight: CGFloat = 44

    required init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        addSubview(categoryStack)
        addSubview(settingsRow)
        addSubview(borderLine)
        refreshColors()
    }
    required init?(coder: NSCoder) { fatalError() }

    override func layout() {
        super.layout()
        let w = frame.width - 1
        let stackH = CGFloat(categoryStack.subviews.count) * FocusCategoryStripView.rowHeight
        categoryStack.frame = NSMakeRect(0, FocusCategoryStripView.topInset, w, stackH)
        settingsRow.frame = NSMakeRect(0, frame.height - FocusCategoryStripView.rowHeight - 12, w, FocusCategoryStripView.rowHeight)
        borderLine.frame = NSMakeRect(frame.width - 1, 0, 1, frame.height)
    }

    override func updateLocalizationAndTheme(theme: PresentationTheme) {
        super.updateLocalizationAndTheme(theme: theme)
        refreshColors()
    }

    private func refreshColors() {
        backgroundColor = theme.colors.listBackground
        categoryStack.backgroundColor = theme.colors.listBackground
        settingsRow.backgroundColor = theme.colors.listBackground
        borderLine.backgroundColor = theme.colors.border
    }
}

// MARK: - Controller

final class FocusCategoryStripController: TelegramGenericViewController<FocusCategoryStripView> {

    let categorySignal: ValuePromise<FocusCategory> = ValuePromise(.inbox, ignoreRepeated: true)

    private(set) var activeCategory: FocusCategory = .inbox {
        didSet { if oldValue != activeCategory { reloadRows() } }
    }
    private var channelsBadge: Int = 0 {
        didSet { if oldValue != channelsBadge { reloadRows() } }
    }
    private var onCategorySelected: ((FocusCategory) -> Void)?

    func setSelectionHandler(_ handler: @escaping (FocusCategory) -> Void) {
        onCategorySelected = handler
    }

    func updateDigestBadge(_ count: Int) {
        assert(Thread.isMainThread)
        channelsBadge = count
    }

    func updateChannelsBadge(_ count: Int) {
        assert(Thread.isMainThread)
        channelsBadge = count
    }

    func selectCategory(_ category: FocusCategory) {
        activeCategory = category
        categorySignal.set(category)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.bar = .init(height: 0)
        reloadRows()
    }

    private func reloadRows() {
        guard isLoaded() else { return }
        let gv = genericView
        let w = gv.frame.width - 1
        let rowH = FocusCategoryStripView.rowHeight

        let defs: [(FocusCategory, String, String)] = [
            (.inbox,       "Inbox",        "tray"),
            (.channels,    "Channels",     "antenna.radiowaves.left.and.right"),
            (.archive,     "Archive",      "archivebox"),
            (.saved,       "Saved",        "bookmark"),
            (.contacts,    "Contacts",     "person.2"),
            (.search,      "Search",       "magnifyingglass"),
            (.stories,     "Stories",      "sparkles"),
        ]

        // Rebuild category stack
        gv.categoryStack.subviews.forEach { $0.removeFromSuperview() }
        for (i, (cat, label, sym)) in defs.enumerated() {
            let badge: Int
            switch cat {
            case .channels:    badge = channelsBadge
            default:           badge = 0
            }
            let row = makeCategoryRow(width: w, height: rowH, category: cat, label: label, symbolName: sym, badgeCount: badge)
            row.frame = NSMakeRect(0, CGFloat(i) * rowH, w, rowH)
            gv.categoryStack.addSubview(row)
        }

        // Rebuild settings row
        gv.settingsRow.subviews.forEach { $0.removeFromSuperview() }
        let sr = makeCategoryRow(width: w, height: rowH, category: .settings, label: "Settings", symbolName: "gearshape", badgeCount: 0)
        sr.frame = NSMakeRect(0, 0, w, rowH)
        gv.settingsRow.addSubview(sr)

        gv.needsLayout = true
    }

    private func makeCategoryRow(width: CGFloat, height: CGFloat, category: FocusCategory, label: String, symbolName: String, badgeCount: Int) -> NSView {
        let isActive = category == activeCategory
        let row = FocusStripButton(frame: NSMakeRect(0, 0, width, height))
        row.configure(label: label, symbolName: symbolName, badgeCount: badgeCount, isActive: isActive)
        row.onTap = { [weak self] in
            guard let self = self else { return }
            self.activeCategory = category
            self.categorySignal.set(category)
            self.onCategorySelected?(category)
        }
        return row
    }
}

// MARK: - NSImage tint helper

private extension NSImage {
    func withTint(_ color: NSColor) -> NSImage {
        let img = self.copy() as! NSImage
        img.lockFocus()
        color.set()
        NSRect(origin: .zero, size: img.size).fill(using: .sourceAtop)
        img.unlockFocus()
        img.isTemplate = false
        return img
    }
}
