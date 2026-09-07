# Release v${VERSION} (${BUILD_NUMBER}) — ${RELEASE_TITLE}

> **Release Date:** ${DATE}  
> **App Version:** `v${VERSION}` (`+${BUILD_NUMBER}`)  
> **Platform:** Android (Min SDK 21 / Android 5.0+, Target SDK 34 / Android 14)  
> **Flutter Channel:** Stable (`v3.47.x`)

---

## 🌟 Highlights & Overview

<!-- Berikan ringkasan singkat 2-3 kalimat mengenai fokus utama pada rilis ini. -->
${SUMMARY}

---

## 📋 What's Changed

### 🚀 Features & Enhancements
- ${FEATURE_1}
- ${FEATURE_2}

### 🐛 Bug Fixes & Stability
- ${FIX_1}
- ${FIX_2}

### 💄 UI / UX Refinements
- ${UI_CHANGE_1}

### ⚡ Performance & Reliability
- ${PERF_CHANGE_1}

### 🛠 Refactor & Maintenance
- ${MAINTENANCE_1}

---

## 📦 Release Assets & Checksums

Unduh file instalasi APK sesuai dengan arsitektur perangkat Anda. Gunakan file `Universal` jika Anda ragu mengenai jenis CPU perangkat Anda.

| Asset File | Target Architecture | Description | SHA-256 Checksum |
| :--- | :--- | :--- | :--- |
| `app-release.apk` | **Universal** | Kompatibel dengan semua perangkat Android | `${SHA256_UNIVERSAL}` |
| `app-arm64-v8a-release.apk` | **arm64-v8a** | Perangkat Android 64-bit modern (Hemat ukuran) | `${SHA256_ARM64}` |
| `app-armeabi-v7a-release.apk` | **armeabi-v7a** | Perangkat Android 32-bit lawas | `${SHA256_ARMV7}` |
| `app-x86_64-release.apk` | **x86_64** | Emulator Android / ChromeOS / Perangkat Intel | `${SHA256_X86_64}` |

### 🔒 Verifikasi Integritas File (SHA-256)

Pastikan file APK yang Anda unduh otentik dan belum dimodifikasi:

**Windows (PowerShell):**
```powershell
Get-FileHash -Algorithm SHA256 ./app-release.apk
```

**Linux / macOS:**
```bash
sha256sum app-release.apk
# atau
shasum -a 256 app-release.apk
```

---

## 🏪 Play Store / App Store "What's New"

<!-- Copy teks di bawah ini langsung ke konsol Google Play Store / Apple App Store (Maksimal 500 karakter) -->

### 🇮🇩 Bahasa Indonesia:
```text
Pembaruan v${VERSION}:
• [Fitur Baru] ${STORE_ID_FITUR}
• [Peningkatan] Optimasi performa dan animasi tampilan
• [Perbaikan] Perbaikan bug dan peningkatan stabilitas aplikasi

Terima kasih telah menggunakan Habits & Journaling Tracker!
```

### 🇬🇧 English:
```text
What's New in v${VERSION}:
• [New Feature] ${STORE_EN_FEATURE}
• [Improvements] UI animations and performance enhancements
• [Fixes] Minor bug fixes and stability improvements

Thank you for using Habits & Journaling Tracker!
```

---

## ⚠️ Breaking Changes & Migration

<!-- Catat jika ada perubahan skema database (Isar) atau preferensi lokal yang membutuhkan migrasi data -->
- [x] Tidak ada breaking changes pada rilis ini.
<!-- Atau sebutkan:
- Migrasi skema database Isar: Semua data lokal akan otomatis termigrasi saat aplikasi dibuka pertama kali.
-->

---

## 🧪 QA & Verification Checklist

- [x] Tested on real Android device (Android 12+)
- [x] Dark mode & Light mode verified
- [x] Multi-language localization (ID / EN) verified
- [x] Local database persistence (Isar) tested on clean install & upgrade
- [x] Release APK signed & SHA-256 verified

---

**Full Changelog**: https://github.com/Drayata/habits-journaling-tracker-mobile/compare/${PREVIOUS_TAG}...v${VERSION}
