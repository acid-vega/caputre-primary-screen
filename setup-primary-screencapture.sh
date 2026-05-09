#!/usr/bin/env bash
#
# =======================================================================================
# aW ( acidWEB)-Script by acid-vega(@h9k.wtf ) alias ( L. Lars Kirches acid2542@gmail.com )
# ki -> chat_completition ( another moronic bash script v0.0.3 (2026-05-09)
# =======================================================================================
#
set -euo pipefail

APP_NAME="Primary screenCapture"
STOP_NAME="Stop screenCapture"

MENU_NAME="acidWEB"

BIN_DIR="/usr/local/bin"

APP_DIR="$HOME/.local/share/applications"
DESKTOP_DIR="$HOME/.local/share/desktop-directories"
MENU_DIR="$HOME/.config/menus/applications-merged"

REC_SCRIPT="$BIN_DIR/aw_screen_capture"
STOP_SCRIPT="$BIN_DIR/aw_screen_capture_stop"

DESKTOP_FILE="$APP_DIR/acidweb-primary-screencapture.desktop"
STOP_DESKTOP_FILE="$APP_DIR/acidweb-stop-screencapture.desktop"

PACKAGES=(
  vlc
  pulseaudio-utils
  x11-xserver-utils
  dbus-x11
  libnotify-bin
  notify-osd
  xdg-utils
  zenity
)

missing=()

for pkg in "${PACKAGES[@]}"; do

  if ! dpkg -s "$pkg" >/dev/null 2>&1; then
    missing+=("$pkg")
  fi

done

