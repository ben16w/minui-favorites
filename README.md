# MinUI Favorites

Apps to manage a Favorites collection in [MinUI](https://github.com/shauninman/MinUI) and [NextUI](https://github.com/LoveRetro/NextUI).

## Description

This project is a MinUI app to manage a collection named "Favorites". The is app is packaged in a .pak folder to be used as a tool within MinUI. The current features include the ability to add and remove the most recently played game from the Favorites collection, as well as clear the Recently Played list. The Favorites collection can be accessed in MinUI, under Collections, and is sorted alphabetically.

## Requirements

This pak is designed for the following MinUI Platforms and devices:

- `miyoomini`: Miyoo Mini Plus (_not_ the Miyoo Mini)
- `my282`: Miyoo A30
- `rg35xxplus`: RG-35XX Plus, RG-34XX, RG-35XX H, RG-35XX SP
- `tg5040`: Trimui Brick (formerly `tg3040`), Trimui Smart Pro

Use the correct platform for your device.

## Installation

1. Mount your MinUI SD card.
2. Download the latest [release](https://github.com/ben16w/minui-favorites/releases) from GitHub.zip.
3. Copy the zip file to the correct platform folder in the "/Tools" directory on the SD card.
4. Extract the zip in place, then delete the zip file.
5. Confirm that there is a `/Tools/$PLATFORM/Favorites.pak/launch.sh` file on your SD card.
6. Unmount your SD Card and insert it into your MinUI device.

Note: The device folder name is based on the name of your device. For example, if you are using a TrimUI Brick, the folder is "tg3040". Alternatively, if you're not sure which folder to use, you can copy the .pak folders to all the device folders.

## Usage

### Add to Favorites

This tool adds your most recently played game to the Favorites collection. If the Favorites collection does not exist, it will be created for you.

### Remove from Favorites

This tool removes your most recently played game from the Favorites collection. If the Favorites collection is empty, it will be removed.

### Clear Recently Played

This tool clears your Recently Played list. Be warned, the list will be cleared without confirmation.

## Acknowledgements

- [MinUI](https://github.com/shauninman/MinUI) by Shaun Inman
- [minui-list](https://github.com/josegonzalez/minui-list) and [minui-presenter](https://github.com/josegonzalez/minui-presenter) by Jose Diaz-Gonzalez

## License

This project is released under the MIT License. For more information, see the [LICENSE](LICENSE) file.
