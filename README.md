# molt-cua

Computer use for Molt agents. This is a Molt plugin that repackages the
[Cua Driver](https://github.com/trycua/cua) CLI and its agent skill. It holds
no driver code of its own.

## What it adds

- `cua-driver` on every agent's PATH, through `~/.moltcode/bin`. Agents drive
  native apps from the shell: `cua-driver list-tools`, `cua-driver describe
  <tool>`, `cua-driver call get_window_state '{...}'`.
- The upstream `cua-driver` skill, with a short note on how it runs inside
  Molt.

## How permissions work

Molt Code runs `cua-driver serve --embedded` itself, as a direct child of the
app, on a private socket. In embedded mode cua never relaunches through
LaunchServices and never shows its own permission panel, so macOS charges
Accessibility and Screen Recording to **Molt Code**. You grant them once, from
Molt's Plugins pane.

`bin/cua-driver` is a small launcher that points every CLI call at Molt's
daemon. It refuses `serve`, `stop`, `update`, `skills` and `permissions grant`,
so agents can't start a second daemon, self-update, or raise cua's own
prompts. Molt turns off cua's update check and telemetry for the daemon.

## Package layout

One npm-layout tarball per platform (`package/` root):

```
package/
  package.json        # manifest, molt.contributes: bin, skills, services
  bin/cua-driver      # Molt launcher
  dist/cua-driver     # upstream binary (universal on macOS)
  skills/cua-driver/  # upstream skill pack + Molt note
```

Platforms: `darwin-arm64` and `darwin-x64` share the universal tarball, plus
`linux-x64` and `linux-arm64`.

## Releasing

The pinned upstream release is `molt.upstream.tag` in `package.json`. To bump:

1. Change `molt.upstream.tag` and `version` in `package.json`.
2. Tag `v<version>` and push. The release workflow downloads the upstream
   assets, checks them against upstream `checksums.txt`, repacks them, and
   publishes the tarballs plus `artifacts.json` (url, sha256 and size per
   platform) for the Molt catalog.

`scripts/repack.sh` does the same locally, writing to `out/`.

Cua Driver is MIT licensed by Cua AI, Inc.
