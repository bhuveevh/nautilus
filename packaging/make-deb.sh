#!/usr/bin/env bash
#
# make-deb.sh — stage the built OpentiaFiles and wrap it in a .deb.
# Run from the Nautilus source root, after `ninja -C builddir` has succeeded.
#
set -euo pipefail

PKG="opentiafiles"
VER="$(sed -n 's/^Major Changes in \([0-9][^ ]*\).*/\1/p' NEWS | head -1)"
VER="${VER:-1.0}"
ARCH="$(dpkg --print-architecture)"
PREFIX="/usr"

echo "==> Staging into pkgroot (version $VER, arch $ARCH)"
DESTDIR="$PWD/pkgroot" ninja -C builddir install

echo "==> Computing runtime dependencies (dpkg-shlibdeps)"
DEPS=""
if command -v dpkg-shlibdeps >/dev/null 2>&1; then
  mkdir -p debian
  cat > debian/control <<'EOF'
Source: opentiafiles
Priority: optional
Maintainer: Bhuvee Paswan <bhuveepaswan@gmail.com>
Standards-Version: 4.6.0
Package: opentiafiles
Architecture: any
Description: OpentiaFiles file manager
EOF
  cat > debian/changelog <<EOF
opentiafiles (1.0) unstable; urgency=low

  * Local build.

 -- Bhuvee Paswan <bhuveepaswan@gmail.com>  $(date -R)
EOF
  DEPS="$(dpkg-shlibdeps -O \
      pkgroot/usr/bin/opentia-files \
      $(ls pkgroot/usr/lib/*/libnautilus-extension.so.* 2>/dev/null || true) \
      $(ls pkgroot/usr/lib/*/nautilus/extensions-*/*.so 2>/dev/null || true) \
      2>/dev/null | sed -n 's/^shlibs:Depends=//p' || true)"
fi
# Fallback that tolerates both the pre- and post-t64 / tracker->tinysparql names
[ -n "$DEPS" ] || DEPS="libgtk-4-1 | libgtk-4-1t64, libadwaita-1-0, libglib2.0-0, libgnome-desktop-4-2 | libgnome-desktop-4-2t64, libtinysparql-3.0-0 | libtracker-sparql-3.0-0"
echo "    Depends: $DEPS"

echo "==> Writing control metadata"
mkdir -p pkgroot/DEBIAN
SIZE="$(du -sk "pkgroot$PREFIX" | cut -f1)"
cat > pkgroot/DEBIAN/control <<EOF
Package: $PKG
Version: $VER
Architecture: $ARCH
Maintainer: Bhuvee Paswan <bhuveepaswan@gmail.com>
Installed-Size: $SIZE
Section: gnome
Priority: optional
Provides: nautilus
Conflicts: nautilus, nautilus-data
Replaces: nautilus, nautilus-data, libnautilus-extension4, gir1.2-nautilus-4.1, libnautilus-extension-dev
Depends: $DEPS
Description: OpentiaFiles - file manager with a Windows Explorer look
 OpentiaFiles is a fork of GNOME Files (Nautilus) whose chrome is arranged
 like Windows File Explorer: window controls on the right, a classic
 File/Edit/View/Go/Help menu bar, a New/Cut/Copy/Paste/Rename/Delete
 command bar and a squarer address bar. It registers itself as a handler
 for inode/directory and as the org.freedesktop.FileManager1 provider, so
 it can be used as the default file manager and in "Open With".
 .
 It replaces the distribution's Files (nautilus) package, which it Provides.
EOF

echo "==> Writing maintainer scripts"
cat > pkgroot/DEBIAN/postinst <<'EOF'
#!/bin/sh
set -e

APP_ID="io.github.bhuveevh.OpentiaFiles"
DESKTOP="$APP_ID.desktop"

if [ -x /usr/bin/update-desktop-database ]; then
  update-desktop-database -q /usr/share/applications 2>/dev/null || true
fi
if [ -x /usr/bin/glib-compile-schemas ]; then
  glib-compile-schemas /usr/share/glib-2.0/schemas 2>/dev/null || true
fi

# Make OpentiaFiles the system-wide default handler for folders.
mkdir -p /etc/xdg
[ -f /etc/xdg/mimeapps.list ] || : > /etc/xdg/mimeapps.list
if ! grep -q "^inode/directory=$DESKTOP" /etc/xdg/mimeapps.list; then
  if grep -q '^\[Default Applications\]' /etc/xdg/mimeapps.list; then
    sed -i "/^\[Default Applications\]/a inode/directory=$DESKTOP" /etc/xdg/mimeapps.list
  else
    printf '\n[Default Applications]\ninode/directory=%s\n' "$DESKTOP" >> /etc/xdg/mimeapps.list
  fi
fi

exit 0
EOF
chmod 0755 pkgroot/DEBIAN/postinst

cat > pkgroot/DEBIAN/prerm <<'EOF'
#!/bin/sh
set -e
exit 0
EOF
chmod 0755 pkgroot/DEBIAN/prerm

echo "==> Building the .deb"
OUT="${PKG}_${VER}_${ARCH}.deb"
dpkg-deb --build --root-owner-group pkgroot "$OUT"
ls -lh "$OUT"
