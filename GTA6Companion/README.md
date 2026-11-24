# Leonida Guide – GTA-VI-Begleit-App (iOS / iPadOS)

Inoffizielle Fan-App mit Missions-Guide, interaktiver Karte, Sammelobjekt-Tracker und Fortschrittsanzeige im „Vice City Sunset“-Look.
SwiftUI, iOS/iPadOS 18+, keine Fremdabhängigkeiten.

## Starten

```bash
brew install xcodegen
cd GTA6Companion
xcodegen generate
open GTA6Companion.xcodeproj
```

1. In `project.yml` und `Shared/SharedData.swift` die Kennung `com.example` bzw. `group.com.example.leonidaguide` durch eine eigene ersetzen.
2. In Xcode für beide Targets (App + `LeonidaWidgets`) ein Team wählen.
3. **App Groups** (für das Widget) und **iCloud Key-Value-Storage** (für den Sync) brauchen einen kostenpflichtigen Apple-Developer-Account.
   Mit einem kostenlosen Account diese Einträge aus den `entitlements` in `project.yml` entfernen: Die App läuft dann ohne Widget-Daten und ohne Sync.

## Funktionen

| Bereich | Inhalt |
|---|---|
| Start | Gesamtfortschritt (Story 60 %, Gold-Ziele 20 %, Sammelobjekte 20 %), Statistik, nächste Mission |
| Missionen | Kapitel, Suche, Filter nach Status und Charakter; Ziele und Gold-Ziele abhaken, eigene Notizen |
| Spoiler-Schutz | Briefing, Ziele und Tipps offener Missionen bleiben verdeckt, bis man sie antippt (abschaltbar) |
| Karte | Zoomen, Verschieben, Filter nach Kategorie und Region, „nächstes offenes Sammelobjekt“ ab Kartenmitte, eigene Pins mit Notiz |
| Sammelobjekte | Nach Region gruppiert, mit Fortschritt je Region und Sprung zur Karte |
| Wissen | Charaktere, Regionen, Fahrzeuge, Waffen, Geschäfte (mit optionalen Kennwerten) |
| Widget | Home- und Sperrbildschirm: Gesamtfortschritt und nächste Mission |
| Live-Aktivität | Mission auf Sperrbildschirm und Dynamic Island verfolgen, mit Fortschritt der Ziele |
| Sync | Fortschritt, Pins und Notizen über iCloud zwischen iPhone und iPad |
| Inhalte online | JSON-Dateien von einer eigenen URL laden, ohne App-Update |
| Import | Kartenpunkte aus GeoJSON, CSV oder JSON, mit Kalibrierung und Vorschau |

## Inhalte

### Mitgelieferte Daten – `GTA6Companion/Resources/Data/`

- `missions.json`, `locations.json`, `knowledge.json`, Schema siehe `Models/Models.swift`
- `x`/`y` sind **normalisiert (0…1, oben links = 0/0)** relativ zum quadratischen Kartenbild
- Einträge mit `"placeholder": true` sind Demo-Daten und werden als „Demo“ markiert

### Online aktualisieren

Die drei JSON-Dateien auf einen beliebigen HTTPS-Ort legen, z. B. GitHub Pages oder einen eigenen Server.
Die Ordner-URL trägst du unter Einstellungen → Inhalte online ein.
Die App prüft alle drei Dateien und übernimmt sie nur, wenn alle gültig sind.

### Kartenpunkte importieren

Unter Einstellungen → Punkte importieren. Beispiele liegen in `Samples/`.

- **GeoJSON** (`FeatureCollection` mit `Point`): `properties.name`, `category`/`type`, `region`, `description`
- **CSV** (`,` oder `;`): Spalten `id, name, category, region, x, y, note`
- Unbekannte Kategorien werden per Stichwort zugeordnet (z. B. „Hidden Package“ → Sammelobjekt)
- **Kalibrierung:** Der Wertebereich der Quelle wird auf das Kartenbild abgebildet.
  Bei Leaflet-Karten sind das die `bounds` der Karte, nicht die Ausdehnung der Punkte.
  Die Vorschau zeigt sofort, ob die Punkte richtig liegen.

## Karte

Reihenfolge der Kartenquellen: Bild `LeonidaMap` im Asset-Katalog → Bild-URL aus den Einstellungen → eingebaute Platzhalterkarte.
Kartenbild und Punkte müssen zueinander passen: Punkte aus einer Quelle immer mit dem Kartenbild **derselben** Quelle oder mit passend kalibrierten Grenzen verwenden.

## Rechtliches

- „Grand Theft Auto“, „GTA“ und zugehörige Namen und Logos sind Marken von Take-Two Interactive / Rockstar Games.
  Für den App Store keine Logos oder offiziellen Artworks verwenden und den App-Namen ohne „GTA“ wählen (App-Review-Richtlinie 5.2.1).
- Kartenbilder und Punktesammlungen fremder Seiten (z. B. gtabase.com) sind deren Inhalte. In der EU schützt zusätzlich das Datenbankrecht
  (§ 87b UrhG) vor der Übernahme wesentlicher Teile. Für eine veröffentlichte App vorher die Erlaubnis einholen.
  Der Import ist für eigene oder lizenzierte Daten gedacht.
