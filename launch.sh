#!/bin/sh

PAK_DIR="$(dirname "$0")"
PAK_NAME="$(basename "$PAK_DIR")"
PAK_NAME="${PAK_NAME%.*}"
[ -f "$USERDATA_PATH/$PAK_NAME/debug" ] && set -x

rm -f "$LOGS_PATH/$PAK_NAME.txt"
exec >>"$LOGS_PATH/$PAK_NAME.txt"
exec 2>&1

echo "$0" "$@"
cd "$PAK_DIR" || exit 1
mkdir -p "$USERDATA_PATH/$PAK_NAME"

architecture=arm
if uname -m | grep -q '64'; then
    architecture=arm64
fi

export HOME="$USERDATA_PATH/$PAK_NAME"
export LD_LIBRARY_PATH="$PAK_DIR/lib/$PLATFORM:$PAK_DIR/lib:$LD_LIBRARY_PATH"
export PATH="$PAK_DIR/bin/$architecture:$PAK_DIR/bin/$PLATFORM:$PAK_DIR/bin:$PATH"

COLLECTIONS_PATH="/mnt/SDCARD/Collections"
RECENTS_PATH="/mnt/SDCARD/.userdata/shared/.minui/recent.txt"
FAVORITES_PATH="$COLLECTIONS_PATH/1) Favorites.txt"

main_screen() {
    minui_list_file="/tmp/minui-list"
    rm -f "$minui_list_file"
    touch "$minui_list_file"
    echo "Add to Favorites" >>"$minui_list_file"
    echo "Remove from Favorites" >>"$minui_list_file"
    echo "Clear Recently Played" >>"$minui_list_file"

    killall minui-presenter >/dev/null 2>&1 || true
    minui-list --file "$minui_list_file" --format text --title "Favorites"
}

add_favorite() {
    if [ ! -s "$RECENTS_PATH" ]; then
        show_message "Recent games list is empty" 2
        exit 1
    fi

    MOST_RECENT_GAME=$(head -n 1 "$RECENTS_PATH" | cut -f1)

    mkdir -p "$COLLECTIONS_PATH"
    touch "$FAVORITES_PATH"

    if ! grep -Fxq "$MOST_RECENT_GAME" "$FAVORITES_PATH"; then
        echo "$MOST_RECENT_GAME" >> "$FAVORITES_PATH"
        awk -F'/' '{print $NF "|" $0}' "$FAVORITES_PATH" | sort -t'|' -k1,1 | cut -d'|' -f2- > "$FAVORITES_PATH.tmp"
        mv "$FAVORITES_PATH.tmp" "$FAVORITES_PATH"
    fi

    show_message "Successfully added to favorites!" 2
}

remove_favorite() {
    if [ ! -s "$RECENTS_PATH" ]; then
        show_message "Recent games list is empty" 2
    exit 1
    fi

    MOST_RECENT_GAME=$(head -n 1 "$RECENTS_PATH" | cut -f1)

    if [ ! -s "$FAVORITES_PATH" ]; then
        show_message "Favorites list is empty" 2
    exit 1
    fi

    if grep -Fxq "$MOST_RECENT_GAME" "$FAVORITES_PATH"; then
    grep -Fxv "$MOST_RECENT_GAME" "$FAVORITES_PATH" > "$FAVORITES_PATH.tmp"
    mv "$FAVORITES_PATH.tmp" "$FAVORITES_PATH"
    fi

    if [ ! -s "$FAVORITES_PATH" ]; then
    rm -f "$FAVORITES_PATH"
    fi

    show_message "Successfully removed from favorites!" 2
}

clear_recents() {
    if [ ! -s "$RECENTS_PATH" ]; then
        show_message "Recent games list is empty" 2
        exit 1
    fi

    rm "$RECENTS_PATH"
    touch "$RECENTS_PATH"

    show_message "Successfully cleared recently played!" 2
}

show_message() {
    message="$1"
    seconds="$2"

    if [ -z "$seconds" ]; then
        seconds="forever"
    fi

    killall minui-presenter >/dev/null 2>&1 || true
    echo "$message" 1>&2
    if [ "$PLATFORM" = "miyoomini" ]; then
        return 0
    fi
    if [ "$seconds" = "forever" ]; then
        minui-presenter --message "$message" --timeout -1 &
    else
        minui-presenter --message "$message" --timeout "$seconds"
    fi
}

cleanup() {
    rm -f /tmp/stay_awake
    killall minui-presenter >/dev/null 2>&1 || true
}

main() {
    echo "1" >/tmp/stay_awake
    trap "cleanup" EXIT INT TERM HUP QUIT

    if [ "$PLATFORM" = "tg3040" ] && [ -z "$DEVICE" ]; then
        export DEVICE="brick"
        export PLATFORM="tg5040"
    fi

    if [ "$PLATFORM" = "miyoomini" ] && [ -z "$DEVICE" ]; then
        export DEVICE="miyoomini"
        if [ -f /customer/app/axp_test ]; then
            export DEVICE="miyoominiplus"
        fi
    fi

    if ! command -v minui-list >/dev/null 2>&1; then
        show_message "minui-list not found" 2
        return 1
    fi

    if ! command -v minui-presenter >/dev/null 2>&1; then
        show_message "minui-presenter not found" 2
        return 1
    fi

    allowed_platforms="my282 tg5040 rg35xxplus miyoomini"
    if ! echo "$allowed_platforms" | grep -q "$PLATFORM"; then
        show_message "$PLATFORM is not a supported platform" 2
        return 1
    fi

    chmod +x "$PAK_DIR/bin/$PLATFORM/minui-list"
    chmod +x "$PAK_DIR/bin/$PLATFORM/minui-presenter"

    while true; do
        selection="$(main_screen)"
        exit_code=$?
        # exit codes: 2 = back button, 3 = menu button
        if [ "$exit_code" -ne 0 ]; then
            break
        fi

        if echo "$selection" | grep -q "^Add to Favorites$"; then
            add_favorite
            break
        elif echo "$selection" | grep -q "^Remove from Favorites$"; then
            remove_favorite
            break
        elif echo "$selection" | grep -q "^Clear Recently Played$"; then
            clear_recents
            break
        fi

    done
}

main "$@"
