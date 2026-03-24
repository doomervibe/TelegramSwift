---
name: focus-chatlist-debugging
description: Diagnose and fix chat list bugs in the Focus fork of TelegramSwift. Use when chats are missing, disappear on scroll, the list doesn't fill the screen, pagination behaves wrong, or the empty state shows unexpectedly. Covers the two-layer filter pipeline (DB pagination + client-side category filter) and known failure modes.
---

# Focus Fork: Chat List Debugging

## Pipeline overview

```
chatListViewForLocation (DB/server)
  → update.list.items        ← paginated window of EngineChatList.Item
  → prepare (client filter)  ← focus category filter applied here
  → mapped (UIChatListEntry) ← empty/loading placeholder appended if needed
  → entries (sorted)         ← wrapped in AppearanceWrapperEntry
  → prepareEntries()         ← TableUpdateTransition
  → enqueueTransition()      ← merged into tableView
```

Key files:
- `ChatListController.swift` — signal pipeline, filtering, scroll handler, `enqueueTransition`
- `FocusMode.swift` / `FocusCategoryStripController.swift` — `FocusCategory` enum, strip UI
- `ChatListEmptyRowItem.swift` — empty / loading / section-header row items

## Two-layer filtering

**Layer 1 – DB pagination** (`ChatListIndexRequest`):
- `.Initial(count, scrollState)` — loads the first N items from the local DB
- `.Index(index, scrollState)` — loads a window around a specific `EngineChatList.Item.Index`
- Controlled by `FilterData.request`; triggered via `updateFilter { $0.withUpdatedRequest(...) }`

**Layer 2 – client-side category filter** (inside the `list` signal, ~line 1078):
```swift
prepare = prepare.filter { item, addition in
    switch currentCategory {
    case .inbox:  return !isChannel
    case .pinned: return isPinned && !isChannel
    case .digest: return isChannel
    ...
    }
}
```
`currentCategory` is read from `activeCategoryAtomic` (thread-safe; updated in `activeCategoryDidChange()`).

## Known bug patterns

### List doesn't fill the screen / mouse scroll doesn't load more
**Cause**: Layer 1 fetches N items; Layer 2 filters many out (e.g. channels stripped from Inbox). Remaining rows don't overflow the table height. Trackpad elastic scroll fires the scroll handler; mouse wheel does not.

**Fixes applied**:
1. Request a larger initial batch in `activeCategoryDidChange()`:
   ```swift
   let initialCount = max(Int(context.window.frame.height / 40) + 10, 30)
   updateFilter { $0.withUpdatedRequest(.Initial(initialCount, nil), ...) }
   ```
2. Auto-paginate via `focusFillIfNeeded()` called directly (synchronously) from `enqueueTransition`:
   - Check `tableView.listHeight < tableView.frame.height && documentOffset.y == 0`
   - If `previousChatList.hasEarlier`, call `updateFilter { $0.withUpdatedRequest(.Index(firstItem.index, nil), ...) }`
   - **No `requestTimestamp` rate-limit** — the signal pipeline on `prepareQueue` is the natural throttle.
   - **Do NOT wrap in `DispatchQueue.main.async`** — call directly; `merge()` has already updated `listHeight`.

**Subtle trap — requestTimestamp rate-limit blocks first fill on tab switch**:  
`withUpdatedRequest(..., removeAnimation: true)` stamps `requestTimestamp = CACurrentMediaTime()`.  
On repeat tab visits the cached signal comes back in ~100 ms. A rate-limit of `ts + 0.3 > now` will  
block `focusFillIfNeeded` every time. On first app start it works because the initial `FilterData`  
is created much earlier (> 0.3 s before the first transition). Remove the rate-limit entirely.

