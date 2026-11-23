# My Notepad

[Português (Brasil)](../../README.md) · [English](en.md) · [Español](es.md) · [Français](fr.md) · **Deutsch** · [Italiano](it.md) · [日本語](ja.md) · [한국어](ko.md)

**My-Suite:** [My Explorer](https://github.com/leoars/my-explorer/blob/main/README.de.md) · **My Notepad** · [My Paint](https://github.com/leoars/my-paint/blob/main/docs/readme/de.md)

Ein einfacher Texteditor für macOS. Eine .txt-Datei öffnen, schreiben und mit den Tastenkürzeln speichern, die Ihre Hände längst kennen.

## Download für macOS

- **[Für Apple Silicon (M-Serie) herunterladen](https://github.com/leoars/My-Notepad/releases/download/1.0.4/My-Notepad-1.0.4-arm64.pkg)**
- **[Für Intel herunterladen](https://github.com/leoars/My-Notepad/releases/download/1.0.4/My-Notepad-1.0.4-x86_64.pkg)**

Erfordert macOS 12 oder neuer. [Zur neuesten Version](https://github.com/leoars/My-Notepad/releases/latest)

Um My Explorer, My Notepad und My Paint auf einmal zu installieren, nutze das [Installationsprogramm der My-Suite](https://github.com/leoars/my-suite/blob/main/docs/readme/en.md).

![Feldnotizen im Editor mit dem markierten Wort „Brücke“ und der Cursorposition in der Statusleiste.](../screenshots/de-editor.png)

## Warum My Notepad?

My Notepad ist entstanden, weil uns ein Texteditor fehlte, der ohne Umwege zur Sache kommt. Um eine Adresse zu notieren oder eine Zeile in einer alten Datei zu ändern, genügen ein Fenster, fünf Menüs und der Cursor. Das Projekt setzt diese Arbeitsweise mit Swift und AppKit um. Jedes Fenster bearbeitet ein Dokument, und die Schriftwahl gilt für die Anzeige. Gespeichert wird reiner Text.

## Funktionen

### Datei

- **Neu**, **Öffnen…**, **Speichern** und **Speichern unter…**. Wenn Sie ein Dokument mit ungespeicherten Änderungen schließen oder ein anderes öffnen oder anlegen, fragt der Editor, ob die Änderungen gespeichert werden sollen.
- Öffnet Textdateien aus dem Finder, auch wenn die App nicht läuft, und bietet beim ersten Öffnen an, Standardeditor für .txt-Dateien zu werden.
- **Neues Fenster** öffnet ein weiteres Dokument daneben. Eine Datei, die aus dem Finder oder aus My Explorer geöffnet wird, erhält ein eigenes Fenster, und das bereits geöffnete Dokument bleibt auf dem Bildschirm; ist die Datei schon geöffnet, kommt ihr Fenster nach vorn.
- **Beenden** schließt das Fenster; die App wird mit dem letzten Fenster beendet.
- **Einstellungen…** (`Cmd+,`) bietet **Vorherige Sitzung fortsetzen**: Beim Schließen des Fensters, Beenden der App oder Neustart des Mac wird nicht mehr nach dem Speichern gefragt; nicht Gespeichertes bleibt auf diesem Mac und ist beim nächsten Öffnen wieder da, jedes Dokument in seinem Fenster. Die Option ist anfangs eingeschaltet; damit wieder gefragt wird, wählen Sie **Neue Sitzung beginnen**.

### Bearbeiten

- **Rückgängig** und **Wiederholen**, **Ausschneiden**, **Kopieren**, **Einfügen**, **Löschen** und **Alles auswählen**.
- **Uhrzeit/Datum** fügt Uhrzeit und Datum an der Cursorposition ein.
- Wirklich reiner Text: keine Rechtschreibprüfung, keine automatischen Ersetzungen und keine versteckte Formatierung.

### Suchen und Ersetzen

- **Suchen…** mit Suchrichtung (aufwärts oder abwärts) und der Option, die Groß-/Kleinschreibung zu beachten. **Weitersuchen** wiederholt die Suche.
- **Ersetzen…** mit **Ersetzen** und **Alle ersetzen**. Das Fenster übernimmt beim Öffnen den markierten Text und bleibt offen, während Sie arbeiten.
- **Gehe zu…** springt zu einer Zeile, deren Nummer Sie angeben (bei ausgeschaltetem Zeilenumbruch).

![Das Fenster „Ersetzen“ mit den Einträgen „Brücke“ und „Fußgängerbrücke“.](../screenshots/de-replace.png)

### Format und Ansicht

- **Zeilenumbruch**, ein- oder ausgeschaltet.
- **Schriftart…**: Schriftart, Schriftschnitt (Standard, Kursiv, Fett, Fett kursiv) und Größe. Die Auswahl gilt für die Anzeige und bleibt gespeichert.
- Schriftgröße über die Tastatur oder mit gedrückter **Strg**-Taste und dem Mausrad ändern.
- **Statusleiste** mit Zeile und Spalte des Cursors.

### Codierungen und Zeilenenden

- Öffnet und speichert ANSI (CP-1252), UTF-8, UTF-16 LE und UTF-16 BE, mit automatischer Erkennung oder manueller Auswahl beim Öffnen und beim Speichern.
- Erkennt die Zeilenenden CRLF, LF und CR und speichert die Datei mit demselben Zeilenende.
- Lässt sich ein Zeichen in der gewählten Codierung nicht darstellen, bietet der Editor an, die Datei als UTF-8 zu speichern.

### Drucken

- **Seite einrichten…**: Kopfzeile, Fußzeile, die vier Seitenränder, Papier und Ausrichtung.
- Codes für Kopf- und Fußzeile: `&f` (Dateiname), `&p` (Seite), `&d` (Datum), `&t` (Uhrzeit), `&l`, `&c` und `&r` (Ausrichtung).
- **Drucken…** verwendet die Schriftart des Editors.

### Tagebuch als .txt-Datei

Schreiben Sie `.LOG` in die erste Zeile einer Datei, speichern Sie sie und öffnen Sie sie erneut. Der Editor fügt am Ende Uhrzeit und Datum ein. Schreiben Sie Ihren Eintrag darunter und speichern Sie die Datei.

### Oberfläche und Sprachen

- Menüs im Fenster (My Notepad, Datei, Bearbeiten, Format, Ansicht, Hilfe), zusätzlich zur Menüleiste von macOS. **Option** und der Buchstabe eines Menüs öffnen es über die Tastatur.
- Position und Größe des Fensters bleiben gespeichert.
- Verfügbar auf Portugiesisch, Englisch, Spanisch, Französisch, Deutsch, Italienisch, Japanisch und Koreanisch.

### Tastenkürzel

Die Tastenkürzel mit `Strg` funktionieren so, wie Sie es gewohnt sind; die Kürzel der Menübefehle lassen sich auch mit `Cmd` verwenden.

| Tasten | Funktion |
| --- | --- |
| `Strg+N` · `Strg+O` · `Strg+S` | Neu, Öffnen und Speichern |
| `Strg+Shift+S` | Speichern unter |
| `Strg+Shift+N` | Neues Fenster |
| `Strg+P` | Drucken |
| `Strg+Z` · `Strg+Y` | Rückgängig und Wiederholen |
| `Strg+X` · `Strg+C` · `Strg+V` · `Strg+A` | Ausschneiden, Kopieren, Einfügen und Alles auswählen |
| `Strg+Insert` · `Shift+Insert` · `Shift+Delete` | Kopieren, Einfügen und Ausschneiden |
| `Strg+F` · `F3` | Text suchen und zum nächsten Treffer springen |
| `Strg+H` | Ersetzen öffnen |
| `Strg+G` | Zu einer Zeile springen |
| `F5` | Uhrzeit und Datum einfügen |
| `Strg+←` / `→` | Den Cursor wortweise bewegen |
| `Strg+Shift+←` / `→` | Die Auswahl wortweise erweitern oder verkleinern |
| `Strg+Backspace` · `Strg+Delete` | Das vorherige oder das nächste Wort löschen |
| `Home` · `End` · `Strg+Home` · `Strg+End` | Anfang und Ende der Zeile oder des Dokuments |
| `Strg++` / `Strg+-` | Schrift vergrößern oder verkleinern |
| `F1` | Hilfe |

## Teil der My-Suite

My Notepad gehört zur My-Suite: drei einfache, geradlinige Apps für macOS, mit den vertrauten Menüs und Tastenkürzeln.

- **My Notepad** (dieses Repository): ein einfacher Texteditor.
- **[My Explorer](https://github.com/leoars/my-explorer/blob/main/README.de.md)**: ein Dateimanager mit Ordnerbaum, Tabs und einer Befehlsleiste. Ist My Notepad installiert, öffnet ein Doppelklick auf eine .txt-Datei in My Explorer den Text hier, und das Kontextmenü erhält den Eintrag **Mit My Notepad bearbeiten**.
- **[My Paint](https://github.com/leoars/my-paint/blob/main/docs/readme/de.md)**: ein einfaches Bildbearbeitungsprogramm.

## Auf dem Mac bauen und installieren

Die Installationspakete sind für macOS 12 oder neuer auf Apple Silicon und Intel vorgesehen. Zum Bauen benötigen Sie die Apple-Entwicklerwerkzeuge mit Swift-Compiler sowie Python 3. Führen Sie im Projektverzeichnis diese Befehle aus.

```sh
./build.sh
open "My Notepad.app"
```

So startest du die automatischen Tests:

```sh
./test.sh
```

Der folgende Befehl erzeugt beide Installationspakete. Wählen Sie in `dist/` das Paket `arm64` für Apple Silicon oder `x86_64` für Intel. Öffnen Sie die `.pkg`-Datei, um die App in `/Applications` zu installieren.

```sh
./package.sh
```

## Mitwirken

[Editor, Menüs und Dateiverarbeitung](../../Sources) sind in Swift geschrieben. Die [Übersetzungen](../../Resources) liegen nach Sprache getrennt in `.lproj`-Ordnern. Geben Sie bei Tastatur- oder Codierungsfehlern die macOS-Version, das Tastaturlayout oder die Dateicodierung sowie ein kurzes reproduzierbares Beispiel an.

## Lizenz

Der ursprüngliche Quellcode und die Dokumentation stehen unter der [Apache-Lizenz 2.0](../../LICENSE).
