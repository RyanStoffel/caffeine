# Caffeine ☕

A tiny, free, open source macOS menu bar app that keeps your Mac's display awake indefinitely.

Click the coffee cup in the menu bar to toggle:

- ☕ **Filled cup** — Active. Keeps your screen awake using the native macOS `caffeinate -d` command, with a liquid rise animation.
- 🫖 **Empty cup** — Inactive. Your normal system sleep settings apply.

No account, no telemetry, no background noise.

---

## Installation

### Homebrew (Recommended)

```sh
brew install ryanstoffel/tap/caffeine
```

Since Caffeine isn't notarized, macOS will block it the first time you open it. To get past this, go to **System Settings > Privacy & Security**, scroll down to the message about Caffeine, and click **Open Anyway**.

---

## Features

- **Liquid fill animation:** Liquid fills or drains inside the cup icon when you toggle.
- **Steam wisps & sound:** A steam puff and audio cue on activation.
- **Keep awake with lid closed:** Optionally keep your Mac running with the lid shut — handy for downloads, syncs, or an external display. Enable it from the menu; macOS asks for your password once, and normal sleep is restored when you turn it off or quit.
- **Awake timer:** Right-click the menu bar icon to see how long your Mac has been kept awake.
- **Launch at login:** Toggle auto-start from the menu bar menu.
- **Light & dark mode:** Adapts to your macOS system theme.

---

## Build from Source

Requires macOS 13.0+ and Xcode Command Line Tools.

```sh
git clone https://github.com/RyanStoffel/caffeine.git
cd caffeine
./build.sh --install
```

---

## License

[MIT](LICENSE)