**Critical — never call `updateFilter` from `focusFillIfNeeded` on every transition**:  
The scroll handler has its own `requestTimestamp + 0.5 > now` cooldown (line ~1472). Every
`updateFilter(..., removeAnimation: true)` resets that timestamp. If `focusFillIfNeeded` fires
on EVERY `enqueueTransition` (not just after category changes), it continuously resets the
cooldown → scroll handler is perpetually blocked. Worse: each call cancels and restarts the
`chatHistoryView` signal subscription (`filterSignal |> mapToSignal`) — the subscription never
completes so no new items are delivered ("not all chats loaded").

**The correct fix — large `.Initial` count, no auto-fill machinery**:
Any attempt at post-transition auto-fill (calling `updateFilter` inside `enqueueTransition`) is
fundamentally unsafe: live chat-update signals fire during the fill phase, trigger new
`enqueueTransition` calls, and cause each fill attempt to cancel the previous subscription
(`filterSignal |> mapToSignal` restarts on every `updateFilter` call). The fill never completes.

The correct solution: **request 200 items upfront** with `.Initial(200, nil)`. The local DB
query is fast. Even if 80 % of items are channels and get filtered out, 40 items remain —
enough to fill any screen. No pagination loop, no `requestTimestamp` pollution.

```swift
// In activeCategoryDidChange():
updateFilter { $0.withUpdatedRequest(.Initial(200, nil), removeAnimation: true).withUpdatedIsTop(true) }
```

### Archive tab shows all inbox chats instead of archived chats

**Cause**: `case .archive: return !isChannel` in the category filter passes all non-channel
root-list items through — the same set as Inbox. Archived chats live in `EngineChatList.Group.archive`,
a **separate DB group** that is NOT in `update.list.items` for the root controller. They appear
only as a group-summary row (`update.list.groupItems`) appended separately when `currentCategory == .archive`.

**Fix**: `case .archive: return false` — exclude all main-list items; let the group row do the work.

### Pinned chat disappears when scrolling on the Pinned tab
**Cause**: Pinned chats live at the top of the DB sort order. The scroll handler calls `.Index(view.items.first?.index, nil)`, loading an *older time window* that doesn't contain pinned items. Layer 2 keeps nothing → `mapped` is empty → empty state is shown.

**Fix applied**: Guard the scroll handler when `activeCategory == .pinned`:
```swift
if self?.activeCategory == .pinned { return }
```
Pinned chats are always included in the initial load; no scroll pagination is needed.

### Empty state flickers when switching tabs
**Cause**: `activeCategoryAtomic` is swapped synchronously, but the `list` signal fires on `prepareQueue`. If the signal fires before the new filter data arrives, `prepare` may be momentarily empty under the new category.

**Mitigation**: `updateFilter` stamps `requestTimestamp = CACurrentMediaTime()`. The transition pipeline checks `requestTimestamp + 2 > CACurrentMediaTime()` to suppress animation during the reload window.

## Useful properties / methods

| Symbol | Where | Purpose |
|---|---|---|
| `activeCategory` | `ChatListController` | Current `FocusCategory`; setting it calls `activeCategoryDidChange()` |
| `activeCategoryAtomic` | `ChatListController` | Thread-safe read on `prepareQueue` |
| `previousChatList` | `ChatListController` | `Atomic<EngineChatList?>` — last emitted DB window |
| `update.list.hasEarlier` | signal pipeline | More older items exist in DB (scroll down to load) |
| `update.list.hasLater` | signal pipeline | More newer items exist in DB (scroll up to load) |
| `tableView.listHeight` | `TableView` | Sum of all rendered row heights |
| `tableView.documentOffset.y` | `TableView` | Current scroll position (0 = at top) |
| `focusFillIfNeeded()` | `ChatListController` | Auto-pagination guard — call after transitions |

## Scroll handler logic

```
scroll.direction == .bottom + view.hasEarlier  →  load older items (.Index(items.first?.index))
scroll.direction == .top    + view.hasLater    →  load newer items (.Index(items.last?.index))
```
"Earlier" = older chats (appear lower in the list).  
"Later" = newer chats (appear higher in the list).

Pinned chats are sorted above all regular chats regardless of their activity timestamp. An `.Index`-based request using a regular chat's index will **not** include pinned chats in the result window.