if (( ${#missing[@]} > 0 )); then

  echo "Installiere fehlende Pakete:"
  echo "${missing[*]}"

  sudo apt update

  sudo apt install -y "${missing[@]}"

fi

mkdir -p "$APP_DIR"
mkdir -p "$DESKTOP_DIR"
mkdir -p "$MENU_DIR"

sudo mkdir -p "$BIN_DIR"

###############################################################################
# RECORDER
###############################################################################

sudo tee "$REC_SCRIPT" >/dev/null <<'EOF'
#!/usr/bin/env bash
set -u

OUTDIR="/home/${USER}/grab-my-screen"

FPS="30"

PIDFILE="/tmp/aw_screen_capture.pid"

mkdir -p "$OUTDIR"

if [[ -f "$PIDFILE" ]]; then

  OLD_PID="$(cat "$PIDFILE" 2>/dev/null || true)"

  if [[ -n "${OLD_PID}" ]] && kill -0 "$OLD_PID" 2>/dev/null; then

    echo "Vorherige Aufnahme gefunden -> wird beendet..."

    kill -INT "$OLD_PID" 2>/dev/null

    for i in {1..10}; do

      if ! kill -0 "$OLD_PID" 2>/dev/null; then
        break
      fi

      sleep 1

    done

    if kill -0 "$OLD_PID" 2>/dev/null; then
      kill -9 "$OLD_PID" 2>/dev/null || true
    fi
  fi
fi

echo $$ > "$PIDFILE"

HOUR="$(date +%H)"
DAY="$(date +%d)"
YEAR="$(date +%Y)"
MONTH_NAME="$(date +%B)"
MONTH_NUM="$(date +%m)"

PART=1

while true; do

  OUTFILE="$OUTDIR/${USER}-${HOUR}-${DAY}-${YEAR}-${MONTH_NAME}-${MONTH_NUM}-${YEAR}-${PART}.mp4"

  [[ ! -e "$OUTFILE" ]] && break

  PART=$((PART + 1))

done

TMPFILE="${OUTFILE}.part"

GEOMETRY="$(xrandr --query | awk '
  / connected primary/ {
    for (i=1; i<=NF; i++) {
      if ($i ~ /^[0-9]+x[0-9]+\+[0-9]+\+[0-9]+/) {
        print $i
        exit
      }
    }
  }
')"

if [[ -z "$GEOMETRY" ]]; then

  GEOMETRY="$(xrandr --query | awk '
    / connected/ {
      for (i=1; i<=NF; i++) {
        if ($i ~ /^[0-9]+x[0-9]+\+[0-9]+\+[0-9]+/) {
          print $i
          exit
        }
      }
    }
  ')"

fi

if [[ "$GEOMETRY" =~ ^([0-9]+)x([0-9]+)\+([0-9]+)\+([0-9]+)$ ]]; then

  WIDTH="${BASH_REMATCH[1]}"
  HEIGHT="${BASH_REMATCH[2]}"
  LEFT="${BASH_REMATCH[3]}"
  TOP="${BASH_REMATCH[4]}"

else

  WIDTH="960"
  HEIGHT="540"
  LEFT="0"
  TOP="0"

fi

SINK="$(pactl get-default-sink 2>/dev/null || true)"

AUDIO_SOURCE="${SINK}.monitor"

VLC_PID=""

cleanup() {

  echo
  echo "Beende Aufnahme sauber..."

  if [[ -n "${VLC_PID}" ]] && kill -0 "$VLC_PID" 2>/dev/null; then

    kill -INT "$VLC_PID" 2>/dev/null

    wait "$VLC_PID" 2>/dev/null

  fi

  if [[ -s "$TMPFILE" ]]; then

    mv "$TMPFILE" "$OUTFILE"

    echo "Gespeichert: $OUTFILE"

    if command -v notify-send >/dev/null 2>&1; then

      notify-send \
        "ScreenCapture gespeichert" \
        "$OUTFILE" \
        --icon=video-x-generic \
        --expire-time=15000

    fi

    (
      sleep 1

      if command -v zenity >/dev/null 2>&1; then

        zenity \
          --question \
          --title="Aufnahme gespeichert" \
          --width=500 \
          --text="Video ansehen?\n\n$OUTFILE"

        if [[ $? -eq 0 ]]; then

          xdg-open "$OUTFILE" >/dev/null 2>&1 &

        fi

      fi

    ) &

  else

    echo "Keine brauchbare Aufnahme gefunden."

    rm -f "$TMPFILE"

  fi

  rm -f "$PIDFILE"
}

trap cleanup INT TERM EXIT

notify-send \
  "ScreenCapture gestartet" \
  "Speichert nach:\n$OUTFILE\n\nStoppen mit SHIFT+F11" \
  --icon=media-record \
  --expire-time=10000

echo "=========================================="
echo "aw_screen_capture"
echo "=========================================="
echo "Datei:"
echo "$OUTFILE"
echo
echo "Monitor:"
echo "${WIDTH}x${HEIGHT}+${LEFT}+${TOP}"
echo
echo "Audioquelle:"
echo "$AUDIO_SOURCE"
echo
echo "Stop:"
echo "SHIFT+F11 oder STRG+C"
echo "=========================================="

cvlc screen:// \
  --screen-fps="$FPS" \
  --screen-left="$LEFT" \
  --screen-top="$TOP" \
  --screen-width="$WIDTH" \
  --screen-height="$HEIGHT" \
  --input-slave="pulse://$AUDIO_SOURCE" \
  --sout="#transcode{vcodec=h264,vb=5000,acodec=mp4a,ab=192,channels=2,samplerate=48000}:std{access=file,mux=mp4,dst=${TMPFILE}}" \
  --no-sout-all \
  --sout-keep &

VLC_PID="$!"

wait "$VLC_PID"
EOF

sudo chmod +x "$REC_SCRIPT"

###############################################################################
# STOP SCRIPT
###############################################################################

sudo tee "$STOP_SCRIPT" >/dev/null <<'EOF'
#!/usr/bin/env bash

PIDFILE="/tmp/aw_screen_capture.pid"

if [[ -f "$PIDFILE" ]]; then

  PID="$(cat "$PIDFILE" 2>/dev/null || true)"

  if [[ -n "$PID" ]] && kill -0 "$PID" 2>/dev/null; then

    kill -INT "$PID"

    notify-send \
      "ScreenCapture" \
      "Aufnahme wird beendet..." \
      --icon=media-playback-stop \
      --expire-time=3000

  else

    notify-send \
      "ScreenCapture" \
      "Keine laufende Aufnahme gefunden." \
      --icon=dialog-warning \
      --expire-time=3000

  fi

else

  notify-send \
    "ScreenCapture" \
    "Keine laufende Aufnahme gefunden." \
    --icon=dialog-warning \
    --expire-time=3000

fi
EOF

sudo chmod +x "$STOP_SCRIPT"

###############################################################################
# DESKTOP ENTRIES
###############################################################################

cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Type=Application
Name=$APP_NAME
Comment=Record primary monitor with system audio
Exec=$REC_SCRIPT
Icon=video-x-generic
Terminal=true
Categories=acidWEB;AudioVideo;Recorder;
EOF

cat > "$STOP_DESKTOP_FILE" <<EOF
[Desktop Entry]
Type=Application
Name=$STOP_NAME
Comment=Stop screen recording
Exec=$STOP_SCRIPT
Icon=media-playback-stop
Terminal=false
Categories=acidWEB;AudioVideo;Recorder;
EOF

cat > "$DESKTOP_DIR/acidweb.directory" <<EOF
[Desktop Entry]
Type=Directory
Name=$MENU_NAME
Icon=applications-internet
EOF

cat > "$MENU_DIR/acidweb.menu" <<EOF
<!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN"
 "http://www.freedesktop.org/standards/menu-spec/menu-1.0.dtd">
<Menu>
  <Name>Applications</Name>
  <Menu>
    <Name>acidWEB</Name>
    <Directory>acidweb.directory</Directory>
    <Include>
      <Category>acidWEB</Category>
    </Include>
  </Menu>
</Menu>
EOF

update-desktop-database "$APP_DIR" >/dev/null 2>&1 || true

###############################################################################
# HOTKEYS
###############################################################################

KEY_PATH1="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/primary-screencapture/"
KEY_PATH2="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/stop-screencapture/"

if gsettings writable org.gnome.settings-daemon.plugins.media-keys custom-keybindings >/dev/null 2>&1; then

  current="$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)"

  new="$current"

  if [[ "$new" != *"$KEY_PATH1"* ]]; then

    if [[ "$new" == "@as []" || "$new" == "[]" ]]; then
      new="['$KEY_PATH1']"
    else
      new="${new%]} , '$KEY_PATH1']"
    fi
  fi

  if [[ "$new" != *"$KEY_PATH2"* ]]; then
    new="${new%]} , '$KEY_PATH2']"
  fi

  gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$new"

  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$KEY_PATH1" name "$APP_NAME"

  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$KEY_PATH1" command "$REC_SCRIPT"

  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$KEY_PATH1" binding "<Shift>F12"

  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$KEY_PATH2" name "$STOP_NAME"

  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$KEY_PATH2" command "$STOP_SCRIPT"

  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$KEY_PATH2" binding "<Shift>F11"

fi

###############################################################################
# BACKUP
###############################################################################

BACKUP_DIR="/media/datastore/skynet/bin"

BACKUP_FILE="$BACKUP_DIR/aw_setup_screen_caputer.sh"

SELF_FILE="$(readlink -f "$0")"

mkdir -p "$BACKUP_DIR"

if [[ -f "$BACKUP_FILE" ]]; then

  SRC_SHA1="$(sha1sum "$SELF_FILE" | awk '{print $1}')"

  DST_SHA1="$(sha1sum "$BACKUP_FILE" | awk '{print $1}')"

  if [[ "$SRC_SHA1" == "$DST_SHA1" ]]; then

    echo "Backup existiert bereits identisch:"
    echo "$BACKUP_FILE"

  else

    cp "$SELF_FILE" "$BACKUP_FILE"

    echo "Backup aktualisiert:"
    echo "$BACKUP_FILE"

  fi

else

  cp "$SELF_FILE" "$BACKUP_FILE"

  echo "Backup erstellt:"
  echo "$BACKUP_FILE"

fi

chmod +x "$BACKUP_FILE"

echo
echo "=========================================="
echo "Fertig."
echo
echo "Recorder:"
echo "$REC_SCRIPT"
echo
echo "Stopper:"
echo "$STOP_SCRIPT"
echo
echo "Start:"
echo "SHIFT + F12"
echo
echo "Stop:"
echo "SHIFT + F11"
echo
echo "Menü:"
echo "acidWEB"
echo
echo "Aufnahmen:"
echo "/home/${USER}/grab-my-screen"
echo "=========================================="
exit 0
