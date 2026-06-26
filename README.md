# 📍 Phone Room SLAM - Mapovač Místností

**Velmi komplexní mobilní aplikace pro přesné mapování místností pomocí senzorů chytrého telefonu.**

Inspirováno technologiemi SLAM (Simultaneous Localization and Mapping), které používají prémiové robotické vysavače (jako Roborock, iRobot, Dreame) k vytváření přesných map domácností.

---

## 🎯 Co aplikace umí (aktuální verze)

- **Real-time sběr dat ze všech relevantních senzorů telefonu:**
  - Akcelerometr (lineární zrychlení + gravitace)
  - Gyroskop (úhlová rychlost)
  - Magnetometr (kompas / magnetické pole)
  - GPS (venku + slabý signál uvnitř)
  - Barometr (výška, pokud dostupný)

- **Pokročilá senzorová fúze (Sensor Fusion)**
  - Odhad orientace zařízení (pitch, roll, yaw / quaternion)
  - Implementovaný **Complementary Filter** + připravený Madgwick filter (pro plnou verzi)
  - Kompenzace driftu gyroskopu

- **Pedestrian Dead Reckoning (PDR)**
  - Detekce kroků pomocí peak detection na magnitudě akcelerace
  - Odhad délky kroku (kalibrovatelný)
  - Výpočet polohy v 2D (x, y) relativně k počátečnímu bodu

- **Tvorba mapy místnosti (Occupancy Grid Mapping)**
  - 2D mřížka (grid) s nastavitelným rozlišením (např. 5–20 cm na buňku)
  - Během chůze se automaticky označují prozkoumané / volné buňky podél cesty
  - Možnost ručního označování zdí a překážek (tap na mapu)
  - Vizualizace v reálném čase s pěknou grafikou (CustomPainter)

- **Profesionální uživatelské rozhraní**
  - Moderní Material 3 design
  - Live dashboard se senzory a grafy (fl_chart)
  - Interaktivní mapa s ovládáním (zoom, pan, reset, pause)
  - Historie relací (uložení / načtení map)
  - Kalibrační průvodce
  - Nastavení parametrů filtru a mapy

- **Architektura pro budoucí rozšíření na plný SLAM**
  - Čistá architektura (Domain / Data / Presentation)
  - Riverpod pro reaktivní stav
  - Připraveno na přidání:
    - Vizuální odometrie (kamera + feature tracking)
    - Particle Filter / EKF
    - Loop closure detection
    - 3D rekonstrukce (pomocí ARCore / ARKit)
    - Export do ROS / PLY / SVG

---

## 🏗️ Technický stack & Architektura

**Framework:** Flutter 3.22+ (cross-platform Android + iOS)

**Klíčové balíčky:**
- `sensors_plus`, `geolocator`, `permission_handler`
- `flutter_riverpod` + `riverpod_annotation`
- `hive` + `hive_flutter` (rychlé lokální úložiště)
- `fl_chart` (live grafy senzorů)
- `vector_math` (kvaterniony, matice)
- `path_provider`, `share_plus`

**Architektura:**
```
lib/
├── core/
│   ├── models/           # SensorData, Position, MapGrid, Session
│   ├── services/         # SensorService, FusionEngine, PositionTracker, MapperService, StorageService
│   ├── utils/            # Math helpers, filters, step detector
│   └── constants/
├── features/
│   ├── dashboard/        # Live senzory + grafy
│   ├── mapper/           # Hlavní mapa + ovládání
│   ├── history/          # Uložené relace
│   └── settings/
├── shared/
│   ├── providers/        # Riverpod providers (state)
│   └── widgets/
└── main.dart
```

Toto je připraveno na scaling do velmi komplexní aplikace (desítky tisíc řádků kódu).

---

## 🚀 Jak spustit aplikaci

```bash
cd phone-room-slam
flutter pub get
flutter run
```

**Požadavky:**
- Flutter SDK 3.22+
- Android Studio / Xcode pro emulátor nebo reálné zařízení
- Na reálném telefonu povolte všechny oprávnění (poloha, senzory, úložiště)

---

## 🧠 Jak to funguje (vysvětlení pro zvídavé)

