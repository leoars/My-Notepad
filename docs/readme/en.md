# My Notepad

[Português (Brasil)](../../README.md) · **English** · [Español](es.md) · [Français](fr.md) · [Deutsch](de.md) · [Italiano](it.md) · [日本語](ja.md) · [한국어](ko.md)

A plain-text editor for macOS inspired by Windows 7 Notepad. Open a .txt file, write a few lines and save with the shortcuts you remember.

![My Notepad showing a field notebook with “bridge” selected and the line and column visible at the bottom.](../screenshots/en-editor.png)

## Why My Notepad?

After moving from Windows to the Mac, we missed the little window we used to jot down an address or fix a line in an old file. My Notepad brings that routine to macOS with Swift and AppKit. One document fills the window, five menus hold the commands, and your font preference stays with the editor. The file itself stays plain text.

## Everyday editing

- Find and replace text with the search panel open. Turn off word wrap to jump to a line with **Edit → Go To…** or enable **View → Status Bar** to see the line and column.
- Open Windows-1252, UTF-8 and UTF-16 (LE or BE) files with Windows, Mac or Unix line endings. If your chosen encoding cannot represent a character, the editor offers to save as UTF-8.
- Choose a typeface under **Format**, or hold **Ctrl** and scroll to change its size. Set margins, a header and a footer before printing.

![The Replace panel in English, ready to replace “bridge” with “footbridge”.](../screenshots/en-replace.png)

### Keyboard shortcuts

| Keys | Action |
| --- | --- |
| `Ctrl+F` · `F3` | Find text and advance to the next match |
| `Ctrl+H` | Open Replace |
| `Ctrl+G` | Go to a line |
| `Ctrl+Shift+←` / `→` | Extend or shrink the selection by one word |
| `Ctrl++` / `Ctrl+-` | Increase or decrease font size |
| `F5` | Insert the time and date |

### Try a plain-text logbook

Type `.LOG` on the first line, save the file and reopen it. My Notepad appends the time and date at the end, ready for your next entry. Save the entry to keep it in the file.

## Build and install on Mac

The installers target macOS 12 or later on Apple Silicon and Intel. To build locally, you need Apple’s developer tools with the Swift compiler and Python 3. From the project root, run:

```sh
./build.sh
open "My Notepad.app"
```

To build both installers, run the command below. In `dist/`, choose the `arm64` package for Apple Silicon or `x86_64` for Intel. Open the `.pkg` to install the app in `/Applications`.

```sh
./package.sh
```

## Contributing

The [editor, menus and file handling](../../Sources) are written in Swift. The [translations](../../Resources) live in one `.lproj` directory per language. For keyboard or encoding issues, include your macOS version, keyboard layout or file encoding, and a short example we can reproduce.

## License

Original code and documentation are distributed under the [Apache License 2.0](../../LICENSE).
