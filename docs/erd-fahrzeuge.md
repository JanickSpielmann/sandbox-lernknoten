# ERD Beispieldatenbank «Fahrzeuge und Halter»

Diese Datenbank lädt der SQL Tab von sandbox.lernknoten.ch als Standard. Die Daten sind erfunden.

```mermaid
erDiagram
    ort ||--o{ person : "wohnt in"
    person ||--o{ kontrollschild : "ist Halter von"
    versicherung ||--o{ kontrollschild : "versichert"
    kontrollschild |o--o{ fahrzeug : "steckt an"
    marke ||--o{ modell : "baut"
    modell ||--o{ fahrzeug : "ist Typ von"
    fahrzeug ||--o{ lenker : ""
    person ||--o{ lenker : "darf fahren"
    fahrzeug ||--o{ service : "hat"
    kontrollschild ||--o{ busse : "erhält"

    ort {
        INTEGER id PK
        TEXT plz
        TEXT ort
        TEXT kanton
    }
    person {
        INTEGER id PK
        TEXT vorname
        TEXT nachname
        TEXT geburtsdatum
        TEXT strasse
        INTEGER ort_id FK
    }
    versicherung {
        INTEGER id PK
        TEXT name
    }
    kontrollschild {
        TEXT kennzeichen PK
        INTEGER halter_id FK
        INTEGER versicherung_id FK
    }
    marke {
        INTEGER id PK
        TEXT name
        TEXT land
    }
    modell {
        INTEGER id PK
        INTEGER marke_id FK
        TEXT name
        TEXT kategorie
        TEXT treibstoff
    }
    fahrzeug {
        TEXT stammnummer PK
        TEXT kennzeichen FK "NULL wenn abgemeldet"
        INTEGER modell_id FK
        TEXT erstzulassung
        INTEGER km_stand
        TEXT farbe
        INTEGER kaufpreis
    }
    lenker {
        TEXT stammnummer PK,FK
        INTEGER person_id PK,FK
        TEXT seit
    }
    service {
        INTEGER id PK
        TEXT stammnummer FK
        TEXT datum
        TEXT art
        INTEGER kosten
        INTEGER km_stand
    }
    busse {
        INTEGER id PK
        TEXT kennzeichen FK
        TEXT datum
        TEXT ort
        TEXT delikt
        INTEGER betrag
    }
```

## Warum diese Schlüssel

* **Ort** hat eine eigene `id` als Primärschlüssel. Die PLZ eignet sich nicht: In der Schweiz können sich mehrere Ortschaften eine PLZ teilen, und eine PLZ kann über eine Kantonsgrenze reichen. Eindeutig ist erst die Kombination aus PLZ und Ortsname (`UNIQUE (plz, ort)`). Die PLZ ist `TEXT`, weil sie eine Kennung ist und keine Zahl zum Rechnen.
* **Kennzeichen** ist der Primärschlüssel von `kontrollschild`. In der Schweiz gehört das Schild dem Halter, nicht dem Fahrzeug. Es wechselt beim Autokauf mit und kann als Wechselschild für zwei Fahrzeuge gelten (`BE 123456`).
* **Stammnummer** ist der Primärschlüssel von `fahrzeug`. Sie bleibt ein Fahrzeugleben lang gleich, auch wenn das Schild wechselt.
* `fahrzeug.kennzeichen` darf NULL sein: Das Fahrzeug `390.826.517` ist abgemeldet.
* Bussen hängen am Kennzeichen, weil ein Radar nur das Schild sieht. Bei einem Wechselschild ist deshalb nicht klar, welches Fahrzeug gefahren ist.
* `lenker` ist eine n:m Beziehung: Wer ausser dem Halter darf ein Fahrzeug fahren.

## Fälle zum Üben

* Wechselschild: `BE 123456` steckt an zwei Fahrzeugen.
* Schild ohne Fahrzeug: `ZH 4711` (Noah Weber hat sein Schild hinterlegt).
* Person ohne Schild: Mia Schmid ist nur Lenkerin.
* Fahrzeuge ohne Service und Halter ohne Bussen für LEFT JOIN Übungen.
