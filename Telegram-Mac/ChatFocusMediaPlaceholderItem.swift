//
//  ChatFocusMediaPlaceholderItem.swift
//  Telegram-Mac
//
//  Focus fork: show media as attachment-style placeholders instead of inline previews.
//

import Cocoa
import TGUIKit
import TelegramCore
import InAppSettings
import Postbox
import SwiftSignalKit

final class ChatFocusMediaPlaceholderItem: ChatRowItem {
    
    let titleLayout: TextViewLayout
    
    override var instantlyResize: Bool {
        return true
    }
    
    init(_ initialSize: NSSize, _ chatInteraction: ChatInteraction, _ context: AccountContext, _ entry: ChatHistoryEntry, title: String, theme: TelegramPresentationTheme) {
        let isIncoming = entry.message.map { $0.isIncoming(context.account, entry.renderType == .bubble) } ?? true
        let textColor = theme.chat.textColor(isIncoming, entry.renderType == .bubble)
        let attr = NSMutableAttributedString()
        _ = attr.append(string: title, color: textColor, font: .medium(.text))
        self.titleLayout = TextViewLayout(attr, maximumNumberOfLines: 2)
        super.init(initialSize, chatInteraction, context, entry, theme: theme)
        _ = makeSize(initialSize.width, oldWidth: 0)
    }
    
    override func makeSize(_ width: CGFloat, oldWidth: CGFloat) -> Bool {
        _ = super.makeSize(width, oldWidth: oldWidth)
        titleLayout.measure(width: blockWidth - 24)
        return true
    }
    
    override func makeContentSize(_ width: CGFloat) -> NSSize {
        let pillH = titleLayout.layoutSize.height + 12
        return NSMakeSize(width, pillH + 12)
    }
    
    override var height: CGFloat {
        return contentOffset.y + makeContentSize(blockWidth).height + defaultContentTopOffset
    }

    override var commentsBubbleData: ChannelCommentsRenderData? { return nil }
    override var commentsBubbleDataOverlay: ChannelCommentsRenderData? { return nil }
    
    override func viewClass() -> AnyClass {
        return ChatFocusMediaPlaceholderView.self
    }
}

final class ChatFocusMediaPlaceholderView: ChatRowView {
    private let pillBackground = View()
    private let text = TextView()
    private let tapContainer = Control()
    
    private func mediaForPlaceholder(from entry: ChatHistoryEntry) -> (parent: Message, medias: [Media])? {
        guard case let .groupedPhotos(entries, _) = entry else {
            return nil
        }
        let messages = entries.compactMap { $0.message }
        guard let parent = messages.first else {
            return nil
        }
        let medias = messages.compactMap { message -> Media? in
            for media in message.media {
                if media is TelegramMediaImage {
                    return media
                } else if let file = media as? TelegramMediaFile {
                    if file.isGraphicFile || file.isVideo || file.isAnimated || file.isVideoFile {
                        return file
                    }
                }
            }
            return nil
        }
        guard !medias.isEmpty else {
            return nil
        }
        return (parent, medias)
    }
    
    required init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        pillBackground.layer?.cornerRadius = 6
        tapContainer.scaleOnClick = true
        tapContainer.addSubview(pillBackground)
        tapContainer.addSubview(text)
        text.isSelectable = false
        text.userInteractionEnabled = false
        contentView.addSubview(tapContainer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateColors() {
        super.updateColors()
        pillBackground.backgroundColor = theme.colors.grayBackground
    }
    
    override func set(item: TableRowItem, animated: Bool) {
        super.set(item: item, animated: animated)
        guard let item = item as? ChatFocusMediaPlaceholderItem else { return }
        text.update(item.titleLayout)
        tapContainer.removeAllHandlers()
        tapContainer.set(handler: { [weak item] _ in
            guard let item = item else { return }
            if let grouped = self.mediaForPlaceholder(from: item.entry) {
                showPaidMedia(context: item.context, medias: grouped.medias, parent: grouped.parent, firstIndex: 0, firstStableId: ChatHistoryEntryId.mediaId(0, grouped.parent), item.table, nil)
            } else if let message = item.message {
                showChatGallery(context: item.context, message: message, item.table, nil, type: .history, chatMode: item.chatInteraction.mode, chatLocation: item.chatInteraction.chatLocation, contextHolder: item.chatInteraction.contextHolder())
            }
        }, for: .Click)
        needsLayout = true
    }
    
    override func layout() {
        super.layout()
        guard let item = item as? ChatFocusMediaPlaceholderItem else { return }
        let pillW = min(item.blockWidth - 16, item.titleLayout.layoutSize.width + 20)
        let pillH = item.titleLayout.layoutSize.height + 12
        let pillSz = NSMakeSize(max(60, pillW), pillH)
        let pillY = max(0, (contentView.frame.height - pillH) / 2)
        tapContainer.frame = NSMakeRect(0, pillY, pillSz.width, pillSz.height)
        pillBackground.frame = tapContainer.bounds
        text.frame = tapContainer.bounds.insetBy(dx: 10, dy: 6)
    }
}
