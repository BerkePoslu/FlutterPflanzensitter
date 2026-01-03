# Flutter Pflanzensitter

Dieses Repository enthält die mobile Applikation des Projekts **Pflanzensitter**, welches im Rahmen der Berufsmaturitätsarbeit (BMA) entwickelt wurde.  
Die App dient zur Visualisierung der Bodenfeuchtigkeitsdaten in Echtzeit.

Die Sensordaten werden von einem ESP32-basierten Feuchtigkeitssystem erfasst und über MQTT an die App übertragen.

---

## Projektübersicht

Der Flutter Pflanzensitter ist die Benutzeroberfläche eines IoT-Systems zur Überwachung der Bodenfeuchtigkeit von Topfpflanzen.

Funktionen der App:

- Anzeige der aktuellen Bodenfeuchtigkeit in Prozent
- Animierte Liquid Progress Indicator Anzeige
- Farblich codierte Statusanzeige (ok / kritisch / trocken)
- Connection Status Indikator (Online/Offline)
- Echtzeit-Datenempfang über MQTT
- Lokale Datenspeicherung (max. 100 Messpunkte)
- "Weekly Insights" Detailansicht mit interaktiver Verlaufsgrafik
- Automatische Mock-Daten Generierung für Tests

---

## Systemarchitektur

Die App ist Teil eines Gesamtsystems und arbeitet wie folgt:

1. Ein kapazitiver Bodenfeuchtigkeitssensor misst die Feuchtigkeit der Erde
2. Ein ESP32 verarbeitet die Sensordaten
3. Die Daten werden per MQTT an einen Broker gesendet
4. Die Flutter-App abonniert die MQTT-Topics
5. Die empfangenen Daten werden visualisiert und lokal gespeichert

---

## Verwendete Technologien

- **Flutter** (Dart)
- **MQTT** (Publish/Subscribe-Kommunikation über `mqtt_client`)
- **fl_chart** (Visualisierung der Messwerte)
- **liquid_progress_indicator_v2** (Animierte Feuchtigkeitsanzeige)
- **shared_preferences** (Lokale Datenspeicherung)
- **google_fonts** (UI-Typografie)
- **glassmorphism** (Moderne UI-Effekte)

---

## Installation & Konfiguration

### Voraussetzungen

- Flutter SDK installiert
- iOS Simulator oder Android Emulator
- MQTT-Broker-Zugang

### 1. Dependencies installieren

```bash
flutter pub get
```

### 2. MQTT-Konfiguration einrichten

```bash
# Kopiere die Beispiel-Konfiguration
cp lib/config.dart.example lib/config.dart
```

Bearbeite `lib/config.dart` mit deinen MQTT-Zugangsdaten:

```dart
class MqttConfig {
  static const String broker = 'dein-mqtt-broker.com';
  static const String username = 'dein-username';
  static const String password = 'dein-password';
  static const int port = 1883;
  static const String topic = 'BBW/SoilMoisture';
}
```

**⚠️ WICHTIG:** Die Datei `lib/config.dart` wird **nicht** in Git committed und enthält deine privaten Zugangsdaten!

### 3. App starten

```bash
flutter run -d ios          # Für iOS Simulator
flutter run -d android      # Für Android Emulator
flutter run -d macos        # Für macOS Desktop
```

**Hinweis:** Web wird nicht unterstützt, da MQTT Secure Socket-Verbindungen benötigt.

---

## Projektstruktur

```
lib/
├── config.dart.example     # Template für MQTT-Konfiguration
├── config.dart            # Deine MQTT-Credentials (nicht in Git!)
└── main.dart              # Hauptapp mit UI und MQTT-Logik
```

---

## UI-Features

### Hauptseite (HomePage)

- **Animierte Feuchtigkeitsanzeige:** Liquid Progress Indicator mit Prozentangabe
- **Glassmorphism Design:** Moderne, halbtransparente UI-Elemente
- **Info Cards:** Anzeige von Raw-Wert und Pflanzenstatus
- **Connection Status:** Echtzeit-Anzeige der MQTT-Verbindung
- **Gradient Background:** Farbverlauf von Deep Blue zu Light Blue/Green

### Weekly Insights (WeekViewPage)

- **Interaktive Grafik:** Visualisierung des Feuchtigkeitsverlaufs
- **Zeitachse:** Beschriftung mit Wochentagen
- **Gradient Background:** Grüner Farbverlauf passend zum Pflanzen-Thema
- **Smooth Curves:** Gekrümmte Linien für bessere Lesbarkeit

### Datenverwaltung

- **Lokaler Cache:** Automatisches Speichern der letzten 100 Messpunkte
- **Mock-Daten:** 7 Tage Test-Daten wenn keine echten Daten vorhanden
- **Sortierung:** Chronologische Sortierung nach Zeitstempel

---

## MQTT-Kommunikation

Die App verbindet sich mit dem konfigurierten MQTT-Broker und abonniert das Topic `BBW/SoilMoisture`.

**Erwartetes Datenformat (JSON):**

```json
{
  "raw": 2345,
  "percent": 65,
  "state": "ok"
}
```

**Mögliche Statuswerte:**

- `ok` – Feuchtigkeit ausreichend
- `critical` – Feuchtigkeit niedrig
- `dry` – Pflanze benötigt Wasser

Die empfangenen Daten werden lokal gespeichert und in Echtzeit visualisiert.

---

## Zusammenhang zur BMA

Dieses Projekt ist Teil der Berufsmaturitätsarbeit:

**Titel:**
_Entwicklung eines Feuchtigkeitssystems_

Die zugehörige Firmware für den ESP32 befindet sich im Repository:
👉 [https://github.com/pirnet7/Feuchtigkeitssystem_esp32_bma](https://github.com/pirnet7/Feuchtigkeitssystem_esp32_bma)

---

## Autoren

- Berke Poslu
- Oliver Zenger
- Bruno Varrese

---

## Lizenz

Dieses Projekt wurde im Rahmen einer Berufsmaturitätsarbeit erstellt.
