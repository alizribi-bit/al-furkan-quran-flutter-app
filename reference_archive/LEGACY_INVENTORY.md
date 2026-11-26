# Reference Archive & Preserved Legacy Assets

This folder preserves valuable data, scholarly research, and Quranic metadata extracted from the earlier multi-app codebase so the main repository stays clean and focused strictly on **Itqan Quran (إتقان • القرآن الكريم)**.

Nothing inside `reference_archive/` is bundled into the compiled APK by default (keeping app size lean), yet every file remains versioned and ready for future milestones.

---

## Inventory of Preserved Materials

### 1. Structural Quran Metadata (`meta_data/`)
Reusable JSON index tables for traditional Mushaf navigation and localization:
- **`Hizb.json`** — Exact start/end Surah & Ayah coordinates for all 60 Ahzab (الأحزاب). Useful for adding Hizb jump navigation and Mushaf margin markers.
- **`Rub.json`** — Exact coordinates for all 240 Arba' (أرباع الأحزاب), ideal for daily Hifz targets (*Rub' al-Hizb* study blocks).
- **`Ruku.json`** — Thematic passage divisions (الركوعات) across Surahs, useful for automatic smart chunking in the Golden Loop.
- **`Manzil.json`** — Seven-day Khatma divisions (المنازل السبعة).
- **`surah_name_localization.json`** & **`surah_meaning_localization.json`** — Multilingual Surah titles and translations ready for future internationalization.

### 2. Extra Quran Scripts (`extra_scripts/`)
Active scripts (`Uthmani.json`, `Warsh.json`, `Qalun.json`) live directly inside `assets/quran_script/`. Archived scripts kept for future optional downloads:
- **`Indopak.json`** — Indo-Pakistani Nastaleeq Quran script dataset.
- **`QPC_Hafs_Tajweed_Compress.json`** — Compressed King Fahd Complex Hafs text with inline Tajwid color annotations (ready for an optional color-coded Tajwid toggle in future releases).

### 3. Pedagogical & Audio Architecture Research (`research/`)
- **`Zen_Hifz_Research_and_Architecture.md`** — Full engineering specification covering:
  - Traditional Shinqiti Digital Lawh & Ottoman cyclic memorization pedagogy.
  - Formal 4-Phase Golden Loop state machine (`Phase A Mastery` → `Phase B Chain Linking` → `Phase C Consolidation` → `Phase D Active Recall`).
  - Dynamic silent self-recitation gap heuristics.
  - Verified 24+ per-ayah reciter CDN catalog across Hafs, Warsh, Qalun, and Al-Duri.

---

## Planned Roadmap Notes
- **Step 1 (Active)**: Clean standalone Flutter root on GitHub + Authentic Flowing Mushaf Book Page with interactive spatial masking.
- **Step 2 (Upcoming)**: Mutun Studio — **تحفة الأطفال** and **متن الشاطبية (حرز الأماني)** with multiple voices and multiple poetry display modes.
- **Step 3 (Upcoming)**: Vocal-Only Anashid Library (أناشيد بدون إيقاع) powered by free Internet Archive public APIs.
