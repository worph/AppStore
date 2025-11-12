#!/bin/sh
# MetaMesh Pre-Install Cleanup Script
# Handles stale FUSE mounts by removing them at the filesystem level

echo "=== MetaMesh Pre-Install Cleanup ==="

# Check if /DATA/MetaMesh exists
if [ ! -e "/DATA/MetaMesh" ]; then
  echo "No previous installation found - clean state"
  exit 0
fi

echo "Found previous installation, cleaning up..."

# Check for stale mounts
if mount | grep -q " /DATA/MetaMesh"; then
  echo "Detected stale FUSE mount at /DATA/MetaMesh"

  # Try to unmount (will work if we have proper privileges)
  if umount -l /DATA/MetaMesh 2>/dev/null || fusermount -uz /DATA/MetaMesh 2>/dev/null; then
    echo "  -> Successfully unmounted"
    sleep 1
  else
    echo "  -> Could not unmount from this context"
    echo "  -> Attempting forceful directory removal..."

    # Force remove at filesystem level
    # Use --one-file-system to avoid crossing into the mount
    find /DATA/MetaMesh -mindepth 1 -maxdepth 1 ! -path "/DATA/MetaMesh/Library" -exec rm -rf {} + 2>/dev/null || true

    # Try to remove the Library directory - this will fail if mounted
    # but that's expected
    rmdir /DATA/MetaMesh/Library 2>/dev/null || {
      echo "  -> Library directory is still a mount point"
      echo "  -> Renaming to force Docker to recreate..."

      # Rename the directory so Docker can create a fresh one
      mv /DATA/MetaMesh /DATA/MetaMesh.old.$(date +%s) 2>/dev/null || {
        echo "  -> ERROR: Cannot clean up stale mount"
        echo "  -> Please run on your server: sudo umount -l /DATA/MetaMesh/Library && sudo rm -rf /DATA/MetaMesh"
        exit 1
      }
    }
  fi
fi

# Final cleanup
rm -rf /DATA/MetaMesh 2>/dev/null || true

# Verify
if mount | grep -q " /DATA/MetaMesh"; then
  echo ""
  echo "ERROR: Stale mount still present!"
  echo "Please run on your server host (not in container):"
  echo "  sudo umount -l /DATA/MetaMesh/Library"
  echo "  sudo rm -rf /DATA/MetaMesh"
  exit 1
fi

echo "Cleanup complete - ready for installation"
exit 0
