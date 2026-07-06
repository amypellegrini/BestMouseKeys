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
 4 (←)   5 (●)   6 (→)   +  (right-drag toggle)
 1 (↙)   2 (↓)   3 (↘)
 0 (left-drag toggle)   Enter (grid overlay)
```

| Key | Action |
|---|---|
| Numpad 1–4, 6–9 | Move cursor (20 pt per press) |
| Numpad 5 | Left-click — double-tap within 0.3 s for double-click |
| Numpad - | Right-click |
| Numpad 0 | Toggle left-button drag (press to grab, press again to drop) |
| Numpad + | Toggle right-button drag (press to grab, press again to drop) |
| Numpad Enter | Show grid overlay — digits 1–9 jump the cursor to a screen cell, recursing on each press |
| Escape | Dismiss the grid overlay |

Both drag toggles work inside the grid overlay too, so you can grab, warp via the grid, and drop. Only one button is ever held at a time: pressing either drag key while a drag is active drops it.

While a drag is active, only the movement keys (1–4, 6–9) and Numpad Enter (grid overlay) keep the drag alive. Any other key — Numpad 5, Numpad -, Escape, or any non-numpad key — ends the drag, so you can't accidentally leave the synthetic mouse button held when you switch tasks. Non-numpad keys still reach the focused app after the drop.

**Right-drag is niche.** Most macOS apps treat a right-button press-and-release as a request for the context menu and ignore drag motion between them. Right-button drag-and-drop is only meaningful in apps that explicitly support it (some 3D/CAD tools, a few file managers and games). In everything else, Numpad + will just open the context menu on drop.

## Known limitations

**Password and other secure text fields.** While a password field is focused,
macOS turns on *Secure Event Input* — an anti-keylogger feature that delivers
keystrokes straight to the focused app and withholds them from every event tap,
regardless of tap level or permission. BestMouseKeys reads the numpad through an
event tap, so it is dormant in that state: numpad keys fall through and type
their digits instead of moving or clicking the cursor.

This affects all event-tap-based utilities, and there is no entitlement that
opts out. When it happens the menu bar icon dims and the menu shows
*"Paused — a password field is focused"*. Click into a non-secure field (or
finish entering the password) and control resumes. Driving the mouse inside a
secure field would require a virtual HID device driver, which BestMouseKeys
does not ship.

A focused password field is the most common cause, but it is not the only one.
*Any* app can turn Secure Event Input on, and some leave it on longer than you'd
expect:

- **Terminals with "Secure Keyboard Entry."** Terminal.app and iTerm2 both have a
  "Secure Keyboard Entry" menu toggle that holds Secure Event Input on the whole
  time that terminal is the active app. Turn it off in the app's menu.
- **Apps that leak it.** Some apps (notably 1Password and other Electron-based
  password managers) occasionally fail to release Secure Event Input after their
  unlock / quick-access window closes, leaving it stuck on *globally* even when
  nothing is focused — so BestMouseKeys stays paused with no password field in
  sight. This is common after wake-from-sleep / unlock. Fully quitting the
  offending app releases it (only the process that turned Secure Event Input on
  can turn it off — no other app, BestMouseKeys included, can clear it).

### Auto-recovery

Because a leaked Secure Event Input can only be cleared by restarting the app
that leaked it, BestMouseKeys watches for the stuck state and recovers on its
own. When Secure Event Input has been continuously on for ~15s (longer than any
real password entry) while the numpad is meant to be active, and 1Password is
running in the background (not the frontmost app — so an actual master-password
entry is never interrupted), it quits and relaunches 1Password to release the
input. A 2-minute cooldown prevents it from bouncing the app repeatedly when the
input is legitimately held elsewhere (e.g. a web password field in a browser).

This is on by default; toggle it from the menu bar via **"Auto-recover stuck
Secure Input."** The 1Password bundle id is currently the only known leaker the
watchdog targets (see `SecureInputWatchdog.swift`).

To check whether Secure Event Input is the culprit and which kind, run:

```bash
swift -e 'import Carbon; print("Secure Event Input:", IsSecureEventInputEnabled())'
```

If it prints `true` while no password field is focused, an app is holding it.
If it stays `true` no matter which app is frontmost, an app has leaked it — quit
your password manager / terminals until it flips to `false`.

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
