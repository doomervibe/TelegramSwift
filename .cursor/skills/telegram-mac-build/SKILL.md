---
name: telegram-mac-build
description: >-
  Builds the Telegram macOS app from this repo using Makefile and
  Telegram-Mac.xcworkspace. Use when the user asks to build, compile, or run
  xcodebuild for TelegramSwift, or when CLI builds fail on Telegram.xcodeproj
  alone (missing RLottie) or on code signing.
---

# Telegram macOS build

## Default command

From the repository root:

```bash
make build
```

This runs `xcodebuild` on **`Telegram-Mac.xcworkspace`** (not `Telegram.xcodeproj` alone). The workspace pulls in **RLottie**, Sparkle, CodeSyntax, etc. Building only the `.xcodeproj` can fail with **Unable to find module dependency: 'RLottie'** for `TelegramShare`.

## Signing

- **`make build`** — ad-hoc signing (`CODE_SIGN_IDENTITY=-`, signing not required). Use when there is no **Mac Development** certificate for the project team.
- **`make build-signed`** — normal Xcode signing; needs a valid team/cert configured like in the Xcode UI.

Override Xcode location if needed:

```bash
make build DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
```

## Clean

```bash
make clean
```

## Output

Built app path is under DerivedData, e.g.:

`~/Library/Developer/Xcode/DerivedData/Telegram-Mac-*/Build/Products/$(CONFIG)/Telegram.app`

## Makefile location

[`Makefile`](../../../Makefile) at the repo root defines `build`, `build-signed`, and `clean`.
