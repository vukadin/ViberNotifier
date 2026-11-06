# Viber Notifier

A macOS menu bar app that mirrors the Rakuten Viber desktop app’s Dock badge. The red badge shows single-digit counts and displays `9+` for larger counts.

## Requirements

- macOS 12 or later
- The Rakuten Viber desktop app
- Xcode to build from source

## Build

From the project folder, run:

```sh
./scripts/build-viber-notifier.sh
```

You can also open `ViberNotifier.xcodeproj` in Xcode and select the **Viber Notifier** scheme. Xcode resolves Swift Package Manager dependencies on the first build. The project currently fetches SwiftUI-Introspect over GitHub SSH.

The script creates `dist/Viber Notifier.app` and `dist/Viber Notifier.zip`. It signs the app ad hoc for local use. `dist/` is ignored by Git.

## Install and use

1. Move `Viber Notifier.app` to Applications and open it.
2. In **System Settings → Privacy & Security → Accessibility**, enable **Viber Notifier**. On some macOS versions the pane is called **Device Control and Data Access**. If an updated build stops showing counts, re-add the app from Applications and relaunch it.
3. In Viber, turn on **Settings → Notifications → Show notification effects → Unread badge**.

Click the menu bar icon to open Rakuten Viber. Right-click or Option-click for Quit and, when needed, the Accessibility settings shortcut.

## Credits

Based on [Doll](https://github.com/xiaogdgenuine/Doll) by xiaogdgenuine and contributors. This project uses artwork from the installed Rakuten Viber app. Review [Viber’s Terms of Service](https://www.viber.com/en/terms/viber-terms-use/) before sharing a build or the assets.
