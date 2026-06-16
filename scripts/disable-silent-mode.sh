#!/usr/bin/env bash
# Removes the optional passwordless sudoers rule installed by enable-silent-mode.sh.
set -euo pipefail
echo "Removing /etc/sudoers.d/amped (you'll be asked for your password)…"
sudo rm -f /etc/sudoers.d/amped
echo "✅ Silent lid control removed. Amped will prompt for the lid toggle again."
