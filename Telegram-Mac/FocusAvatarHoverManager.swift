//
//  FocusAvatarHoverManager.swift
//  Telegram
//
//  Focus fork: shared manager that renders a hovering avatar preview
//  near the right edge of the left category strip, vertically aligned
//  with the chat-list row being hovered.
//

import Cocoa
import TGUIKit
import TelegramCore
import Postbox

private let kAvatarSize: CGFloat = 44
private let kRevealDelay: TimeInterval = 1.4
private let kRevealDuration: TimeInterval = 0.55
private let kHideDuration: TimeInterval = 0.38
private let kXOffset: CGFloat = 8  // gap between avatar right edge and sidebar right edge

final class FocusAvatarHoverManager {
    static let shared = FocusAvatarHoverManager()
    private init() {}

    private weak var currentWindow: NSWindow?
    private var overlayView: View?
    private var avatarView: AvatarControl?
    private var revealWorkItem: DispatchWorkItem?
    private var currentPeerId: PeerId?

    // Call when a chat-list or contacts row is hovered.
    // `peer`          – the chat peer whose avatar to show
    // `context`       – the account context for avatar loading
    // `rowBoundsInWindow` – the row's frame in the WINDOW's coordinate space
    //                       (pass `rowView.convert(rowView.bounds, to: nil)`)
    func rowHovered(peer: Peer?, context: AccountContext?, rowBoundsInWindow: NSRect, window: NSWindow) {
        guard let peer = peer, let context = context else {
            hide()
            return
        }

        // Ensure the overlay lives in the right window.
        if overlayView?.window !== window {
            teardownOverlay()
            setupOverlay(in: window)
        }
        currentWindow = window

        // Reuse or create avatar control.
        let av: AvatarControl
        if let existing = avatarView {
            av = existing
        } else {
            av = AvatarControl(font: .avatar(17))
            av.setFrameSize(NSMakeSize(kAvatarSize, kAvatarSize))
            av.layer?.cornerRadius = kAvatarSize / 2
            av.layer?.masksToBounds = true
            overlayView?.addSubview(av)
            avatarView = av
        }

        // Only reload the peer image if it changed.
        if currentPeerId != peer.id {
            currentPeerId = peer.id
            av.setPeer(account: context.account, peer: peer)
        }

        // Position in the overlay (which fills the window's content view).
        // X: just inside the right edge of the sidebar strip.
        // Y: centered on the hovered row (rowBoundsInWindow is in window coords).
        let xPos: CGFloat = FocusLeftChromeLayout.effectiveWidth - kAvatarSize - kXOffset
        let yPos: CGFloat = positionY(for: rowBoundsInWindow, in: window)
        av.frame = NSMakeRect(xPos, yPos, kAvatarSize, kAvatarSize)

        // Start the reveal sequence.
        revealWorkItem?.cancel()
        av.alphaValue = 0
        let workItem = DispatchWorkItem { [weak self, weak av] in
            guard let self, let av else { return }
            self.revealWorkItem = nil
            av.animator().alphaValue = 1.0
        }
        revealWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + kRevealDelay, execute: workItem)
    }

    // Call when the same row is still hovered but may have scrolled (update position only).
    func updatePosition(rowBoundsInWindow: NSRect, window: NSWindow) {
        guard let av = avatarView, overlayView?.window === window else { return }
        let yPos = positionY(for: rowBoundsInWindow, in: window)
        av.frame.origin = NSMakePoint(av.frame.origin.x, yPos)
    }

    // Call when the row is no longer hovered.
    func rowUnhovered() {
        revealWorkItem?.cancel()
        revealWorkItem = nil
        currentPeerId = nil
        guard let av = avatarView, av.alphaValue > 0.01 else {
            avatarView?.alphaValue = 0
            avatarView?.removeFromSuperview()
            avatarView = nil
            return
        }
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = kHideDuration
            av.animator().alphaValue = 0
        }, completionHandler: { [weak av] in
            av?.removeFromSuperview()
        })
        avatarView = nil
    }

    func hide() {
        rowUnhovered()
    }

    // MARK: - Private

    private func setupOverlay(in window: NSWindow) {
        guard let contentView = window.contentView else { return }
        let overlay = View(frame: contentView.bounds)
        overlay.isEventLess = true
        overlay.wantsLayer = true
        overlay.autoresizingMask = [.width, .height]
        contentView.addSubview(overlay)
        overlayView = overlay
    }

    private func teardownOverlay() {
        avatarView?.removeFromSuperview()
        avatarView = nil
        overlayView?.removeFromSuperview()
        overlayView = nil
    }

    /// Converts a row's bounds-in-window rect to a Y position for the avatar
    /// inside the contentView coordinate system.
    private func positionY(for rowBoundsInWindow: NSRect, in window: NSWindow) -> CGFloat {
        guard let contentView = window.contentView else { return 0 }
        // Convert from window-base coordinates to contentView local coordinates.
        let rowInContent = contentView.convert(rowBoundsInWindow, from: nil)
        return rowInContent.midY - kAvatarSize / 2
    }
}
