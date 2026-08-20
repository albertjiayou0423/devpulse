# Troubleshooting

## Common Issues

### DevPulse not detecting sessions

**Problem**: DevPulse shows "No active sessions"

**Solutions**:
1. Make sure opencode is running
2. Check that the database exists at `~/.local/share/opencode/opencode.db`
3. Restart DevPulse
4. Check Console.app for error messages

### Status bar not updating

**Problem**: Status bar is stuck on one state

**Solutions**:
1. Check polling interval in settings (default: 2s)
2. Restart DevPulse
3. Check if opencode database is locked

### HUD not appearing on hover

**Problem**: Hovering over status bar doesn't show details

**Solutions**:
1. Make sure you're hovering over the status bar, not the menu bar icon
2. Check system preferences for accessibility permissions
3. Restart DevPulse

### DMG won't open

**Problem**: "DevPulse.dmg" can't be opened

**Solutions**:
1. Right-click the DMG and select "Open"
2. Or use: `xattr -d com.apple.quarantine DevPulse.dmg`
3. Download the latest version from Releases

## Getting Help

If you're still having issues:

1. Check the [existing issues](https://github.com/albertjiayou0423/devpulse/issues)
2. Create a new issue with:
   - macOS version
   - DevPulse version
   - Steps to reproduce
   - Any error messages from Console.app
