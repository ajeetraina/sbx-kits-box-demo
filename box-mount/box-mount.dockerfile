# syntax=docker/dockerfile:1
# check=skip=SecretsUsedInArgOrEnv
# (BOX_ACCESS_TOKEN below is the literal sentinel "proxy-managed", not a real
#  secret — the sbx proxy swaps in the real token outbound. Lint false positive.)
#
# Box Mount overlay — carries the private box-mount client and the runtime ENV.
#
# A v3 mixin carries an overlay, so the binary ships here and lands on ANY base.
# Because this is an overlay (not a root filesystem), there is NO ENTRYPOINT —
# the base workload's launch command stays and the user/agent runs box-mount
# from the shell.
#
# The box-mount binary (~20–34 MB) is private/confidential (Box preview) and is
# git-ignored — stage it under this kit's own build context before building:
#   box-mount/bin/linux/amd64/box-mount   (linux/amd64)
#   box-mount/bin/linux/arm64/box-mount   (linux/arm64)
# A kit's build context is rooted at its own directory, so the binary must live
# inside box-mount/ (the kit cannot reach files outside its own tree).
#
# TARGETARCH is amd64 or arm64, set automatically per platform by buildx, so a
# single `--platform linux/amd64,linux/arm64` build bakes the right binary into
# each arch. The sbx runtime does NOT emulate, so the arch must match the host.

# FROM scratch keeps the layer purely the binary below plus the ENV, which rides
# in the image config. The frontend stages the descriptor as a content layer
# alongside it.
FROM scratch
ARG TARGETARCH

# v0.4.0 note: the `mount` command self-invokes a helper executable named
# `box-mount` on PATH (the sync engine), so the binary MUST be installed under
# that name or `mount` fails with FileNotFoundError. We also install an
# `agent-mount` alias so the older CLI surface keeps working. COPY --chown/--chmod
# sets ownership (root:root) and mode at copy time — the overlay-ownership audit
# requires every owner be 0/0 or 1000/1000.
COPY --chown=root:root --chmod=0755 bin/linux/${TARGETARCH}/box-mount /usr/local/bin/box-mount
COPY --chown=root:root --chmod=0755 bin/linux/${TARGETARCH}/box-mount /usr/local/bin/agent-mount

# environment.variables → ENV (must be on the recipe's final stage to merge at
# assembly). This is the sentinel box-mount reads to build its `Authorization:
# Bearer` header; the sbx proxy rewrites that header to the real token on
# outbound Box requests (see credential@1 in box-mount.yaml), so the real token
# never enters the container.
ENV BOX_ACCESS_TOKEN="proxy-managed"
