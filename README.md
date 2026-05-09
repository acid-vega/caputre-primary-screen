# aw_screen_capture

Linux desktop screen recorder using VLC (`cvlc`) with:

- automatic package installation
- primary monitor detection
- full desktop audio recording
- GNOME Flashback hotkeys
- desktop notifications
- automatic recovery / clean save on abort
- one-key stop/start handling
- automatic filename versioning
- backup/self-copy support

Designed for Debian GNU/Linux + GNOME Flashback.

---

# Features

## Recording

- records the **primary monitor**
- records **all system audio**
- uses VLC / H264 / MP4
- automatic fallback resolution:
  - `960x540` if monitor detection fails

---

## Hotkeys

| Key | Action |
|---|---|
| `SHIFT + F12` | Start recording |
| `SHIFT + F11` | Stop recording |

---

## Smart Restart

If recording is already running and you press:

```text
SHIFT + F12
```

again:

- previous recording is stopped cleanly
- current video is saved
- new recording starts automatically

---

# Notifications

When recording starts:

- desktop notification appears
- shows save location
- reminds:
  - `SHIFT + F11 = Stop`

When recording stops:

- desktop notification appears
- asks whether video should be opened immediately

---

# Save Location

Videos are stored in:

```text
/home/${USER}/grab-my-screen/
```

Filename format:

```text
${USER}-HOUR-DAY-YEAR-MONTHNAME-MONTH-YEAR-PART.mp4
```

Example:

```text
acid-vega-21-09-2026-May-05-2026-1.mp4
```

If file already exists:

```text
...-2.mp4
...-3.mp4
...
```

---

# Installed Commands

## Recorder

```bash
aw_screen_capture
```

## Stop Recording

```bash
aw_screen_capture_stop
```

Installed under:

```text
/usr/local/bin/
```

---

# GNOME Integration

Creates:

## Menu Category

```text
acidWEB
```

## Menu Entries

```text
Primary screenCapture
Stop screenCapture
```

---

# Requirements

Automatically installs if missing:

- vlc
- pulseaudio-utils
- x11-xserver-utils
- dbus-x11
- libnotify-bin
- notify-osd
- xdg-utils
- zenity

---

# Installation

## Clone

```bash
git clone https://github.com/acid-vega/aw_screen_capture.git
cd aw_screen_capture
```

## Run Setup

```bash
chmod +x aw_setup_screen_caputer.sh
./aw_setup_screen_caputer.sh
```

---

# Backup Feature

The installer automatically copies itself to:

```text
/media/datastore/skynet/bin/aw_setup_screen_caputer.sh
```

Behavior:

- SHA1 checked
- identical versions skipped
- changed versions updated automatically

---

# Audio Capture

Uses PulseAudio / PipeWire monitor device:

```text
DEFAULT_SINK.monitor
```

This records:

- browser audio
- VLC
- Discord
- games
- notifications
- everything playing on desktop audio

---

# Safe Shutdown / Crash Handling

Uses Bash `trap` cleanup handling.

Even if recording is interrupted via:

- hotkey
- CTRL+C
- signal
- second launch
- terminal close

the video is still finalized and saved correctly whenever possible.

---

# Tested On

- Debian 12
- GNOME Flashback
- X11

---

# Notes

Wayland is NOT officially supported.

Recommended session:

```text
GNOME Flashback (X11)
```

---

# License

Apache 2.0

---
