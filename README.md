# freebuff-fedora-installer

An unofficial, one-command installer for [Freebuff](https://freebuff.com) on Fedora and other RPM-based Linux distributions (x86_64).

```bash
curl -fsSL https://raw.githubusercontent.com/habibsnippets/freebuff-fedora-installer/main/install.sh | bash
```

That's it. Freebuff appears in your app drawer and `freebuff` works from the terminal. No root, no `sudo`.

> Prefer to read before you run? Clone the repo and run `./install.sh`. The script is under 80 lines.

## Why this exists

Freebuff's download page offers builds for macOS, Windows and Linux, but the Linux options are a **`.deb`** (Debian/Ubuntu) and an **AppImage**. There is no `.rpm`, no Fedora package, no `dnf` repository, and no installer script for RPM-based systems.

On Fedora that leaves a few awkward paths:

- **The `.deb` can't be installed directly.** Fedora has no `dpkg` and `rpm` refuses `.deb` files. You can unpack it by hand with `ar` and `tar`, but then nothing registers the app: no launcher, no icon, no app-drawer entry.
- **The package's install script is written for Debian.** It runs as root, calls `update-alternatives`, and sets the Chromium sandbox helper setuid root. Running that blindly on a different distro isn't something I wanted to do, and it shouldn't be something you have to audit yourself.
- **The AppImage is a working alternative,** but it isn't integrated with the desktop either, and it needs FUSE and a manual `chmod +x`. If you're happy with that, use it. This repo is for people who want a normal installed app.

So this script does the manual route properly: it fetches the official `.deb`, unpacks it, checks it, and installs it for your user with a proper launcher and icon.

## What the script does

1. Downloads the official Freebuff `.deb` from `freebuff.com` (which redirects to the vendor's release on GitHub). The script refuses to continue if the download ends up anywhere else.
2. Unpacks it into a temporary folder. **No script inside the package is executed.**
3. Checks that it is the `freebuff` package for `amd64`, and verifies every file against the package's own `md5sums`.
4. Aborts if the package contains files outside `opt/Freebuff` and `usr/share`, or any setuid/setgid file.
5. Installs to your home directory:

   | What | Where |
   |---|---|
   | App | `~/.local/opt/Freebuff/` |
   | Launcher | `~/.local/share/applications/freebuff.desktop` |
   | Icon | `~/.local/share/icons/hicolor/512x512/apps/freebuff.png` |
   | Command | `~/.local/bin/freebuff` |

The setuid sandbox helper is deliberately **not** made setuid. Chromium falls back to user namespaces, which Fedora enables by default.

## Usage

```bash
./install.sh                    # download the official .deb and install
./install.sh ~/Downloads/x.deb  # install a .deb you already have
./install.sh --uninstall        # remove everything the installer created
```

To upgrade, run the installer again.

Requirements (all present on a default Fedora Workstation): `bash`, `curl`, `tar`, `coreutils`, and `ar` (from `binutils`; `sudo dnf install binutils` if missing). Make sure `~/.local/bin` is on your `PATH` if you want to run `freebuff` from a terminal.

## Good to know

- **Auto-update won't work.** The app's built-in updater is configured for `.deb` installs. Re-run this installer to upgrade.
- **Integrity, not authenticity.** The checks above catch a corrupted or tampered-with package, but the `md5sums` ship inside the package itself, and Freebuff doesn't publish a separate signature or checksum. You are trusting the download from `freebuff.com`, the same as if you'd downloaded it yourself.
- **Freebuff is an AI coding agent.** It can run commands and edit files on your machine. Decide for yourself whether you trust it; installing it per-user at least keeps the installation step itself out of root.
- **x86_64 only.** ARM64 isn't supported by this script yet.
- **Tested on Fedora (x86_64)** with Freebuff 0.0.204. Other RPM-based distros should work but are untested.

## Disclaimer

This project is not affiliated with or endorsed by Freebuff, Inc. It contains no Freebuff software. It only downloads the official package from the vendor and installs it on your machine. Freebuff is subject to its own terms. The installer script is MIT licensed.
