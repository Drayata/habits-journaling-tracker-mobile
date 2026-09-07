# 🚀 Panduan Rilis Aplikasi (Release Guide)

Dokumen ini menjelaskan alur kerja rilis standar (*release lifecycle*) untuk proyek **Habits & Journaling Tracker Mobile**.

---

## 📌 Standar Penomoran Versi (Semantic Versioning)

Aplikasi ini menggunakan format versi Flutter di `pubspec.yaml`:
```yaml
version: MAJOR.MINOR.PATCH+BUILD_NUMBER
```
Contoh: `1.0.0+1`
- **`MAJOR`**: Perubahan arsitektur besar / breaking changes.
- **`MINOR`**: Penambahan fitur baru yang backward-compatible.
- **`PATCH`**: Perbaikan bug / perbaikan minor.
- **`BUILD_NUMBER`**: Nomor build inkremental (khusus untuk Android `versionCode` dan iOS `CFBundleVersion`).

---

## 🛠 Langkah-Langkah Rilis

### 1. Perbarui Versi Aplikasi
Buka `pubspec.yaml` dan naikkan versinya:
```yaml
# Sebelum:
version: 1.0.0+1

# Sesudah:
version: 1.0.1+2
```

### 2. Commit Perubahan
```bash
git add pubspec.yaml
git commit -m "chore(release): bump version to 1.0.1+2"
```

### 3. Buat Git Tag
Gunakan awalan `v` diikuti dengan nomor versi (tanpa build number):
```bash
git tag -a v1.0.1 -m "Release v1.0.1"
```

### 4. Push Tag ke GitHub
```bash
git push origin main
git push origin v1.0.1
```

> [!TIP]
> Begitu tag `v1.0.1` di-push ke repository, workflow **GitHub Actions** (`.github/workflows/release.yml`) akan otomatis berjalan untuk:
> 1. Mem-build Universal APK dan Split-per-ABI APKs.
> 2. Menghitung SHA-256 Checksums.
> 3. Membuat GitHub Release baru dengan release notes otomatis berdasarkan commit/PR.
> 4. Mengunggah seluruh file APK dan `checksums.txt`.

---

## 📝 Format & Template Catatan Rilis

Jika Anda ingin membuat atau mengedit catatan rilis secara manual di GitHub Releases atau untuk didistribusikan ke tester/konsol Google Play:
- Gunakan template di [`.github/RELEASE_TEMPLATE.md`](../.github/RELEASE_TEMPLATE.md).
- Konfigurasi generator changelog otomatis GitHub dikelola melalui [`.github/release.yml`](../.github/release.yml).

### Label Pull Request untuk Changelog Otomatis:
Gunakan label berikut pada Pull Request agar otomatis terkelompokkan ke kategori yang sesuai:
| Label | Kategori Changelog |
| :--- | :--- |
| `feature`, `feat`, `enhancement` | 🚀 What's New / Features |
| `bug`, `fix`, `bugfix` | 🐛 Bug Fixes & Stability |
| `ui`, `ux`, `design`, `style` | 💄 UI / UX Enhancements |
| `performance`, `perf` | ⚡ Performance Improvements |
| `refactor`, `architecture` | 🛠 Refactoring & Architecture |
| `dependencies`, `deps` | 📦 Dependencies & Tooling |
| `documentation`, `docs` | 📝 Documentation |
| `skip-changelog` | Diabaikan dari changelog |

---

## 🔒 Verifikasi Integritas File APK

Untuk memastikan file APK yang diunduh dari rilis tidak korup atau dimodifikasi:

### Di Windows (PowerShell):
```powershell
Get-FileHash -Algorithm SHA256 ./habits-tracker-universal.apk
```

### Di Linux / macOS:
```bash
sha256sum habits-tracker-universal.apk
```

Bandingkan output hash tersebut dengan file `checksums.txt` yang dilampirkan pada halaman GitHub Release.
