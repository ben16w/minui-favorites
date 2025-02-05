#!/bin/sh

trap "killall sdl2imgshow" EXIT INT TERM HUP QUIT

show_message() {
    message="$1"
    seconds="$2"

    killall sdl2imgshow
    "./sdl2imgshow" \
        -i "./background.png" \
        -f "./BPreplayBold.otf" \
        -s 27 \
        -c "220,220,220" \
        -q \
        -t "$message" >/dev/null 2>&1
    sleep "$seconds"
}

DIR="$(dirname "$0")"
cd "$DIR" || exit 1

COLLECTIONS_PATH="/mnt/SDCARD/Collections"
RECENTS_PATH="/mnt/SDCARD/.userdata/shared/.minui/recent.txt"
FAVORITES_PATH="$COLLECTIONS_PATH/1) Favorites.txt"

if [ ! -s "$RECENTS_PATH" ]; then
  show_message "Failed to remove game from Favorites." 5
  exit 1
fi

MOST_RECENT_GAME=$(head -n 1 "$RECENTS_PATH" | cut -f1)

if [ ! -s "$FAVORITES_PATH" ]; then
  show_message "Failed to remove game from Favorites." 5
  exit 1
fi

if grep -Fxq "$MOST_RECENT_GAME" "$FAVORITES_PATH"; then
  grep -Fxv "$MOST_RECENT_GAME" "$FAVORITES_PATH" > "$FAVORITES_PATH.tmp"
  mv "$FAVORITES_PATH.tmp" "$FAVORITES_PATH"
fi

if [ ! -s "$FAVORITES_PATH" ]; then
  rm -f "$FAVORITES_PATH"
fi

show_message "Removed the most recently played game from Favorites." 5