# Installation Guide

## Requirements

- macOS 14.0 or later
- [opencode](https://github.com/opencode-ai/opencode) installed and running

## Install from DMG (Recommended)

1. Download `DevPulse.dmg` from the [latest release](https://github.com/albertjiayou0423/devpulse/releases/latest)
2. Open the DMG file
3. Drag DevPulse to your Applications folder
4. Launch from Applications

## Install from Source

```bash
# Clone the repository
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

## First Launch

After launching, you'll see DevPulse in your menu bar. The app will automatically detect your running opencode sessions.
