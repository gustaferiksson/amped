#!/usr/bin/env bash
# OPTIONAL. Lets Amped toggle lid-closed (clamshell) sleep WITHOUT a password
# prompt every time — and, crucially, lets "Auto-off at 20%" release clamshell
# mode while the lid is shut and nobody is around to type a password.
#
# It installs a tightly scoped sudoers rule that permits ONLY these two exact
# commands to run as root without a password. Nothing else.
#
# Undo any time with: ./scripts/disable-silent-mode.sh
set -euo pipefail

USER_NAME="$(id -un)"
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

cat > "$TMP" <<EOF
# Installed by Amped — passwordless toggling of clamshell (lid-closed) sleep.
# Remove with: sudo rm /etc/sudoers.d/amped
$USER_NAME ALL=(root) NOPASSWD: /usr/bin/pmset -a disablesleep 0, /usr/bin/pmset -a disablesleep 1
EOF

echo "Validating sudoers syntax…"
sudo visudo -cf "$TMP"

echo "Installing /etc/sudoers.d/amped (you'll be asked for your password)…"
sudo install -m 0440 -o root -g wheel "$TMP" /etc/sudoers.d/amped
sudo visudo -cf /etc/sudoers.d/amped

echo "✅ Silent lid control enabled. Amped will no longer prompt for the lid toggle."
