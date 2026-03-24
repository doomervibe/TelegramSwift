//
//  FocusMode.swift
//  Telegram-Mac
//
//  Focus-first app fork: distraction-free UX is always on (no toggle).
//

import InAppSettings

/// Always `true` in this fork. Use for greppable focus-related behavior; no persistence or settings.
let isFocusMode = FocusProduct.isEnabled

// MARK: - Phase 5 Extension Points (Send/Receive Delays)
//
// The hook for optional queued/batched sending would plug in at:
//   ChatController.swift – chatInteraction.sendMessage closure (line ~3875)
//   Approach: before calling apply(), check FocusDelaySettings.sendWindowOpen().
//   If window is closed, queue the pending send in FocusOutbox.swift and schedule
//   a local notification/timer to flush it when the delivery window opens.
//
// For receive-side batching:
//   SharedNotificationManager.swift – the `sources` signal (line ~407)
//   Approach: instead of delivering each batch immediately, buffer sources in a
//   FocusInboxBuffer and flush on a timer (e.g. every 30 min).
//   The digest row in ChatListController already surfaces channel unreads;
//   a similar mechanism would batch DM/group messages.
//
// FocusDelaySettings (future struct, not yet implemented):
//   - sendWindowStart: Int  (hour of day, e.g. 9)
//   - sendWindowEnd: Int    (hour of day, e.g. 17)
//   - receiveFlushInterval: TimeInterval (e.g. 1800 = 30 min)
//   - enableSendDelay: Bool
//   - enableReceiveDelay: Bool
