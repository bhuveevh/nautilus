# Files (Nautilus) — Windows Explorer look

This is a fork of [GNOME Files / Nautilus](https://gitlab.gnome.org/GNOME/nautilus)
whose *chrome* has been rearranged to look like Windows File Explorer.

**The behaviour is unchanged.** Every action, keyboard shortcut, context menu,
extension and integration is stock GNOME. Only the *visual placement* of the
existing controls was changed, which is exactly what was asked for.

## What was changed

Only three source files were touched:

| File | Change |
|------|--------|
| `src/resources/ui/nautilus-toolbar.blp` | Window controls forced to the **right** (`minimize / maximize / close`). Back / Forward stay on the left, the breadcrumb **address bar** fills the middle and expands, and the **search** toggle moved to the right end — the Explorer order. |
| `src/resources/ui/nautilus-window.blp` | Added a classic **menu bar** (`File / Edit / View / Go / Help`) and a Windows-style **command bar** (`New / Cut / Copy / Paste / Rename / Delete / Properties`) below the title/address bar. Both drive existing GNOME actions (`app.*`, `win.*`, `view.*`, `slot.*`). |
| `src/resources/style.css` | Styling for the new menu bar and command bar, and a squarer (Explorer-like) address bar. |

### How the new controls are wired

Nothing new was implemented in C. The menu bar and command bar reuse actions
that Nautilus already exposes on the window:

* `app.new-window`, `app.quit`, `app.help`, `app.about` — application actions
* `win.new-tab`, `win.undo`, `win.redo`, `win.close-current-view`, `win.go-home` — window actions
* `view.cut`, `view.copy`, `view.paste`, `view.rename`, `view.move-to-trash`,
  `view.new-folder`, `view.select-all`, `view.properties`, `view.zoom-*`,
  `view.show-hidden-files` — the active files view's action group (Nautilus
  installs it on the window root with the `view.` prefix)
* `slot.back`, `slot.forward` — the active slot's navigation actions

Because these are the real actions, buttons disable themselves automatically
(e.g. Cut/Copy grey out when nothing is selected) and every keyboard shortcut
and right-click menu keeps working exactly as before.

## Building

Nautilus uses Meson. Install its build dependencies first, then:

```sh
meson setup builddir --prefix=/usr -Dtests=none
ninja -C builddir
sudo ninja -C builddir install
```

On Debian/Ubuntu the build dependencies can be pulled in with:

```sh
sudo apt build-dep nautilus
```

On Fedora:

```sh
sudo dnf builddep nautilus
```

Because this replaces the system `Files`, it is easiest to test it against a
throw-away prefix (`--prefix=$HOME/.local`) or inside a container / VM rather
than installing over your distro's copy.

## Notes / limitations

* This is a *look* change, not a full Explorer clone. Tabs, the sidebar, list
  and grid views, search, batch rename, properties and every other GNOME
  feature are untouched.
* For an even stronger Windows feel, a Windows-style GTK theme and icon pack
  (from e.g. gnome-look.org) can be layered on top of the system theme; that is
  separate from the changes in this fork.
* The changes were validated with the Blueprint compiler's parser, but the full
  application was not compiled in the environment where they were authored — do
  a build to confirm on your machine, and expect the usual GTK/meson dependency
  dance.

## Licence

Unchanged from upstream Nautilus: **GPL-2.0-or-later**.
