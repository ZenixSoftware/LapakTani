# LapakTani Mobile App

Aplikasi mobile platform agribisnis digital terintegrasi LapakTani berbasis Flutter.

---

## Konfigurasi API Base URL untuk Kolaborator Tim

URL API backend bersifat dinamis dan dapat dikonfigurasi menggunakan flag `--dart-define=API_BASE_URL=...` tanpa perlu mengubah kode sumber `api_service.dart`:

### 1. Default Run (Cloud Ngrok / Testing Device Fisik)
Menggunakan endpoint Ngrok bawaan:
```bash
flutter run
```

### 2. Collaborator Run (Localhost / XAMPP / Web / Desktop)
Bagi kolaborator yang menjalankan backend secara lokal (misalnya di port 3000):
```bash
flutter run --dart-define=API_BASE_URL=http://localhost:3000/api
```

### 3. Collaborator Run (Android Emulator)
Jika menggunakan Android Emulator resmi Google (koneksi ke host localhost):
```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
```

---

## Getting Started

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
