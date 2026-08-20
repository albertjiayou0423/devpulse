# DevPulse

**Your code's heartbeat, always in sight.**

A macOS menu bar app that monitors your [opencode](https://github.com/opencode-ai/opencode) sessions in real-time.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-orange)
![License: MIT](https://img.shields.io/badge/license-MIT-blue)
![Version](https://img.shields.io/badge/version-0.1.0-green)
[![Patreon](https://img.shields.io/badge/support-patreon-orange?logo=patreon&logoColor=white)](https://www.patreon.com/cw/huo_sai)

**English** | [中文](./README_zh.md)

## Features

- **Real-time monitoring** — Watch your opencode sessions as they run
- **Status indicators** — Visual feedback for working, thinking, idle, compacting, and error states
- **Subagent tracking** — See all child sessions with hover-to-inspect details
- **Token usage** — Track context window consumption at a glance
- **Question handling** — Respond to opencode questions directly from the menu bar
- **Glass-morphism HUD** — Beautiful status list interface

## Installation

### Quick Start

1. Download `DevPulse.dmg` from [Releases](https://github.com/albertjiayou0423/devpulse/releases/latest)
2. Open the DMG and drag DevPulse to Applications folder
3. Launch from Applications folder

### From Source

```bash
# Clone the repo
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

### Requirements

- macOS 14.0+
- [opencode](https://github.com/opencode-ai/opencode) installed and running

## How It Works

DevPulse reads from opencode's SQLite database at `~/.local/share/opencode/opencode.db` to track:

- Session states (idle, working, thinking, compacting, error)
- Token usage and context window consumption
- Subagent relationships and status
- Tool calls and their outcomes

## Status Colors

| Color | State | Meaning |
|-------|-------|---------|
| 🟢 Green | Idle | Session ready, waiting for input |
| 🟣 Purple | Working | Tool executing |
| 🔵 Cyan | Thinking | Model reasoning |
| 🟠 Orange | Compacting | Context compression in progress |
| 🔴 Red | Error | Something went wrong |

## Development

### Build

```bash
# Compile
swiftc -O Sources/OpenCodeMonitor/main.swift -o OpenCodeMonitor \
  -Xlinker -lsqlite3 -framework Cocoa -framework ServiceManagement

# Deploy and restart
cp OpenCodeMonitor OpenCodeMonitor.app/Contents/MacOS/OpenCodeMonitor
pkill -9 OpenCodeMonitor 2>/dev/null; sleep 0.5
open OpenCodeMonitor.app
```

### Create DMG Installer

```bash
hdiutil create -volname "DevPulse" -srcfolder OpenCodeMonitor.app -ov -format UDZO DevPulse.dmg
```

### Project Structure

```
devpulse/
├── Sources/
│   └── OpenCodeMonitor/
│       └── main.swift          # Main app source (~3300 lines)
├── OpenCodeMonitor.app/        # App bundle
├── branding.html               # Brand identity document
├── suggestions.html            # 100 improvement suggestions
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

Your support helps keep this project alive and enables new features.

## License

MIT © 2026

## Brand

See [branding.html](./branding.html) for the complete brand identity.

---

Built with ❤️ for developers who care about the rhythm of their code.
