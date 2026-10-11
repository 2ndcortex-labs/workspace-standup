# Buzz.app — where to get it and how to verify it

Buzz.app is the desktop app that ships the relay tooling the standup needs:
the `buzz` client and the git credential helper that lets git speak to the
relay.

## Source

Releases of `github.com/block/buzz`. Desktop releases are tagged
`desktop-v<version>`; the latest at the time of writing is `desktop-v0.5.23`,
released 2026-09-05.

macOS artifacts:

- `Buzz_<version>_aarch64.dmg` — Apple Silicon
- `Buzz_<version>_x64.dmg` — Intel

Or install the same app from the official Homebrew cask:

```
brew install --cask block-buzz
```

There is no published checksum file for the release artifacts. The project's
updater artifacts carry Tauri signatures that the app verifies itself, so the
check you run by hand is the notarization check below, not a hash comparison.

## Verify the installed app

Both of these must pass before you trust the app:

```
codesign --verify --deep --strict /Applications/Buzz.app
spctl --assess --type execute /Applications/Buzz.app
```

The app is Apple-notarized under Developer ID team `EYF346PHUG`, bundle id
`xyz.block.buzz.app`. If either command reports a failure, do not use the
copy — remove it and install again from the source above.

## The bundled binaries

The standup uses four binaries from inside the bundle, at
`/Applications/Buzz.app/Contents/MacOS/`:

- `buzz` — the client used to join a group and post
- `buzz-acp` — the agent client protocol bridge
- `buzz-agent` — the agent runner
- `git-credential-nostr` — the git credential helper that authenticates
  fetches against the relay, given a key file by path

Point git at the helper by its full path; it reads the key file named by
`git config nostr.keyfile`, so no key is ever opened by hand.
