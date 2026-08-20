# Development Guide

## Prerequisites

- macOS 14.0+
- Swift compiler
- Xcode Command Line Tools

## Building from Source

```bash
git clone https://github.com/albertjiayou0423/devpulse.git
cd devpulse

swiftc -O Sources/OpenCodeMonitor/main.swift -o OpenCodeMonitor \
  -Xlinker -lsqlite3 -framework Cocoa -framework ServiceManagement

cp OpenCodeMonitor OpenCodeMonitor.app/Contents/MacOS/OpenCodeMonitor
```

## Creating DMG Installer

```bash
brew install create-dmg

create-dmg \
  --volname "DevPulse" \
  --background "assets/dmg-background.png" \
  --window-pos 200 120 \
  --window-size 660 400 \
  --icon-size 128 \
  --icon "OpenCodeMonitor.app" 165 200 \
  --hide-extension "OpenCodeMonitor.app" \
  --app-drop-link 495 200 \
  "DevPulse.dmg" \
  "OpenCodeMonitor.app"
```

## Project Structure

```
devpulse/
├── Sources/OpenCodeMonitor/main.swift
├── OpenCodeMonitor.app/
├── assets/dmg-background.png
├── README.md
└── README_zh.md
```

## Architecture

DevPulse is a single-file Swift application that:
1. Reads from opencode's SQLite database
2. Polls for session state changes
3. Renders a menu bar UI with status indicators
4. Provides hover-based HUD for detailed information
