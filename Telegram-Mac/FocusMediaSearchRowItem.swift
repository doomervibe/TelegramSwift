//
//  FocusMediaSearchRowItem.swift
//  Telegram
//
//  Focus fork: media-centric search result rows for global searches filtered
//  by message tag (voice, files, links, music). Shows the actual media item
//  rather than the chat context that contains it.
//

import Cocoa
import TGUIKit
import TelegramCore
import Postbox
import SwiftSignalKit
import DateUtils

// MARK: - Helpers

private func durationString(_ duration: Int) -> String {
    let mins = duration / 60
    let secs = duration % 60
    return String(format: "%d:%02d", mins, secs)
}

// MARK: - Row Item

final class FocusMediaSearchRowItem: GeneralRowItem {

    enum MediaKind {
        case voice(TelegramMediaFile)
        case music(TelegramMediaFile)
        case file(TelegramMediaFile)
        case link(TelegramMediaWebpage)
    }

    let context: AccountContext
    let message: Message
    let kind: MediaKind
    let titleLayout: TextViewLayout
    let subtitleLayout: TextViewLayout

    init?(_ initialSize: NSSize, context: AccountContext, message: Message, action: @escaping () -> Void) {
        self.context = context
        self.message = message

        if let file = message.media.first(where: { $0 is TelegramMediaFile }) as? TelegramMediaFile {
            // Determine file category from its attributes.
            var isVoiceOrVideo = false
            var isMusicFile = false
            for attr in file.attributes {
                switch attr {
                case let .Audio(isVoice, _, _, _, _):
                    if isVoice { isVoiceOrVideo = true } else { isMusicFile = true }
                case .Video:
                    if file.isInstantVideo { isVoiceOrVideo = true }
                default:
                    break
                }
            }
            if isVoiceOrVideo {
                let duration = Int(file.duration ?? 0)
                let durStr = durationString(duration)
                titleLayout = TextViewLayout(.initialize(string: "\(FocusStrings.voiceMessage) · \(durStr)", color: theme.colors.text, font: .medium(.text)), maximumNumberOfLines: 1)
                let sender = message.author?.displayTitle ?? ""
                let dateStr = DateUtils.string(forMessageListDate: message.timestamp) ?? ""
                subtitleLayout = TextViewLayout(.initialize(string: "\(sender) · \(dateStr)", color: theme.colors.grayText, font: .normal(.small)), maximumNumberOfLines: 1)
                kind = .voice(file)
            } else if isMusicFile {
                let (songTitle, artist) = file.musicText
                let duration = Int(file.duration ?? 0)
                let durStr = durationString(duration)
                titleLayout = TextViewLayout(.initialize(string: songTitle.isEmpty ? (file.fileName ?? FocusStrings.unknown) : songTitle, color: theme.colors.text, font: .medium(.text)), maximumNumberOfLines: 1)
                subtitleLayout = TextViewLayout(.initialize(string: artist.isEmpty ? durStr : "\(artist) · \(durStr)", color: theme.colors.grayText, font: .normal(.small)), maximumNumberOfLines: 1)
                kind = .music(file)
            } else {
                let fileName = file.fileName ?? FocusStrings.unknown
                titleLayout = TextViewLayout(.initialize(string: fileName, color: theme.colors.text, font: .medium(.text)), maximumNumberOfLines: 1)
                let sizeStr = file.size.map { dataSizeString(Int($0), formatting: DataSizeStringFormatting.current) } ?? ""
                let dateStr = DateUtils.string(forMessageListDate: message.timestamp) ?? ""
                subtitleLayout = TextViewLayout(.initialize(string: [sizeStr, dateStr].filter { !$0.isEmpty }.joined(separator: " · "), color: theme.colors.grayText, font: .normal(.small)), maximumNumberOfLines: 1)
                kind = .file(file)
            }
        } else if let webpage = message.media.first(where: { $0 is TelegramMediaWebpage }) as? TelegramMediaWebpage {
            if case let .Loaded(content) = webpage.content {
                let title = content.title ?? content.displayUrl ?? content.url
                titleLayout = TextViewLayout(.initialize(string: title, color: theme.colors.text, font: .medium(.text)), maximumNumberOfLines: 1)
                subtitleLayout = TextViewLayout(.initialize(string: content.displayUrl ?? content.url, color: theme.colors.accent, font: .normal(.small)), maximumNumberOfLines: 1)
            } else {
                titleLayout = TextViewLayout(.initialize(string: FocusStrings.link, color: theme.colors.text, font: .medium(.text)), maximumNumberOfLines: 1)
                subtitleLayout = TextViewLayout(.initialize(string: "", color: theme.colors.grayText, font: .normal(.small)), maximumNumberOfLines: 1)
            }
            kind = .link(webpage)
        } else {
            return nil
        }

        super.init(initialSize, stableId: AnyHashable(message.id), action: action)
    }

    override var height: CGFloat { 52 }

    override func makeSize(_ width: CGFloat, oldWidth: CGFloat = 0) -> Bool {
        _ = super.makeSize(width, oldWidth: oldWidth)
        titleLayout.measure(width: width - 20)
        subtitleLayout.measure(width: width - 20)
        return true
    }

    override func viewClass() -> AnyClass { FocusMediaSearchRowView.self }
}

// MARK: - Row View

final class FocusMediaSearchRowView: GeneralContainableRowView {
    private let titleView = TextView()
    private let subtitleView = TextView()
    private let overlay = Control()

    required init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        titleView.isSelectable = false
        titleView.userInteractionEnabled = false
        subtitleView.isSelectable = false
        subtitleView.userInteractionEnabled = false
        containerView.addSubview(titleView)
        containerView.addSubview(subtitleView)
        containerView.addSubview(overlay)
        overlay.set(handler: { [weak self] _ in
            (self?.item as? FocusMediaSearchRowItem)?.action()
        }, for: .Click)
        overlay.set(background: theme.colors.grayForeground.withAlphaComponent(0.08), for: .Highlight)
        overlay.set(background: .clear, for: .Normal)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layout() {
        super.layout()
        overlay.frame = containerView.bounds
        titleView.setFrameOrigin(NSMakePoint(14, 10))
        subtitleView.setFrameOrigin(NSMakePoint(14, frame.height - subtitleView.frame.height - 10))
    }

    override func set(item: TableRowItem, animated: Bool = false) {
        super.set(item: item, animated: animated)
        guard let item = item as? FocusMediaSearchRowItem else { return }
        titleView.update(item.titleLayout)
        subtitleView.update(item.subtitleLayout)
        needsLayout = true
    }
}
