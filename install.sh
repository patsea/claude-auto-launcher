#!/bin/bash
# Installation script for Claude Auto Launcher

set -e

INSTALL_DIR="$HOME/.claude-auto"
BASHRC="$HOME/.bash_profile"

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║     Claude Auto Launcher - Installation Script           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "→ Installing Claude Auto Launcher..."
echo ""

# Create installation directory
echo "  Creating installation directory: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"

# Copy files
echo "  Copying files..."
cp -r "$SCRIPT_DIR/bin" "$INSTALL_DIR/"
cp -r "$SCRIPT_DIR/lib" "$INSTALL_DIR/"

# Make scripts executable
echo "  Setting permissions..."
chmod +x "$INSTALL_DIR/bin/"*
chmod +x "$INSTALL_DIR/lib/"*

# Check if already installed in bash profile
if grep -q "# Claude Auto Launcher" "$BASHRC" 2>/dev/null; then
    echo ""
    echo "⚠️  Claude Auto Launcher is already in your $BASHRC"
    echo "   Skipping bash profile modification."
    echo ""
    echo "   To reinstall, remove the existing configuration first:"
    echo "   1. Edit $BASHRC"
    echo "   2. Remove the Claude Auto Launcher section"
    echo "   3. Run this install script again"
else
    # Add to bash profile
    echo ""
    echo "  Adding to $BASHRC..."
    cat >> "$BASHRC" << 'EOF'

# Claude Auto Launcher
# Quick navigation to Dropbox claude-code directory
alias ccode='cd ~/Dropbox/claude-code'

# Add Claude Auto Launcher to PATH
export PATH="$HOME/.claude-auto/bin:$PATH"

EOF

    echo ""
    echo "✓ Installation complete!"
fi

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                  Installation Summary                     ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "Installed to: $INSTALL_DIR"
echo ""
echo "Available commands:"
echo "  • claude-auto        - Start all services and Claude Code"
echo "  • claude-auto-stop   - Stop all services"
echo "  • claude-auto-status - Check service status"
echo "  • ccode              - Navigate to claude-code directory"
echo ""
echo "Next steps:"
echo "  1. Reload your shell:"
echo "     source ~/.bash_profile"
echo ""
echo "  2. Try it out:"
echo "     claude-auto"
echo ""
echo "Documentation: $SCRIPT_DIR/docs/USAGE.md"
echo ""
