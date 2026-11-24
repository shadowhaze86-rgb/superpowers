# Leonida Guide – GTA-VI-Begleit-App (iOS / iPadOS)

Inoffizielle Fan-App mit Missions-Guide, interaktiver Karte und Fortschrittsanzeige im „Vice City Sunset“-Look.
SwiftUI, iOS/iPadOS 18+, keine Fremdabhängigkeiten.

## Starten

```bash
brew install xcodegen
cd GTA6Companion
xcodegen generate
open GTA6Companion.xcodeproj
```

In Xcode ein Team unter *Signing & Capabilities* wählen und auf iPhone/iPad oder im Simulator starten.

## Funktionen

| Tab | Inhalt |
|---|---|
| Start | Gesamtfortschritt (Story 60 %, Gold-Ziele 20 %, Sammelobjekte 20 %), Statistik-Karten, nächste offene Mission |
| Missionen | Nach Kapiteln gruppiert, Suche, Filter nach Status und Charakter, Detailansicht mit abhakbaren Zielen und Gold-Zielen |
| Karte | Zoom (Pinch/Doppeltipp) und Verschieben, Pins nach Kategorien, gefundene Sammelobjekte markieren oder ausblenden |
| Wissen | Charaktere und Regionen mit Quellenangabe, Sprung zur Karte |
| Einstellungen | Quelle der Kartengrafik, Fortschritt zurücksetzen |

Auf dem iPad wird die Tab-Leiste automatisch zur Sidebar (`.sidebarAdaptable`).

## Inhalte pflegen

Alle Inhalte liegen in `GTA6Companion/Resources/Data/`:

- `missions.json` – Missionen (`chapter`, `character`: `lucia` | `jason` | `both`, `objectives[]` mit optional `"gold": true`, `locationID`)
- `locations.json` – Kartenpunkte. `x`/`y` sind **normalisiert (0…1, oben links = 0/0)** relativ zum quadratischen Kartenbild.
  Kategorien: `landmark`, `mission`, `safehouse`, `shop`, `activity`, `collectible`
- `knowledge.json` – Charaktere/Regionen

Einträge mit `"placeholder": true` sind Demo-Daten und werden in der App als „Demo“ markiert.
**Echte Missionsinhalte sind bewusst nicht enthalten.** Sie sollen aus geprüften Quellen kommen und nicht erfunden sein.

## Karte

Reihenfolge der Kartenquellen:

1. Bild `LeonidaMap` in einem Asset-Katalog (quadratisch, z. B. 4096×4096)
2. Bild-URL aus den Einstellungen
3. Eingebaute stilisierte Platzhalterkarte

Die Karte von gtabase.com ist **nicht** eingebunden. Ihre Kacheln und Markierungen sind Inhalte von gtabase,
und eine Nutzung in einer eigenen App braucht deren Erlaubnis. Mit Erlaubnis lässt sich das Bild über Option 1 oder 2 einbinden.
Die Pin-Koordinaten müssen dann auf das jeweilige Bild kalibriert werden.

## Rechtliches

„Grand Theft Auto“, „GTA“ und zugehörige Namen und Logos sind Marken von Take-Two Interactive / Rockstar Games.
Für eine Veröffentlichung im App Store keine Logos oder offiziellen Artworks verwenden und den App-Namen ohne „GTA“ wählen
(App-Review-Richtlinie 5.2.1, geistiges Eigentum).
