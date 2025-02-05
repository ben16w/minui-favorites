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

RECENTS_PATH="/mnt/SDCARD/.userdata/shared/.minui/recent.txt"

if [ ! -s "$RECENTS_PATH" ]; then
    show_message "Failed to clear the Recently Played list." 5
    exit 1
fi

rm "$RECENTS_PATH"
touch "$RECENTS_PATH"

show_message "Cleared the Recently Played list." 5
