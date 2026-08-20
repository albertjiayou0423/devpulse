# DevPulse

**Your code's heartbeat, always in sight.**

A macOS menu bar app that monitors your [opencode](https://github.com/opencode-ai/opencode) sessions in real-time.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-orange)
![License: MIT](https://img.shields.io/badge/license-MIT-blue)
![Version](https://img.shields.io/badge/version-0.1.1-green)
[![Patreon](https://img.shields.io/badge/support-patreon-orange?logo=patreon&logoColor=white)](https://www.patreon.com/cw/huo_sai)

**English** | [中文](./README_zh.md)

## Requirements

- macOS 14.0+
- [opencode](https://github.com/opencode-ai/opencode) installed and running

## Installation

### From DMG (Recommended)

1. Download `DevPulse.dmg` from [Releases](https://github.com/albertjiayou0423/devpulse/releases/latest)
2. Open the DMG and drag DevPulse to Applications folder
3. Launch from Applications

### From Source

```bash
git clone https://github.com/albertjiayou0423/devpulse.git
cd devpulse

# Build
swiftc -O Sources/OpenCodeMonitor/main.swift -o OpenCodeMonitor \
  -Xlinker -lsqlite3 -framework Cocoa -framework ServiceManagement

# Deploy to app bundle
cp OpenCodeMonitor OpenCodeMonitor.app/Contents/MacOS/OpenCodeMonitor

# Run
open OpenCodeMonitor.app
```

## Usage

Once installed and launched, DevPulse appears in your menu bar:

- **Status Bar** — Shows current session state with color-coded indicator
- **Session List** — Click to switch between opencode sessions
- **Subagent Dots** — Hover to see child session details
- **Question Popup** — Answer opencode questions directly from the menu bar

### Status Colors

| Color | State | Meaning |
|-------|-------|---------|
| 🟢 Green | Idle | Session ready, waiting for input |
| 🟣 Purple | Working | Tool executing |
| 🔵 Cyan | Thinking | Model reasoning |
| 🟠 Orange | Compacting | Context compression in progress |
| 🔴 Red | Error | Something went wrong |

## Features

- **Real-time monitoring** — Watch your opencode sessions as they run
- **Status indicators** — Visual feedback for all session states
- **Subagent tracking** — See all child sessions with hover-to-inspect details
- **Token usage** — Track context window consumption at a glance
- **Question handling** — Respond to opencode questions directly
- **Glass-morphism HUD** — Beautiful status list interface

## How It Works

DevPulse reads from opencode's SQLite database at `~/.local/share/opencode/opencode.db` to track:

- Session states (idle, working, thinking, compacting, error)
- Token usage and context window consumption
- Subagent relationships and status
- Tool calls and their outcomes

## Development

### Build

```bash
swiftc -O Sources/OpenCodeMonitor/main.swift -o OpenCodeMonitor \
  -Xlinker -lsqlite3 -framework Cocoa -framework ServiceManagement
```

### Create DMG Installer

```bash
# Install create-dmg
brew install create-dmg

# Create DMG with Applications shortcut and custom background
create-dmg \
  --volname "DevPulse" \
  --background "assets/dmg-background.png" \
  --window-pos 200 120 \
  --window-size 660 400 \
  --icon-size 128 \
  --icon "OpenCodeMonitor.app" 200 190 \
  --hide-extension "OpenCodeMonitor.app" \
  --app-drop-link 560 190 \
  "DevPulse.dmg" \
  "OpenCodeMonitor.app"
```

### Project Structure

```
devpulse/
├── Sources/
│   └── OpenCodeMonitor/
│       └── main.swift          # Main app source (~3300 lines)
├── OpenCodeMonitor.app/        # App bundle
├── assets/                     # DMG background and screenshots
├── README.md                   # English documentation
└── README_zh.md                # Chinese documentation
```

## Roadmap

- [ ] iOS companion app
- [ ] Session history timeline
- [ ] Token usage statistics
- [ ] Multi-project monitoring
- [ ] Dark/light theme support
- [ ] Keyboard shortcuts
- [ ] Export session data

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Support

If you find DevPulse useful, consider supporting the project:

<a href="https://www.patreon.com/cw/huo_sai">
  <img src="https://c5.patreon.com/external/logo/become_a_patron_button@2x.png" width="160">
</a>

## License

MIT © 2026

---

Built with ❤️ for developers who care about the rhythm of their code.
