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

COLLECTIONS_PATH="$SDCARD_PATH/Collections"
RECENTS_PATH="$SHARED_USERDATA_PATH/.minui/recent.txt"
FAVORITES_PATH="$COLLECTIONS_PATH/1) Favorites.txt"

cleanup() {
    rm -f /tmp/stay_awake
    killall minui-presenter >/dev/null 2>&1 || true
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

add_favorite() {
    recents="$RECENTS_PATH"
    collections="$COLLECTIONS_PATH"
    favorites="$FAVORITES_PATH"

    if [ ! -s "$recents" ]; then
        show_message "The Recently Played list is empty." 5
        return 1
    fi

    most_recent_game=$(head -n 1 "$recents" | cut -f1)

    mkdir -p "$collections"
    touch "$favorites"

    if ! grep -Fxq "$most_recent_game" "$favorites"; then
        echo "$most_recent_game" >> "$favorites"
        awk -F'/' '{print $NF "|" $0}' "$favorites" | sort -t'|' -k1,1 | cut -d'|' -f2- > "$favorites.tmp"
        mv "$favorites.tmp" "$favorites"
    fi

    show_message "Successfully added game to Favorites." 5
    return 0
}

remove_favorite() {
    recents="$RECENTS_PATH"
    collections="$COLLECTIONS_PATH"
    favorites="$FAVORITES_PATH"

    if [ ! -s "$recents" ]; then
        show_message "The Recently Played list is empty." 5
        return 1
    fi

    most_recent_game=$(head -n 1 "$recents" | cut -f1)

    if [ ! -s "$favorites" ]; then
        show_message "The Favorites list is empty" 5
        return 1
    fi

    if grep -Fxq "$most_recent_game" "$favorites"; then
        grep -Fxv "$most_recent_game" "$favorites" > "$favorites.tmp"
        mv "$favorites.tmp" "$favorites"
    fi

    if [ ! -s "$favorites" ]; then
        rm -f "$favorites"
    fi

    show_message "Successfully removed game from Favorites." 5
    return 0
}

clear_recents() {
    recents="$RECENTS_PATH"

    if [ ! -s "$recents" ]; then
        show_message "The Recently Played list is empty." 5
        return 1
    fi

    rm "$recents"
    touch "$recents"

    show_message "Successfully cleared the Recently Played list." 5
    return 0
}

main_screen() {
    recents="$RECENTS_PATH"

    minui_list_file="/tmp/minui-list"
    rm -f "$minui_list_file"
    touch "$minui_list_file"

    if [ -s "$recents" ]; then
        most_recent_game_name=$(head -n 1 "$recents" | cut -f2)
    else
        most_recent_game_name="recents empty"
    fi

    echo "Add to Favorites" >> "$minui_list_file"
    echo "Remove from Favorites" >> "$minui_list_file"
    echo "Clear Recently Played" >> "$minui_list_file"

    killall minui-presenter >/dev/null 2>&1 || true
    minui-list --file "$minui_list_file" --format text --title "Recently Played: $most_recent_game_name"
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
