# My Notepad

[Português (Brasil)](../../README.md) · [English](en.md) · [Español](es.md) · [Français](fr.md) · [Deutsch](de.md) · **Italiano** · [日本語](ja.md) · [한국어](ko.md)

Un editor di testo semplice per macOS ispirato al Blocco note di Windows 7. Apri un file .txt, scrivi qualche riga e salva con le scorciatoie che conosci già.

## Scarica per macOS

- **[Scarica per Apple Silicon (serie M)](https://github.com/leoars/My-Notepad/releases/download/1.0.1/My-Notepad-1.0.1-arm64.pkg)**
- **[Scarica per Intel](https://github.com/leoars/My-Notepad/releases/download/1.0.1/My-Notepad-1.0.1-x86_64.pkg)**

Richiede macOS 12 o successivo. [Vedi la versione più recente](https://github.com/leoars/My-Notepad/releases/latest)

![Taccuino di campo aperto nell’editor con la parola «ponte» selezionata e la posizione del cursore in basso.](../screenshots/it-editor.png)

## Perché My Notepad?

Dopo il passaggio da Windows al Mac ci mancava la piccola finestra dove bastava un attimo per annotare un indirizzo o correggere una riga di un vecchio file. My Notepad riprende quel modo di lavorare con Swift e AppKit. Ogni finestra contiene un documento e cinque menu. Il carattere scelto è una preferenza dell’editor e il file rimane testo semplice.

## Nell’uso quotidiano

- Cerca e sostituisci il testo mantenendo aperta la finestra di ricerca. Disattiva l’a capo automatico per usare **Modifica → Vai a…** oppure attiva **Visualizza → Barra di stato** per leggere riga e colonna.
- Apri file in Windows-1252, UTF-8 e UTF-16 (LE o BE) con terminazioni di riga Windows, Mac o Unix. Se la codifica scelta non supporta un carattere, l’editor propone di salvare in UTF-8.
- Scegli il carattere in **Formato** oppure tieni premuto **Ctrl** e gira la rotellina del mouse per regolare la dimensione. Per la stampa puoi impostare margini, intestazione e piè di pagina.

![Finestra Sostituisci pronta a cambiare «ponte» in «passerella».](../screenshots/it-replace.png)

### Scorciatoie da tastiera

| Tasti | Azione |
| --- | --- |
| `Ctrl+F` · `F3` | Cercare e passare all’occorrenza successiva |
| `Ctrl+H` | Aprire Sostituisci |
| `Ctrl+G` | Andare a una riga |
| `Ctrl+Shift+←` / `→` | Estendere o ridurre la selezione di una parola |
| `Ctrl++` / `Ctrl+-` | Aumentare o ridurre il carattere |
| `F5` | Inserire ora e data |

### Un diario in testo semplice

Scrivi `.LOG` sulla prima riga, salva il file e riaprilo. L’editor aggiunge ora e data in fondo al documento. Scrivi la nuova annotazione e salva per conservarla.

## Compilazione e installazione sul Mac

I pacchetti richiedono macOS 12 o successivo e sono disponibili per Apple Silicon e Intel. Per compilare servono gli strumenti di sviluppo Apple con il compilatore Swift e Python 3. Dalla radice del progetto esegui questi comandi.

```sh
./build.sh
open "My Notepad.app"
```

Il comando seguente genera entrambi i pacchetti. In `dist/` scegli `arm64` per Apple Silicon oppure `x86_64` per Intel. Apri il file `.pkg` per installare l’app in `/Applications`.

```sh
./package.sh
```

## Come contribuire

[L’editor, i menu e la gestione dei file](../../Sources) sono scritti in Swift. Le [traduzioni](../../Resources) si trovano in una cartella `.lproj` per ogni lingua. Per segnalare un problema di tastiera o codifica, indica la versione di macOS, il layout della tastiera o la codifica del file e un breve esempio riproducibile.

## Licenza

Il codice e la documentazione originali sono distribuiti con [licenza Apache 2.0](../../LICENSE).
