# Caffeine

A tiny, free and open source macOS menu bar app that keeps your display awake.

Click the coffee cup in the menu bar to toggle it:

- **Filled cup** — active, the display stays on (runs `caffeinate -d`) with a liquid rise & pop animation
- **Empty cup** — off, nothing running

Right-click the icon to quit. No accounts, no settings, no background nonsense.

## Build & Install

Requires Xcode command line tools.

```sh
cd ~/Developer/personal/caffeine
./build.sh            # builds .build/Caffeine.app
./build.sh --install  # builds and copies to /Applications
```

Then launch Caffeine from `/Applications` or Spotlight. To start it automatically at login, add it
under **System Settings → General → Login Items**.

## License

MIT
