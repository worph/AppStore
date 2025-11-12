#!/bin/sh
# MetaMesh Pre-Install Cleanup Script
# Safely unmounts stale FUSE mounts and cleans up directories

set -e
echo "=== MetaMesh Pre-Install Cleanup ==="

# Function to safely unmount a path
safe_unmount() {
  local mount_point="$1"

  if mount | grep -q " $mount_point "; then
    echo "Found mount at $mount_point, attempting unmount..."

    # Try lazy unmount
    umount -l "$mount_point" 2>/dev/null && echo "  -> umount successful" || true

    # Try fusermount if available
    fusermount -uz "$mount_point" 2>/dev/null && echo "  -> fusermount successful" || true

    # Brief pause for unmount to complete
    sleep 1

    # Verify
    if mount | grep -q " $mount_point "; then
      echo "  -> WARNING: Failed to unmount $mount_point"
      return 1
    else
      echo "  -> Successfully unmounted $mount_point"
    fi
  else
    echo "No mount found at $mount_point"
  fi
  return 0
}

# Unmount all potential MetaMesh mount points
echo ""
echo "Checking for stale mounts..."
safe_unmount "/DATA/MetaMesh/Library" || true
safe_unmount "/DATA/MetaMesh" || true
safe_unmount "/mnt/data/user/MetaMesh/Library" || true
safe_unmount "/mnt/data/user/MetaMesh" || true

# Clean up directories
echo ""
echo "Cleaning up directories..."
if [ -d "/DATA/MetaMesh" ]; then
  if rm -rf /DATA/MetaMesh 2>/dev/null; then
    echo "  -> Removed /DATA/MetaMesh"
  else
    echo "  -> WARNING: Could not remove /DATA/MetaMesh (may have stale mount)"
    ls -la /DATA/MetaMesh 2>&1 || true
  fi
else
  echo "  -> /DATA/MetaMesh does not exist"
fi

# Final verification
echo ""
echo "Verifying cleanup..."
if mount | grep -i metamesh; then
  echo "  -> WARNING: MetaMesh mounts still present!"
  echo "  -> Manual cleanup may be required on the host system"
  echo "  -> Run: sudo umount -l /DATA/MetaMesh"
else
  echo "  -> All MetaMesh mounts cleared successfully"
fi

echo ""
echo "=== Cleanup Complete ==="
exit 0
