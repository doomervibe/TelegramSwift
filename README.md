<div align="center">
  <br>
  <h1>Focus</h1>
  <p><strong>An async, inbox-style Telegram client for macOS.</strong></p>
  <p>
    Built on <a href="https://github.com/overtake/TelegramSwift">TelegramSwift</a>.
    Strips the noise. Keeps the signal.
  </p>
  <br>
</div>

---

Telegram is built for conversation. Focus is built for people who'd rather not be in one right now.

It takes the full TelegramSwift codebase and reshapes it into something closer to email: an inbox you check on your terms, not a feed that demands your attention. No typing indicators. No presence dots. No read receipts ticking up in real time. Just messages, organized and waiting.

## What's different

| Stock Telegram | Focus |
|---|---|
| Chat bubbles, alternating sides | Full-width messages, author name as header |
| Avatars, story rings, badges everywhere | Clean text-only list rows |
| Typing indicators, online dots, read ticks | Nothing — async by default |
| Emoji picker, sticker button, gift button | Minimal composer: just a text field |
| Channels mixed into chat list | Channels hidden, surfaced via a **Digest** banner |
| Folders as tabs | **Pinned** / **Inbox** section headers |
| Dark mode, auto-night, theme switching | Locked to a subdued light palette |
| Media previews inline | Attachment-style placeholders (tap to expand) |

## Design pillars

**Async over live.** No real-time social signals leak through. You read when you want. You reply when you're ready.

**Mail-like layout.** Messages flow top-to-bottom in a single column. Sender names sit above the text like email headers. Generous whitespace. No visual ping-pong.

**Inbox, not chat.** The sidebar organizes conversations into Pinned and Inbox sections. A category strip on the left gives you Inbox, Channels, Archive, Saved, Contacts, Search, and Stories — no tab bar, no folder pills.

**Digest for channels.** Broadcast channels are pulled out of the main list entirely. A digest banner shows how many channels have new posts; tap it to see the list and jump in.

**Minimal chrome.** If a UI element exists to create urgency or social pressure, it's gone. Avatars appear on hover after a delay, not by default. The composer is a text field and nothing else.

## Architecture

This is a hard fork, not a plugin. `FocusProduct.isEnabled` is always `true` — there is no toggle to go back to stock behavior. Key files:

```
Telegram-Mac/
├── FocusMode.swift                      # Flag + future send/receive delay hooks
├── FocusCategoryStripController.swift   # Left sidebar category navigation
├── FocusDigestController.swift          # Channel digest banner + modal
├── FocusAvatarHoverManager.swift        # Delayed avatar reveal on row hover
├── ChatFocusMediaPlaceholderItem.swift  # Attachment-style media placeholders
├── ChatListController.swift             # Section headers, digest injection, filtering
├── ChatListRowItem.swift                # Stripped-down list row (no avatars, no ticks)
├── ChatListRowView.swift                # Row rendering with focus layout
├── ChatRowItem.swift                    # Full-width message layout
├── ChatInputView.swift                  # Minimal composer ("Write a reply…")
├── ChatInputActionsView.swift           # Hidden emoji/keyboard/gift buttons
└── Appearance.swift                     # Theme locked to light palette
```

## Roadmap

- **Send windows** — queue outgoing messages and flush them during a configured time window (e.g. 9am–5pm)
- **Receive batching** — buffer incoming messages and deliver them on a timer instead of instantly
- **Notification digest** — replace per-message notifications with periodic summaries

The hooks for these are already sketched in `FocusMode.swift`.

## Building

```bash
make build
```

See [INSTALL.md](INSTALL.md) for full build instructions and dependencies. You'll need your own [Telegram API ID](https://core.telegram.org/api/obtaining_api_id).

## License

Same as upstream: [GNU General Public License v2.0](LICENSE).

This is an unofficial fork. It is not affiliated with Telegram.
