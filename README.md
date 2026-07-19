# NoHand - MacBook Theft Alarm

NoHand adalah aplikasi menu bar macOS untuk mendeteksi penutupan lid MacBook
saat laptop ditinggalkan di ruang publik. Ketika Armed, NoHand menjaga Mac
tetap aktif dengan lid tertutup, mengunci layar, memutar alarm lokal dari
`audio.mp3`, dan mengirim notifikasi ke Android/iOS melalui
[ntfy.sh](https://ntfy.sh).

NoHand tidak menggunakan PIN aplikasi. Unlock dan disarm memakai passcode akun
atau Touch ID melalui lock screen native macOS.

## Fitur

- Menu bar app tanpa ikon Dock.
- Deteksi lid open/closed secara real-time melalui IOKit.
- Pencegahan clamshell sleep selama Armed menggunakan `pmset disablesleep`.
- Alarm MP3 looping dengan volume sistem maksimum dan fallback system beep.
- Audio dipersiapkan saat Arm untuk mengurangi race dengan transisi clamshell.
- Push notification urgent melalui ntfy.sh.
- Lock screen otomatis saat Arm.
- Disarm otomatis setelah unlock dengan passcode atau Touch ID.
- Pemulihan setting sleep saat unlock, disarm, quit, atau launch setelah crash.
- Dukungan Apple Silicon dan Intel.

## Persyaratan

- MacBook dengan macOS 15 atau lebih baru.
- Xcode dengan macOS SDK.
- Akun atau kredensial administrator.
- Izin Accessibility untuk NoHand.
- Aplikasi ntfy pada HP Android/iOS untuk menerima notifikasi.

## Build dan Test

Project Xcode dan shared scheme sudah tersedia di repository.

```bash
xcodebuild -project nohand.xcodeproj \
  -scheme nohand \
  -destination 'platform=macOS' \
  build
```

Jalankan unit test:

```bash
xcodebuild -project nohand.xcodeproj \
  -scheme nohand \
  -destination 'platform=macOS' \
  test
```

Atau buka `nohand.xcodeproj` dan gunakan Cmd+R dari Xcode.

## Setup Awal

### 1. Berikan Izin Accessibility

1. Buka **System Settings > Privacy & Security > Accessibility**.
2. Tambahkan aplikasi `nohand` jika belum muncul.
3. Aktifkan toggle untuk `nohand`.

Izin ini diperlukan oleh fallback lock screen yang mensimulasikan shortcut
Control+Command+Q.

### 2. Konfigurasi ntfy

1. Install aplikasi [ntfy](https://ntfy.sh) di HP.
2. Subscribe ke topic acak dan sulit ditebak, misalnya
   `nohand-7f91c2-example`.
3. Di menu NoHand, pilih **Set ntfy Topic...**.
4. Masukkan topic yang sama lalu pilih **Save**.
5. Pilih **Test Notification** dan pastikan notifikasi diterima di HP.

Topic pada server publik ntfy.sh tidak memiliki autentikasi. Siapa pun yang
mengetahui nama topic dapat melakukan subscribe, jadi jangan memakai nama yang
mudah ditebak atau mengirim informasi sensitif.

## Cara Menggunakan

### Arm

1. Klik **NoHand > Arm**.
2. Pada penggunaan pertama, baca dan setujui peringatan panas/baterai.
3. Masukkan kredensial administrator saat macOS meminta otorisasi.
4. NoHand menjalankan `pmset -a disablesleep 1`, memasang power assertion,
   mempersiapkan `assets/audio.mp3`, lalu mengunci layar.
5. Jika otorisasi dibatalkan atau perubahan setting gagal, Arm dibatalkan dan
   aplikasi tetap Disarmed.

### Trigger

Saat lid ditutup dalam kondisi Armed:

- Mac tetap aktif meskipun lid tertutup.
- `audio.mp3` diputar looping dengan volume maksimum.
- Notifikasi **MacBook Theft Alert** dikirim ke topic ntfy.
- Jika MP3 gagal diputar, NoHand menggunakan system alert sound berulang.

### Disarm

1. Buka lid MacBook.
2. Unlock melalui passcode akun atau Touch ID.
3. NoHand otomatis menghentikan alarm, melepas assertion, mengubah state ke
   Disarmed, dan menjalankan `pmset -a disablesleep 0`.

Tidak ada PIN atau password yang disimpan dan divalidasi oleh NoHand.

## Peringatan Keselamatan

Mode Armed sengaja membuat Mac tetap aktif ketika lid tertutup. Kondisi ini
dapat meningkatkan penggunaan baterai dan suhu perangkat.

- Jangan masukkan MacBook ke tas atau sleeve ketika Armed.
- Selalu unlock/disarm sebelum menyimpan atau membawa MacBook.
- Jangan abaikan dialog kegagalan pemulihan setting sleep.

Jika aplikasi berhenti tidak normal, NoHand menyimpan recovery flag dan mencoba
memulihkan setting pada launch berikutnya. Jika pemulihan otomatis gagal,
jalankan perintah berikut di Terminal:

```bash
sudo pmset -a disablesleep 0
```

## Lisensi dan Kontribusi

Internal project - hubungi pemilik repository untuk kontribusi.
