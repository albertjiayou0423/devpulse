#!/bin/bash
# DevPulse Demo Recorder
# Usage: bash scripts/record-demo.sh
# Requires: ffmpeg (brew install ffmpeg)

set -e

OUTPUT_DIR="assets"
mkdir -p "$OUTPUT_DIR"

echo "🎬 DevPulse Demo Recorder"
echo "========================"
echo ""
echo "Instructions:"
echo "1. Make sure DevPulse is running in menu bar"
echo "2. Press ENTER to start recording (10 seconds)"
echo "3. During recording: hover over status bar, click menu, etc."
echo "4. GIF will be saved to $OUTPUT_DIR/demo.gif"
echo ""
read -p "Press ENTER to start..."

# Record 10 seconds of screen
echo "🔴 Recording... (10 seconds)"
ffmpeg -f avfoundation -framerate 15 -i "1" \
  -t 10 \
  -vf "fps=12,scale=800:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
  -loop 0 \
  "$OUTPUT_DIR/demo.gif" -y 2>/dev/null

echo ""
echo "✅ Saved: $OUTPUT_DIR/demo.gif"
echo "Size: $(du -h "$OUTPUT_DIR/demo.gif" | cut -f1)"