### 1. Senzorová fúze (Orientation Estimation)
Telefon má 3 osy. Gyroskop je přesný krátkodobě, ale driftuje. Magnetometr + akcelerometr pomáhají korigovat.

Používáme **Complementary Filter**:
```
angle = alpha * (angle + gyro * dt) + (1 - alpha) * accel_angle
```

Pro plnou přesnost lze přidat **Madgwickův filtr** (gradient descent na quaternionu) – kód je připraven v `fusion_engine.dart`.

### 2. Detekce kroků a PDR
- Spočítáme magnitudu lineárního zrychlení: `sqrt(ax² + ay² + az²)`
- Hledáme peaky (lokální maxima) s minimální vzdáleností a prahovou hodnotou.
- Každý detekovaný krok posune polohu o `stepLength` v aktuálním směru (yaw z fúze).

### 3. Occupancy Grid Mapping
Místnost je reprezentována jako 2D pole `List<List<CellType>>`:
- `unknown` (šedá)
- `free` (zelená) – projito
- `occupied` (červená) – zeď / nábytek (ručně nebo detekováno)

Při pohybu se "vykresluje" paprsek nebo oblast podél cesty jako `free`. Uživatel může ťuknutím označit překážky.

V budoucnu: použít kameru + on-device ML (MediaPipe / ML Kit) pro detekci zdí a objektů.

### 4. Vizualizace
Všechno se děje v `MapPainter` (CustomPainter) – velmi efektivní, 60 FPS i při velkých mapách.

---

## 🆕 Nové funkce: 3D + Více pater + Export

- **3D pozice** (`x`, `y`, `z` + `floor`)
- **Automatická detekce pater** pomocí barometru (změna tlaku = schody/výtah)
- **Export 2D mapy** jako `.png` / `.jpg`
- **Export 3D modelu** jako `.stl` (ASCII) – lze otevřít v Blenderu, FreeCAD, PrusaSlicer, online viewerech
- STL obsahuje zdi (jako 3D boxy) + podlahu

V budoucí verzi lze přidat plný 3D viewer přímo v aplikaci (`model_viewer_plus` + Three.js webview).

---

## 🗺️ Roadmap k plnému SLAM (co ještě přidat)

1. **Vizuální SLAM** – integrace `camera` + `google_ml_kit` nebo ARCore/ARKit plugin pro point cloud a plane detection.
2. **Particle Filter** pro robustnější lokalizaci (1000+ částic).
3. **Loop Closure** – detekce, že jsme se vrátili na stejné místo (feature matching z kamery nebo WiFi fingerprinting).
4. **Graph-based optimization** (g2o style) pro korekci driftu.
5. **3D mapa** + export do Matterport-like modelu.
6. **Multi-room support** + automatické rozpoznání místností.
7. **Cloud sync** (Firebase / Supabase) + sdílení map mezi zařízeními.
8. **AR Overlay** – zobrazení virtuálního nábytku na reálné mapě.

Tento projekt je solidní základ pro takový výzkumný / produkční projekt.

---

## 📸 Ukázky UI (popis)

- **Dashboard**: 4 karty se senzory + 2 live grafy (akcelerace a orientace)
- **Mapper**: Velká interaktivní mapa s aktuální pozicí (šipka), cestou (modrá čára), gridem (barevné buňky). Tlačítka: Start/Pause, Reset, Mark Wall, Save, Calibrate.
- **History**: Seznam relací s náhledem mapy, možnost načtení.
- **Settings**: Posuvníky pro citlivost detekce kroků, velikost buňky, alpha filtr, délka kroku atd.

---

## 🤝 Přispívání & Licence

Projekt je open-source (MIT). Pokud chceš přidat Madgwick filter, particle filter, AR integraci nebo cokoliv jiného – pull requesty vítány!

---

**Vytvořeno s ❤️ pro pochopení indoor positioning a SLAM technologií.**

*Poznámka: GPS uvnitř budov nefunguje přesně. Aplikace je primárně navržena pro relativní mapování uvnitř místnosti pomocí IMU + PDR.*

---

## 📄 Licence

MIT License – volné použití i pro komerční účely.
