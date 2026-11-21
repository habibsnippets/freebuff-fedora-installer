#!/usr/bin/env bash
# Unofficial per-user installer for Freebuff on Fedora / RPM-based distros (x86_64).
#
#   install.sh                      download the official .deb from freebuff.com and install
#   install.sh /path/to/file.deb    install a .deb you already downloaded
#   install.sh --uninstall          remove Freebuff
#
# No root needed. No script from the .deb is ever executed.
set -euo pipefail

PREFIX="${HOME}/.local"
APP_DIR="${PREFIX}/opt/Freebuff"
DESKTOP="${PREFIX}/share/applications/freebuff.desktop"
ICON="${PREFIX}/share/icons/hicolor/512x512/apps/freebuff.png"
BIN="${PREFIX}/bin/freebuff"
OFFICIAL_URL="https://freebuff.com/api/desktop/download/linux"   # redirects to the vendor's GitHub release

if [[ "${1:-}" == "--uninstall" ]]; then
  rm -rf "$APP_DIR" "$DESKTOP" "$ICON" "$BIN"
  update-desktop-database "${PREFIX}/share/applications" 2>/dev/null || true
  gtk-update-icon-cache -f -t "${PREFIX}/share/icons/hicolor" 2>/dev/null || true
  echo "Freebuff removed."; exit 0
fi

[[ "$(uname -m)" == "x86_64" ]] || { echo "Only x86_64 is supported by this installer."; exit 1; }
for t in ar tar md5sum curl; do
  command -v "$t" >/dev/null || { echo "Missing '$t' (try: sudo dnf install binutils tar coreutils curl)"; exit 1; }
done

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT

DEB="${1:-}"
if [[ -z "$DEB" ]]; then
  echo "Downloading the official Freebuff .deb from freebuff.com ..."
  FINAL="$(curl -fL --progress-bar --proto '=https' --tlsv1.2 -o "$W/freebuff.deb" -w '%{url_effective}' "$OFFICIAL_URL")"
  case "$FINAL" in
    https://github.com/CodebuffAI/*|https://release-assets.githubusercontent.com/*|https://objects.githubusercontent.com/*) ;;
    *) echo "Unexpected download host: $FINAL"; exit 1 ;;
  esac
  DEB="$W/freebuff.deb"
fi
[[ -f "$DEB" ]] || { echo "File not found: $DEB"; exit 1; }

mkdir "$W/raw" "$W/ctl" "$W/data"
(cd "$W/raw" && ar x "$(readlink -f "$DEB")")
[[ -f "$W/raw/debian-binary" ]] || { echo "Not a valid .deb"; exit 1; }
tar -xf "$W"/raw/control.tar.* -C "$W/ctl"
tar -xf "$W"/raw/data.tar.*    -C "$W/data"

grep -q '^Package: freebuff' "$W/ctl/control"    || { echo "This is not the Freebuff package"; exit 1; }
grep -q '^Architecture: amd64' "$W/ctl/control"  || { echo "Only the amd64 package is supported"; exit 1; }
(cd "$W/data" && md5sum -c --quiet "$W/ctl/md5sums") || { echo "Integrity check failed"; exit 1; }
# Refuse anything unexpected: paths outside opt/Freebuff and usr/share, or setuid/setgid files.
if tar -tf "$W"/raw/data.tar.* | grep -Ev '^\./(opt/Freebuff|usr/share)(/|$)|^\./(opt|usr)/?$|^\./$' | grep -q .; then
  echo "Package has unexpected paths; aborting"; exit 1; fi
if find "$W/data" -perm /6000 | grep -q .; then echo "Package has setuid/setgid files; aborting"; exit 1; fi

mkdir -p "${PREFIX}/opt" "${PREFIX}/bin" "$(dirname "$DESKTOP")" "$(dirname "$ICON")"
rm -rf "$APP_DIR"; cp -a "$W/data/opt/Freebuff" "$APP_DIR"
chmod 0755 "$APP_DIR/chrome-sandbox" 2>/dev/null || true   # no setuid: Chromium falls back to user namespaces
cp "$W/data/usr/share/icons/hicolor/512x512/apps/freebuff.png" "$ICON"
cat > "$DESKTOP" <<EOT
[Desktop Entry]
Name=Freebuff
Exec=${APP_DIR}/freebuff %U
Terminal=false
Type=Application
Icon=freebuff
StartupWMClass=Freebuff
Comment=Freebuff Desktop
MimeType=x-scheme-handler/freebuff;
Categories=Development;
EOT
ln -sf "$APP_DIR/freebuff" "$BIN"
update-desktop-database "${PREFIX}/share/applications" 2>/dev/null || true
gtk-update-icon-cache -f -t "${PREFIX}/share/icons/hicolor" 2>/dev/null || true
echo "Freebuff installed. Launch it from the app drawer or run: freebuff"
