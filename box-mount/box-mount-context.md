## Box Mount: two-way folder sync

The `box-mount` CLI is installed on PATH (with an `agent-mount` alias) and your
Box access token is injected by the sbx proxy as the `Authorization: Bearer`
credential on requests to api.box.com / upload.box.com / dl.boxcloud.com. The
BOX_ACCESS_TOKEN env var holds the sentinel "proxy-managed", NOT the real token.

Mount a Box folder into a local directory and keep it in two-way sync:

    # <local-dir>: absolute path to sync into
    # <box-id>:    the folder id (the number at the end of the folder URL on box.com; root = 0)
    box-mount mount "/home/agent/workspace/box" "123456789"
    box-mount status
    box-mount unmount "/home/agent/workspace/box"

Important:
 - Auth is pre-wired through the proxy. Do NOT run `box-mount config` and do
   NOT write ~/.box-mount/box-config.json — that would override the proxy token.
 - OAuth/developer tokens are short-lived. If sync starts failing with auth
   errors, the host must refresh the secret (`sbx secret set box <new-token>`)
   and recreate the sandbox.
 - Avoid atomic-save (temp-file + rename) edits inside the mount; they break Box
   file version history.
