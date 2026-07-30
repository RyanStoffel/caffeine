# Caffeine ☕

A tiny, lightweight, free and open source macOS menu bar app that keeps your Mac's display awake indefinitely.

Click the coffee cup in the menu bar to toggle:

- ☕ **Filled cup** — Active. Keeps your screen awake using native macOS `caffeinate -d` with a smooth liquid rise animation.
- 🫖 **Empty cup** — Inactive. Standard system sleep settings apply.

No account needed, no telemetry, no background noise.

---

## Installation

### Homebrew (Recommended)

```sh
brew install ryanstoffel/tap/caffeine
```

---

## Features

- **Liquid Fill Animation:** Liquid fills or drains smoothly inside the cup icon when toggling.
- **Steam Wisps & Sound:** Brief steam puff on activation with audio feedback.
- **Awake Timer:** Right-click the menu bar icon to view how long your screen has been kept awake.
- **Launch at Login:** Toggle auto-start at login right from the menu bar menu.
- **Light & Dark Mode:** Adapts automatically to your macOS system theme.

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
