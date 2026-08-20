# User Guide

## Menu Bar Interface

DevPulse appears in your menu bar with a status indicator:

### Status Colors

| Color | State | Meaning |
|-------|-------|---------|
| 🟢 Green | Idle | Session ready, waiting for input |
| 🟣 Purple | Working | Tool executing |
| 🔵 Cyan | Thinking | Model reasoning |
| 🟠 Orange | Compacting | Context compression in progress |
| 🔴 Red | Error | Something went wrong |

## Session Management

### Switching Sessions

Click the menu bar icon to see a list of all active opencode sessions. Click on any session to switch to it.

### Session Details

Hover over a session to see:
- Token usage
- Context window consumption
- Duration
- Recent tool calls

## Subagent Tracking

When your main session spawns subagents, you'll see small dots next to the status bar. Hover over these dots to see details about each subagent.

## Question Handling

When opencode asks a question, DevPulse will show a popup in the menu bar. You can answer directly without switching to the terminal.
