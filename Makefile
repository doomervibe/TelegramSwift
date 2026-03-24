# Telegram macOS — build via workspace (includes RLottie, Sparkle, etc.)
# Usage:
#   make build          # ad-hoc signing (no Apple dev cert required)
#   make build-signed   # normal signing (requires team cert in Xcode)
#   make clean

.PHONY: build build-signed clean

XCODE          ?= xcodebuild
WORKSPACE      := Telegram-Mac.xcworkspace
SCHEME         := Telegram
CONFIG         ?= Debug
DEVELOPER_DIR  ?= /Applications/Xcode.app/Contents/Developer

# Single-line env + xcodebuild invocation
XCB = DEVELOPER_DIR=$(DEVELOPER_DIR) $(XCODE) -workspace $(WORKSPACE) -scheme $(SCHEME) -configuration $(CONFIG)

build:
	$(XCB) build \
		CODE_SIGN_IDENTITY="-" \
		CODE_SIGNING_REQUIRED=NO \
		CODE_SIGNING_ALLOWED=NO

build-signed:
	$(XCB) build

clean:
	$(XCB) clean
