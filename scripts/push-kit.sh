#!/usr/bin/env bash
# Build and (optionally) push the Kit v3 Box Mount mixin (box-mount/) as ONE
# OCI image. BuildKit reads the descriptor's `# syntax=docker/sandbox-kit:3`
# line, pulls the kit frontend, validates the descriptor, builds the overlay
# (which bakes the private box-mount binary) and attaches the descriptor to the
# manifest. ONE artifact — no separate template to load.
#
#   ./scripts/push-kit.sh <namespace>              # push <ns>/sbx-kit-box-mount
#   DOCKERHUB_NAMESPACE=me ./scripts/push-kit.sh   # namespace via env
#   PUSH=0 ./scripts/push-kit.sh <namespace>       # build only, into an OCI layout (for kit-tck)
#   PLATFORMS=linux/arm64 ./scripts/push-kit.sh me # single-arch
#
# ⚠️  CONFIDENTIAL: the image EMBEDS the private box-mount binary. Only push to a
#     registry/repo you intend to be PRIVATE (or are cleared to publish). A
#     public image would expose the Box private-preview binary.
#
# Stage the private binaries inside the kit's build context first (git-ignored):
#   box-mount/bin/linux/amd64/box-mount   (linux/amd64)
#   box-mount/bin/linux/arm64/box-mount   (linux/arm64)
set -euo pipefail

namespace="${1:-${DOCKERHUB_NAMESPACE:-${DOCKER_NAMESPACE:-}}}"
if [ -z "$namespace" ]; then
  echo "push-kit: no namespace given." >&2
  echo "  Usage: $0 <namespace>   (or DOCKERHUB_NAMESPACE=<ns> $0)" >&2
  exit 1
fi

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
kit_dir="$repo_root/box-mount"
descriptor="box-mount.yaml"
image="docker.io/$namespace/sbx-kit-box-mount"
push="${PUSH:-1}"
platforms="${PLATFORMS:-linux/amd64,linux/arm64}"

command -v docker >/dev/null 2>&1 || { echo "push-kit: docker not found." >&2; exit 1; }
docker buildx version >/dev/null 2>&1 || { echo "push-kit: docker buildx not available." >&2; exit 1; }

# Read the descriptor's own `version:` so the pinned tag says what the image is.
version="$(sed -n 's/^version:[[:space:]]*"\{0,1\}\([0-9][^"]*\)"\{0,1\}[[:space:]]*$/\1/p' "$kit_dir/$descriptor")"
[ -n "$version" ] || { echo "push-kit: $descriptor has no version: field" >&2; exit 1; }

# Guard the confidential binary against an accidental public push.
if [ "$push" = "1" ] && [ "${I_KNOW_THIS_IS_PRIVATE:-}" != "1" ]; then
  cat >&2 <<EOF
push-kit: refusing to push without confirmation.
  The image EMBEDS the private box-mount binary. Push only to a PRIVATE repo.
  Re-run with I_KNOW_THIS_IS_PRIVATE=1 once you have confirmed $image is private:
    I_KNOW_THIS_IS_PRIVATE=1 $0 $namespace
EOF
  exit 1
fi

if [ "$push" = "1" ]; then
  docker buildx build "$kit_dir" -f "$kit_dir/$descriptor" \
    --platform "$platforms" --push --provenance=true \
    -t "$image:latest" -t "$image:$version"
  echo "Pushed $image :latest and :$version"
  echo
  echo "Compose onto a v3 workload, e.g.:"
  echo "  sbx run docker/sbx-kit-shell:1.0.0 --kit $image:$version ."
else
  layout="/tmp/sbx-kit-box-mount-layout"
  rm -rf "$layout"
  docker buildx build "$kit_dir" -f "$kit_dir/$descriptor" \
    --platform "$platforms" \
    -t "box-mount-kit:$version" \
    --output "type=oci,dest=$layout,tar=false"
  echo "Built $version into $layout"
  echo "  kit-tck validate --layout $layout $version"
fi
