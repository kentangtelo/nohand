# NoHand — MacBook Theft Alarm

NoHand adalah aplikasi menu bar macOS yang mendeteksi percobaan pencurian MacBook di ruang publik (kafe, co-working space). Saat diaktifkan ("Armed"), aplikasi memantau status lid MacBook. Jika lid ditutup tanpa izin, alarm keras berbunyi dan notifikasi dikirim ke HP via [ntfy.sh](https://ntfy.sh).

## Cara Setup

### 1. Buat Project Xcode

1. Buka Xcode, pilih **File > New > Project**
2. Pilih **macOS > App**, klik Next
3. Product Name: `NoHand`
4. Interface: **XIB** (tidak digunakan karena kita setup UI dari kode)
5. Language: **Swift**
6. Simpan project

### 2. Tambahkan Source Code

1. Hapus file template bawaan Xcode (`AppDelegate.swift`, `ViewController.swift`, `Main.xib` jika ada)
2. Copy seluruh file di folder `NoHand/` dari repo ini ke project Xcode:
   - `AppDelegate.swift`
   - `LidMonitor.swift`
   - `AlarmController.swift`
   - `NtfyNotifier.swift`
   - `DisarmWindow.swift`
   - `Info.plist`
3. Drag semua file `.swift` ke project di Xcode (pastikan "Copy items if needed" dicentang)
4. Di Xcode, pastikan `Info.plist` yang digunakan adalah yang dari repo (cek Build Settings > Info.plist File)

### 3. Konfigurasi Build

- Target: macOS 12.0+
- Architectures: Standard (Apple Silicon + Intel)

### 4. Jalankan

- Build & Run (Cmd+R)
- Ikuti dialog setup: masukkan ntfy topic dan PIN

## Cara Pakai

### Setup Awal

1. **Install ntfy di HP**: Download [ntfy](https://ntfy.sh) dari App Store (iOS) atau Play Store (Android)
2. **Buat topic**: Subscribe ke topic dengan nama random & unik, misalnya `nohand-abc123xyz`. Jangan gunakan nama yang mudah ditebak karena topic publik bisa di-subscribe siapa saja
3. **Set topic di NoHand**: Klik ikon menu bar > "Set ntfy Topic..." > masukkan nama topic yang sama
4. **Set PIN**: Klik "Set PIN..." > masukkan PIN untuk disarm
5. **Test**: Klik "Send Test Notification" untuk verifikasi

### Mengamankan Laptop

1. Klik ikon menu bar > **Arm** (ikon berubah jadi 🛡️)
2. Tinggalkan laptop — NoHand sekarang aktif
3. Jika seseorang menutup lid laptop saat Armed: alarm berbunyi keras + notifikasi dikirim ke HP
4. Untuk disarm: masukkan PIN di window yang muncul, atau toggle Arm/Disarm manual saat belum trigger

### Kembali Normal

- Masukkan PIN yang benar di window disarm, atau
- Klik **Disarm** di menu bar (hanya bisa saat state belum triggered)

## ntfy.sh Self-Hosted (Opsional)

Jika ingin privasi lebih baik, self-host ntfy server:

```bash
docker run -p 80:80 binwiederhier/ntfy
```

Lalu set `NtfyNotifier` base URL ke server sendiri.

## Lisensi & Kontribusi

Internal project — hubungi pemilik repo untuk kontribusi.
