# BestMouseKeys

A macOS utility that drives the mouse from the numeric keypad. Built because the system's built-in Mouse Keys is slow, modal, and awkward to live in.

Requires macOS 13+ and Accessibility permission (needed to post synthetic mouse events).

## Building

The project is generated from `project.yml` via [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
xcodegen generate
xcodebuild -project BestMouseKeys.xcodeproj -scheme BestMouseKeys -configuration Debug build
```

Or open `BestMouseKeys.xcodeproj` in Xcode and build/run from there.

On first launch macOS will prompt for Accessibility permission. Grant it under **System Settings → Privacy & Security → Accessibility**.

## Key bindings

Numpad layout:

```
 7 (↖)   8 (↑)   9 (↗)   -  (right-click)
 4 (←)   5 (●)   6 (→)
 1 (↙)   2 (↓)   3 (↘)
 0 (drag toggle)   Enter (grid overlay)
```

| Key | Action |
|---|---|
| Numpad 1–4, 6–9 | Move cursor (20 pt per press) |
| Numpad 5 | Left-click — double-tap within 0.3 s for double-click |
| Numpad - | Right-click |
| Numpad 0 | Toggle drag (press to grab, press again to drop) |
| Numpad Enter | Show grid overlay — digits 1–9 jump the cursor to a screen cell, recursing on each press |
| Escape | Dismiss the grid overlay |

Numpad 0 (drag toggle) works inside the grid overlay too, so you can grab, warp via the grid, and drop.

While a drag is active, only the movement keys (1–4, 6–9) and Numpad Enter (grid overlay) keep the drag alive. Any other key — Numpad 5, Numpad -, Escape, or any non-numpad key — ends the drag, so you can't accidentally leave the synthetic mouse button held when you switch tasks. Non-numpad keys still reach the focused app after the drop.

## Resetting Accessibility permission

If the app stops working after a rebuild or signing identity change, macOS may be holding a stale Accessibility entry. Reset it with:

```bash
tccutil reset Accessibility com.amypellegrini.BestMouseKeys
```

To clear every TCC permission for the app:

```bash
tccutil reset All com.amypellegrini.BestMouseKeys
```

Relaunch the app afterward — macOS will prompt again and a fresh entry will appear in **System Settings → Privacy & Security → Accessibility** once you re-grant.
