#!/usr/bin/env bash
# OPTIONAL - stage a MOCK box-mount so you can practice the build / validate /
# compose / kit-tck mechanics WITHOUT the real Box private-preview binary.
#
#   ./scripts/stage-mock-binary.sh
#
# The mock is a tiny shell script that answers `--version` and explains itself.
# It is enough to make the overlay build, the descriptor validate, the kit
# compose onto a workload, and kit-tck run - but it does NOT sync with Box.
# For real two-way sync, replace it with the genuine binary from Box (see the
# README, "Lab 4: Get a Box token and stage the client").
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"

for arch in amd64 arm64; do
  dir="$repo_root/box-mount/bin/linux/$arch"
  mkdir -p "$dir"
  cat > "$dir/box-mount" <<'STUB'
#!/usr/bin/env bash
# MOCK box-mount (workshop placeholder - NOT the real Box client).
case "${1:-}" in
  --version|version) echo "box-mount 0.4.0 (MOCK - workshop placeholder)";;
  mount)   echo "MOCK: would mount Box folder '${3:-?}' at '${2:-?}' (no real sync)";;
  status)  echo "MOCK: no real mounts (this is the workshop placeholder binary)";;
  unmount) echo "MOCK: would unmount '${2:-?}'";;
  *)       echo "MOCK box-mount: unknown command '${*:-}'. Try --version." >&2; exit 2;;
esac
STUB
  chmod +x "$dir/box-mount"
  echo "staged mock: box-mount/bin/linux/$arch/box-mount"
done

cat <<EOF

Mock binaries staged for amd64 and arm64. You can now run every build/validate
step in the workshop. Two-way sync will NOT work until you replace these with
the real Box box-mount binary. Remove the mocks with:
  rm -rf box-mount/bin
EOF
