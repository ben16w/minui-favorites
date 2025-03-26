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
FAVORITES_LABEL="Favorites"
FAVORITES_PATH="$COLLECTIONS_PATH/1) $FAVORITES_LABEL.txt"

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

show_confirm() {
    message="$1"

    killall minui-presenter >/dev/null 2>&1 || true
    echo "$message" 1>&2

    if ! minui-presenter --message "$message" \
        --confirm-show \
        --cancel-show \
        --confirm-text "YES" \
        --cancel-text "NO" \
        --timeout 0; then
        return 1
    fi

    return 0
}

load_settings() {
    config_file="$PAK_DIR/config.json"
    if [ ! -f "$config_file" ]; then
        show_message "Config file $config_file not found." 2
        return 1
    fi

    if jq -e '.settings.favorites_label' "$config_file" >/dev/null 2>&1; then
        FAVORITES_LABEL=$(jq -r '.settings.favorites_label' "$config_file")
        FAVORITES_PATH="$COLLECTIONS_PATH/1) $FAVORITES_LABEL.txt"
    fi
}

prettify_game_name() {
    game="$1"
    game_name=$(echo "$game" | cut -f1)
    game_name=$(basename "$game_name" | cut -d'.' -f1 | sed -e 's/([^()]*)//g' -e 's/[[^]]*]//g')
    echo "$game_name"
}

prettify_game_list() {
    game_list="$1"

    list_file="/tmp/game-list"
    rm -f "$list_file"
    touch "$list_file"

    while read -r game; do
        prettify_game_name "$game" >> "$list_file"
    done < "$game_list"

    cat "$list_file"
}

clean_favorites() {
    favorites="$FAVORITES_PATH"
    sd_path="$SDCARD_PATH"

    temp_file="/tmp/cleaned-favorites"
    rm -f "$temp_file"
    touch "$temp_file"

    while read -r favorite; do
        if [ -f "$sd_path/$favorite" ]; then
            echo "$favorite" >> "$temp_file"
        fi
    done < "$favorites"

    mv "$temp_file" "$favorites"
    return 0
}

select_game() {
    title="$1"
    game_list_file="$2"

    minui_list_file="/tmp/minui-list"
    rm -f "$minui_list_file"
    touch "$minui_list_file"

    prettify_game_list "$game_list_file" | while read -r game; do
        echo "$game" >> "$minui_list_file"
    done

    killall minui-presenter >/dev/null 2>&1 || true
    selected_favorite=$(minui-list --file "$minui_list_file" --format text --title "$title")
    exit_code=$?
    if [ "$exit_code" -ne 0 ]; then
        return 1
    fi

    grep -F "$selected_favorite" "$game_list_file"  | cut -f1
}

add_favorite() {
    recents="$RECENTS_PATH"
    collections="$COLLECTIONS_PATH"
    favorites="$FAVORITES_PATH"

    if [ ! -s "$recents" ]; then
        show_message "Recently Played is empty." 2
        return 1
    fi

    selected_favorite=$(select_game "Add a game from Recently Played." "$recents")
    exit_code=$?
    if [ "$exit_code" -ne 0 ]; then
        return 1
    fi

    mkdir -p "$collections"
    touch "$favorites"

    if ! grep -Fxq "$selected_favorite" "$favorites"; then
        echo "$selected_favorite" >> "$favorites"
        awk -F'/' '{print $NF "|" $0}' "$favorites" | sort -t'|' -k1,1 | cut -d'|' -f2- > "$favorites.tmp"
        mv "$favorites.tmp" "$favorites"
    fi

    pretty_game_name=$(prettify_game_name "$selected_favorite")
    show_message "$pretty_game_name added to $FAVORITES_LABEL." 4
    return 0
}

remove_favorite() {
    favorites="$FAVORITES_PATH"

    if [ ! -s "$favorites" ]; then
        show_message "The $FAVORITES_LABEL list is empty." 2
        return 1
    fi

    selected_favorite=$(select_game "Select a game to remove." "$favorites")
    exit_code=$?
    if [ "$exit_code" -ne 0 ]; then
        return 1
    fi

    grep -Fxv "$selected_favorite" "$favorites" > "$favorites.tmp"
    mv "$favorites.tmp" "$favorites"

    if [ ! -s "$favorites" ]; then
        rm -f "$favorites"
    fi

    pretty_game_name=$(prettify_game_name "$selected_favorite")
    show_message "$pretty_game_name removed from $FAVORITES_LABEL." 4
    return 0
}

clear_recents() {
    recents="$RECENTS_PATH"

    if [ ! -s "$recents" ]; then
        show_message "Recently Played is empty." 2
        return 1
    fi

    if ! show_confirm "Are you sure you want to clear Recently Played?"; then
        return 1
    fi

    rm -f "$recents"
    touch "$recents"

    show_message "Recently Played cleared." 4
    return 0
}

delete_favorites() {
    favorites="$FAVORITES_PATH"

    if [ ! -s "$favorites" ]; then
        show_message "The $FAVORITES_LABEL list is empty." 2
        return 1
    fi

    if ! show_confirm "Are you sure you want to delete $FAVORITES_LABEL?"; then
        return 1
    fi

    rm -f "$favorites"
    show_message "$FAVORITES_LABEL deleted ." 4
    return 0
}

main_screen() {
    recents="$RECENTS_PATH"
    favorites="$FAVORITES_PATH"

    clean_favorites

    minui_list_file="/tmp/minui-list"
    rm -f "$minui_list_file"
    touch "$minui_list_file"

    echo "Add to $FAVORITES_LABEL" >> "$minui_list_file"

    if [ -s "$favorites" ]; then
        echo "Remove from $FAVORITES_LABEL" >> "$minui_list_file"
        echo "Delete $FAVORITES_LABEL" >> "$minui_list_file"
    fi

    if [ -s "$recents" ]; then
        echo "Clear Recently Played" >> "$minui_list_file"
    fi

    killall minui-presenter >/dev/null 2>&1 || true
    minui-list --file "$minui_list_file" --format text --title "$FAVORITES_LABEL Collection"
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
        show_message "Minui-list not found." 2
        return 1
    fi

    if ! command -v minui-presenter >/dev/null 2>&1; then
        show_message "Minui-presenter not found." 2
        return 1
    fi

    if ! command -v jq >/dev/null 2>&1; then
        show_message "Jq not found." 2
        return 1
    fi

    allowed_platforms="my282 tg5040 rg35xxplus miyoomini"
    if ! echo "$allowed_platforms" | grep -q "$PLATFORM"; then
        show_message "$PLATFORM is not a supported platform." 2
        return 1
    fi

    chmod +x "$PAK_DIR/bin/$PLATFORM/minui-list"
    chmod +x "$PAK_DIR/bin/$PLATFORM/minui-presenter"
    chmod +x "$PAK_DIR/bin/$architecture/jq"

    if ! load_settings; then
        return 1
    fi

    while true; do
        selection="$(main_screen)"
        exit_code=$?
        # exit codes: 2 = back button, 3 = menu button
        if [ "$exit_code" -ne 0 ]; then
            break
        fi

        if echo "$selection" | grep -q "^Add to $FAVORITES_LABEL$"; then
            add_favorite
            continue
        elif echo "$selection" | grep -q "^Remove from $FAVORITES_LABEL$"; then
            remove_favorite
            continue
        elif echo "$selection" | grep -q "^Clear Recently Played$"; then
            clear_recents
            continue
        elif echo "$selection" | grep -q "^Delete $FAVORITES_LABEL$"; then
            delete_favorites
            continue
        fi

    done
}

main "$@"
