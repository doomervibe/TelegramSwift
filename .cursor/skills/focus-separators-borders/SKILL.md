---
name: focus-separators-borders
description: Remove or hide 1pt list chrome (horizontal/vertical separators, column borders) in the Focus fork. Use when gray lines remain after theme tweaks, or when adding new row types that draw separators.
---

# Focus fork: list separators and borders

## Goal

In Focus, list and settings rows should not show hairline dividers or vertical column rules, except where a feature explicitly needs structure.

## System lever (palette)

In `Telegram-Mac/Appearance.swift`, `generateTheme` builds an `effectivePalette` for Focus:

- **`withUpdatedBorder(palette.listBackground)`** — sets `ColorPalette.border` to the same color as the list surface so TGUIKit fills (TableView clip border, `TableRowView` edges, `NavigationViewController` bar borders, etc.) are invisible.
- **Do not use `NSColor.clear`** for `border` in `ColorPalette` init paths; on newer macOS it can raise `NSColorRaiseWithColorSpaceError` when the palette validates colors.

`ColorPalette.withUpdatedBorder(_:)` lives in `packages/ColorPalette/Sources/ColorPalette/ColorPalette.swift` (duplicates the `withUpdatedWallpaper` pattern).

## TGUIKit vs Telegram theme

`TableView`, `NavigationViewController`, and `View` border drawing use **`presentation.colors`** from TGUIKit, synced when the app calls `updateTheme(_:)` with `TelegramPresentationTheme`. Changing only `theme.colors` in isolated views is not enough if `presentation` is stale; the palette passed into `generateTheme` must carry the adjusted `border`.

## Telegram-Mac row views (explicit draws / custom themes)

Some code bypasses `theme.colors.border` or uses opaque **`customTheme.borderColor`**:

| Area | File / behavior |
|------|------------------|
| Block row bottom strip | `GeneralContainableRowView.borderView` — `GeneralRowView.swift`: in Focus, `borderColor` → `listBackground` |
| Settings-style rows | `GeneralInteractedRowView` — same override so `customTheme.borderColor` does not draw gray lines |
| Peer rows | `ShortPeerRowView` — strip `.Right` from `border`, `rightSeparatorView` / `separator` use `listBackground` in Focus |
| Chat list between rows | `ChatListRowView.draw` — skip bottom `ctx.fill` when `FocusProduct.isEnabled` |
| Search chrome | `PeersListController.swift` — `SearchContainer` border empty in Focus |

## Drag highlight

`TelegramChatListTheme.activeDraggingBackgroundColor` uses `palette.grayForeground` in Focus instead of `palette.border` so reorder drag remains visible when `border` matches the list.

## If lines remain

Grep for `theme.colors.border`, `presentation.colors.border`, `ctx.fill` with `.borderSize`, and `BorderType.Right` on new screens; add a Focus branch or reuse `listBackground` like the rows above.
