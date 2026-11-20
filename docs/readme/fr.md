# My Notepad

[Português (Brasil)](../../README.md) · [English](en.md) · [Español](es.md) · **Français** · [Deutsch](de.md) · [Italiano](it.md) · [日本語](ja.md) · [한국어](ko.md)

Un éditeur de texte brut pour macOS, inspiré du Bloc-notes de Windows 7. Ouvrez un fichier .txt, écrivez quelques lignes et enregistrez-les avec vos raccourcis habituels.

## Télécharger pour macOS

- **[Télécharger pour Apple Silicon (série M)](https://github.com/leoars/My-Notepad/releases/download/1.0.1/My-Notepad-1.0.1-arm64.pkg)**
- **[Télécharger pour Intel](https://github.com/leoars/My-Notepad/releases/download/1.0.1/My-Notepad-1.0.1-x86_64.pkg)**

Nécessite macOS 12 ou une version ultérieure. [Voir la dernière version](https://github.com/leoars/My-Notepad/releases/latest)

![Carnet de terrain ouvert dans My Notepad, avec le mot « pont » sélectionné et la position du curseur en bas de la fenêtre.](../screenshots/fr-editor.png)

## Pourquoi My Notepad ?

En passant de Windows au Mac, il nous manquait cette petite fenêtre dans laquelle on pouvait noter une adresse ou corriger une ligne dans un vieux fichier. My Notepad retrouve cet usage avec Swift et AppKit. Une fenêtre contient un document et cinq menus. La police se règle dans l’éditeur et le fichier reste en texte brut.

## Au quotidien

- Recherchez et remplacez du texte en gardant la fenêtre de recherche ouverte. Désactivez le retour automatique à la ligne pour utiliser **Édition → Atteindre…** ou activez **Affichage → Barre d’état** pour connaître la ligne et la colonne.
- Ouvrez des fichiers Windows-1252, UTF-8 et UTF-16 (LE ou BE) avec des fins de ligne Windows, Mac ou Unix. Si l’encodage choisi ne représente pas tous les caractères, l’éditeur propose un enregistrement en UTF-8.
- Choisissez la police dans **Format** ou maintenez **Ctrl** en tournant la molette pour en régler la taille. Pour l’impression, vous pouvez définir les marges, l’en-tête et le pied de page.

![Fenêtre Remplacer prête à remplacer « pont » par « passerelle ».](../screenshots/fr-replace.png)

### Raccourcis clavier

| Touches | Action |
| --- | --- |
| `Ctrl+F` · `F3` | Rechercher puis passer à l’occurrence suivante |
| `Ctrl+H` | Ouvrir la fenêtre Remplacer |
| `Ctrl+G` | Atteindre une ligne |
| `Ctrl+Shift+←` / `→` | Étendre ou réduire la sélection mot par mot |
| `Ctrl++` / `Ctrl+-` | Agrandir ou réduire la police |
| `F5` | Insérer l’heure et la date |

### Tenir un journal en texte brut

Saisissez `.LOG` sur la première ligne, enregistrez le fichier et ouvrez-le de nouveau. L’éditeur ajoute l’heure et la date à la fin pour accueillir la prochaine entrée. Enregistrez-la pour la conserver.

## Compiler et installer sur Mac

Les paquets ciblent macOS 12 ou ultérieur sur Apple Silicon et Intel. La compilation nécessite les outils de développement Apple avec le compilateur Swift et Python 3. À la racine du projet, exécutez les commandes suivantes.

```sh
./build.sh
open "My Notepad.app"
```

Pour créer les deux paquets d’installation, exécutez la commande ci-dessous. Dans `dist/`, choisissez `arm64` pour Apple Silicon ou `x86_64` pour Intel. Ouvrez le fichier `.pkg` pour installer l’application dans `/Applications`.

```sh
./package.sh
```

## Contribuer

[L’éditeur, les menus et la gestion des fichiers](../../Sources) sont écrits en Swift. Les [traductions](../../Resources) disposent chacune d’un dossier `.lproj`. Pour signaler un problème de clavier ou d’encodage, précisez la version de macOS, la disposition du clavier ou l’encodage du fichier et donnez un court exemple reproductible.

## Licence

Le code et la documentation d’origine sont distribués sous [licence Apache 2.0](../../LICENSE).
