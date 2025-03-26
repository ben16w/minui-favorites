# MinUI Favorites

App to manage a Favorites collection in [MinUI](https://github.com/shauninman/MinUI) and [NextUI](https://github.com/LoveRetro/NextUI).

## Description

This project is a MinUI app to manage a collection named "Favorites". The is app is packaged in a .pak folder to be used as a tool within MinUI. The current features include the ability to add and remove games from the Favorites collection, delete the collection and clear the Recently Played. The Favorites collection can be accessed under Collections in the main menu, and is sorted alphabetically.

## Requirements

This pak is designed for the following MinUI Platforms and devices:

- `miyoomini`: Miyoo Mini Plus (_not_ the Miyoo Mini)
- `my282`: Miyoo A30
- `rg35xxplus`: RG-35XX Plus, RG-34XX, RG-35XX H, RG-35XX SP
- `tg5040`: Trimui Brick (formerly `tg3040`), Trimui Smart Pro

## Installation

1. Mount your MinUI SD card.
2. Download the latest [release](https://github.com/ben16w/minui-favorites/releases) from GitHub.
3. Copy the zip file to the correct platform folder in the "/Tools" directory on the SD card.
4. Extract the zip in place, then delete the zip file.
5. Confirm that there is a `/Tools/$PLATFORM/Favorites.pak/launch.sh` file on your SD card.
6. Unmount your SD Card and insert it into your MinUI device.

Note: The platform folder name is based on the name of your device. For example, if you are using a TrimUI Brick, the folder is "tg3040". Alternatively, if you're not sure which folder to use, you can copy the .pak folders to all the platform folders.

## Usage

### Add to Favorites

This option allows you to add a game from Recently Played to the Favorites collection. If the Favorites collection does not exist, it will be created for you.

### Remove from Favorites

This option allows you to remove a game from the Favorites collection. If the Favorites collection is empty, it will be removed.

### Clear Recently Played

This option clears your Recently Played list.

### Delete Favorites

This option deletes the Favorites collection.

## Settings

It is possible to change the word used for "Favorites" to another word of your choice. This will be reflected in the app and in the Collections menu. The can be used to, for example, change "Favorites" to British English "Favourites" or another language of your choice.

To do this, edit the `settings.json` file in the `Favorites.pak` folder. Change the value of `favorites_label` to the word you want to use. For example, to change "Favorites" to "Favourites", the settings section of the file would look like this:

```json
    "settings": {
        "favorites_label": "Favourites"
    }
```

You can also rename the `Favorites.pak` folder to the word you want to use. For example, to change "Favorites" to "Favourites", rename the folder to `Favourites.pak`.

## Acknowledgements

- [MinUI](https://github.com/shauninman/MinUI) by Shaun Inman
- [minui-list](https://github.com/josegonzalez/minui-list) and [minui-presenter](https://github.com/josegonzalez/minui-presenter) by Jose Diaz-Gonzalez
- Also thank you Jose Diaz-Gonzalez for your pak repositories, which this project is based on.

## License

This project is released under the MIT License. For more information, see the [LICENSE](LICENSE) file.
