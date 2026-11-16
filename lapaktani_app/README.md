# LapakTani Mobile App

Aplikasi mobile platform agribisnis digital terintegrasi LapakTani berbasis Flutter.

---

## Konfigurasi API Base URL & API Key untuk Kolaborator Tim

URL API backend dan API Key bersifat dinamis dan dapat dikonfigurasi menggunakan flag `--dart-define=API_BASE_URL=...` dan `--dart-define=API_KEY=...` tanpa perlu mengubah kode sumber `app_config.dart` atau `api_service.dart`:

### 1. Default Run (Cloudflare Tunnel Permanen / Production)
Menggunakan endpoint Cloudflare Tunnel bawaan (`https://api-lapaktani.velosixraptor.my.id/api`) beserta `X-API-Key` anti-spoofing bawaan:
```bash
flutter run
```

### 2. Collaborator Run (Localhost / XAMPP / Laragon / Web / Desktop)
Bagi kolaborator yang menjalankan backend secara lokal (misalnya di port 3000):
```bash
flutter run --dart-define=API_BASE_URL=http://localhost:3000/api
```

### 3. Collaborator Run (Android Emulator)
Jika menggunakan Android Emulator resmi Google (koneksi ke host localhost):
```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
```

### 4. Override API Key Kustom (Opsional)
```bash
flutter run --dart-define=API_BASE_URL=https://api-lapaktani.velosixraptor.my.id/api --dart-define=API_KEY=your_custom_api_key
```

---

## Getting Started

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
