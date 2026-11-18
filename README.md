# sandbox.lernknoten.ch

Python und SQL direkt im Browser ausprobieren. Öffentlich, ohne Anmeldung, ohne Server.

* **Python:** echtes CPython im Browser mit [Pyodide](https://pyodide.org), Ausführung in einem Web Worker, Live Eingabe für `input()`, Stopp Knopf, numpy und pandas werden bei `import` nachgeladen.
* **SQL:** echte SQLite Datenbank im Browser mit [sql.js](https://github.com/sql-js/sql.js), Beispieldatenbank, Tabellenübersicht, Datenbank speichern und öffnen.

Alles läuft lokal im Browser. Code und Daten verlassen das Gerät nicht.

## Aufbau

* `index.html`: die ganze Seite (HTML, CSS und JavaScript in einer Datei, kein Build nötig)
* `coi-sw.js`: Service Worker, der die Header COOP und COEP setzt, damit die Live Eingabe (`SharedArrayBuffer`) auf GitHub Pages funktioniert
* `CNAME`: eigene Domain für GitHub Pages

Pyodide und sql.js werden mit fester Version von cdn.jsdelivr.net geladen (siehe oben in `index.html`).

## Deployment

GitHub Pages veröffentlicht den Branch `main` bei jedem Push automatisch unter https://sandbox.lernknoten.ch.

Lokal testen: `python -m http.server 8000` und http://localhost:8000 öffnen.
