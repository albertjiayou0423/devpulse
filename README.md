# DevPulse

Your code's heartbeat, always in sight.

A macOS menu bar app that monitors your [opencode](https://github.com/opencode-ai/opencode) sessions in real-time.

![DevPulse](https://img.shields.io/badge/macOS-14%2B-orange) ![License](https://img.shields.io/badge/license-MIT-blue)

## Features

- **Real-time monitoring** — Watch your opencode sessions as they run
- **Status indicators** — Visual feedback for working, thinking, idle, compacting, and error states
- **Subagent tracking** — See all child sessions with hover-to-inspect details
- **Token usage** — Track context window consumption at a glance
- **Question handling** — Respond to opencode questions directly from the menu bar
- **Beautiful HUD** — Glass-morphism interface that matches your workflow

## Installation

### From Source

```bash
# Clone the repo
git clone https://github.com/YOUR_USERNAME/devpulse.git
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

## Brand

See [branding.html](./branding.html) for the complete brand identity.

## Development

```bash
# Build
swiftc -O Sources/OpenCodeMonitor/main.swift -o OpenCodeMonitor \
  -Xlinker -lsqlite3 -framework Cocoa -framework ServiceManagement

# Deploy and restart
cp OpenCodeMonitor OpenCodeMonitor.app/Contents/MacOS/OpenCodeMonitor
pkill -9 OpenCodeMonitor 2>/dev/null; sleep 0.5
open OpenCodeMonitor.app
```

## Roadmap

- [ ] iOS companion app
- [ ] Session history timeline
- [ ] Token usage statistics
- [ ] Multi-project monitoring
- [ ] Dark/light theme support
- [ ] Keyboard shortcuts

## License

MIT © 2026

---

Built with ❤️ for developers who care about the rhythm of their code.
