# sandbox.lernknoten.ch

Python und SQL direkt im Browser ausprobieren. Öffentlich, ohne Anmeldung, ohne eigenen Server Code.

* **Python:** echtes CPython im Browser mit [Pyodide](https://pyodide.org), Ausführung in einem Web Worker, Live Eingabe für `input()`, Stopp Knopf, numpy und pandas werden bei `import` nachgeladen.
* **SQL:** echte SQLite Datenbank im Browser mit [sql.js](https://github.com/sql-js/sql.js), Beispieldatenbank, Tabellenübersicht, Datenbank speichern und öffnen.

Alles läuft lokal im Browser. Code und Daten verlassen das Gerät nicht.

Live: https://sandbox.lernknoten.ch (läuft auf HP-Winkel, siehe Deployment unten).

## Aufbau

* `index.html`: die ganze Seite (HTML, CSS und JavaScript in einer Datei, kein Build nötig). Pyodide und sql.js werden mit fester Version von cdn.jsdelivr.net geladen (siehe oben im Script).
* `nginx.conf`: Webserver Konfiguration. Sie setzt die Header COOP und COEP, damit die Live Eingabe (`SharedArrayBuffer`) funktioniert, und liefert keine Konfigurationsdateien aus.
* `docker-compose.yml`: Container `sandbox-lernknoten` (nginx), hängt am Docker Netzwerk `proxy`, Testport nur auf `127.0.0.1:8091`.
* `setup-winkel.sh`: richtet Container, Caddy Block und Test auf HP-Winkel ein (kann beliebig oft laufen).
* `coi-sw.js`: Service Worker als Ersatz für die Header, falls die Seite ohne `nginx.conf` ausgeliefert wird (zum Beispiel auf GitHub Pages). Wo die Header kommen, wird er nicht benutzt.
* `CNAME`: nur für GitHub Pages (siehe unten).

## Deployment auf HP-Winkel

Ablauf wie bei den anderen Webseiten (siehe `anleitungen/neue_webseite.md` in der Dokumentation Winkel):

1. DNS bei Metanet: A Record `sandbox` für `lernknoten.ch` auf die öffentliche IP des Heimnetzes.
2. Klon auf HP-Winkel (öffentliches Repository, HTTPS ohne Anmeldung): `git clone https://github.com/JanickSpielmann/sandbox-lernknoten ~/docker/sandbox-lernknoten`
3. `cd ~/docker/sandbox-lernknoten && ./setup-winkel.sh` (Container, Caddy Block, Test).
4. Pull Job: am Ende von `~/docker/winkel-deploy/winkel-deploy.sh` die Zeile `deploy sandbox-lernknoten '^(nginx\.conf|docker-compose\.yml)' '--force-recreate'` ergänzen.
5. Im Alltag: auf `main` arbeiten, `git publish` (Alias, schiebt `main` und `release`). Nach höchstens einer Minute ist die Änderung live.

Lokal testen: `docker compose up` und http://localhost:8091 öffnen, oder einfach `python -m http.server 8000` (dann ohne die COOP und COEP Header, die Seite nutzt den Service Worker oder das Feld "Eingaben").

## GitHub Pages

Der Branch `main` wird zusätzlich von GitHub Pages veröffentlicht, solange Pages in den Repository Einstellungen aktiv ist. Wenn die Seite nur auf HP-Winkel laufen soll, Pages dort abschalten und die Datei `CNAME` löschen.
