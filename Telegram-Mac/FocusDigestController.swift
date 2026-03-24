//
//  FocusDigestController.swift
//  Telegram-Mac
//
//  Modal list of broadcast channels with unread posts (focus fork digest).
//

import Cocoa
import TGUIKit
import TelegramCore
import InAppSettings
import Postbox

struct UIDigestBannerAction: UIChatListTextAction {
    let text: NSAttributedString
    let info: NSAttributedString
    private let context: AccountContext
    private let channels: [(PeerId, String, Int32)]
    
    var canDismiss: Bool { false }
    
    init(context: AccountContext, channelCount: Int, channels: [(PeerId, String, Int32)]) {
        self.context = context
        let sortedChannels = channels.sorted { $0.2 > $1.2 }
        self.channels = sortedChannels
        
        let title = NSMutableAttributedString()
        _ = title.append(string: "Digest  ", color: theme.colors.text, font: .medium(.text))
        _ = title.append(string: "\(channelCount) channels", color: theme.colors.accent, font: .medium(.text))
        self.text = title
        
        let previewNames = sortedChannels.prefix(3).map { "\($0.1) (\($0.2))" }.joined(separator: "  ·  ")
        let infoText = previewNames.isEmpty ? "Tap to open" : previewNames
        self.info = .initialize(string: infoText, color: theme.colors.grayText, font: .normal(.small))
    }
    
    func action() {
        showModal(with: FocusDigestController(context: context, channels: channels), for: context.window)
    }
    
    func dismiss() {}
    
    func isEqual(_ rhs: any UIChatListTextAction) -> Bool {
        rhs is UIDigestBannerAction
    }
}

private let rowHeight: CGFloat = 40
private let topPadding: CGFloat = 12
private let bottomPadding: CGFloat = 12
private let modalWidth: CGFloat = 380

final class FocusDigestController: ModalViewController {
    private let context: AccountContext
    private let channels: [(PeerId, String, Int32)]
    
    init(context: AccountContext, channels: [(PeerId, String, Int32)]) {
        self.context = context
        self.channels = channels
        let height = topPadding + CGFloat(channels.count) * rowHeight + bottomPadding
        super.init(frame: NSMakeRect(0, 0, modalWidth, min(height, 480)))
    }
    
    override var modalHeader: (left: ModalHeaderData?, center: ModalHeaderData?, right: ModalHeaderData?)? {
        return (
            left: ModalHeaderData(image: theme.icons.modalClose, handler: { [weak self] in
                self?.close()
            }),
            center: ModalHeaderData(title: "Channels with new posts"),
            right: nil
        )
    }
    
    override func measure(size: NSSize) {
        let height = topPadding + CGFloat(channels.count) * rowHeight + bottomPadding
        self.modal?.resize(with: NSMakeSize(modalWidth, min(height, size.height - 80)), animated: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        view.layer?.backgroundColor = theme.colors.background.cgColor
        
        let scroll = ScrollView()
        let document = View()
        scroll.documentView = document
        view.addSubview(scroll)
        scroll.autoresizingMask = [.width, .height]
        let headerH = bar.height
        scroll.frame = NSMakeRect(0, headerH, view.bounds.width, view.bounds.height - headerH)
        
        let contentWidth = view.frame.width - 40
        var y: CGFloat = topPadding
        for ch in channels {
            let rowView = Control(frame: NSMakeRect(20, y, contentWidth, rowHeight - 4))
            rowView.wantsLayer = true
            rowView.layer?.cornerRadius = 6
            
            let nameLabel = TextView()
            nameLabel.isSelectable = false
            nameLabel.userInteractionEnabled = false
            let nameLayout = TextViewLayout(.initialize(string: ch.1, color: theme.colors.text, font: .medium(.text)))
            nameLayout.measure(width: contentWidth - 60)
            nameLabel.update(nameLayout)
            nameLabel.frame = NSMakeRect(12, (rowHeight - 4 - nameLayout.layoutSize.height) / 2, nameLayout.layoutSize.width, nameLayout.layoutSize.height)
            rowView.addSubview(nameLabel)
            
            let badgeLabel = TextView()
            badgeLabel.isSelectable = false
            badgeLabel.userInteractionEnabled = false
            let badgeLayout = TextViewLayout(.initialize(string: "\(ch.2)", color: theme.colors.grayText, font: .normal(.small)))
            badgeLayout.measure(width: 60)
            badgeLabel.update(badgeLayout)
            badgeLabel.frame = NSMakeRect(contentWidth - badgeLayout.layoutSize.width - 12, (rowHeight - 4 - badgeLayout.layoutSize.height) / 2, badgeLayout.layoutSize.width, badgeLayout.layoutSize.height)
            rowView.addSubview(badgeLabel)
            
            let peerId = ch.0
            rowView.set(handler: { [weak self] _ in
                guard let self = self else { return }
                closeAllModals(window: self.context.window)
                self.context.bindings.rootNavigation().push(ChatController(context: self.context, chatLocation: .peer(peerId)))
            }, for: .Click)
            rowView.set(handler: { control in
                control.backgroundColor = theme.colors.grayBackground
            }, for: .Hover)
            rowView.set(handler: { control in
                control.backgroundColor = .clear
            }, for: .Normal)
            
            document.addSubview(rowView)
            y += rowHeight
        }
        document.frame = NSMakeRect(0, 0, view.frame.width, y + bottomPadding)
        
        readyOnce()
    }
}
