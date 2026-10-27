# Voucher Umroh & Haji — iOS Xcode (Demo)

> **Versi Flutter tersedia di folder [`flutter/`](flutter/README.md)** — port 1:1 dari SwiftUI, Material 3, jalankan `flutter create .` lalu `flutter run`.

Aplikasi **native SwiftUI** siap dibuka sebagai project Xcode. Dibuat dari PRD yang menggunakan Flutter; implementasi ini sengaja memakai SwiftUI untuk menyediakan folder `.xcodeproj` langsung tanpa instal Flutter/CocoaPods. Ini **demo offline**, bukan implementasi pembayaran/keuangan produksi.

## Menjalankan
1. Mac dengan Xcode 16+ disarankan, iOS Simulator versi 17+.
2. Buka `VoucherUmrohHaji.xcodeproj` di Xcode.
3. Pilih target **VoucherUmrohHaji**, tujuan iPhone Simulator, tekan **Cmd+R**.
4. Untuk iPhone fisik, target → Signing & Capabilities → pilih Apple Development Team dan ubah Bundle Identifier ke domain unik Anda.
5. Gunakan ikon akun di kanan atas untuk berpindah antara **Citra, Andi, Budi, Admin** atau membuat buyer baru.

## Alur uji
1. Buyer Citra → Top-Up → pilih voucher → Buat Order Demo → Simulasikan Pembayaran Berhasil.
2. Dompet: saldo, inventory, order dan mutasi tercatat.
3. Pindah ke Andi dan Budi: komisi MLM otomatis masuk sesuai konfigurasi.
4. Buyer → Withdraw: pengajuan memotong saldo (hold).
5. Admin → Approval → Tolak: saldo buyer dikembalikan; atau Setujui bila transfer dilakukan **manual di luar aplikasi**.
6. Admin → Voucher: tambah/edit/aktif-nonaktif/hapus jika belum dipakai order. Admin → Komisi: ubah persentase, kedalaman, step dan multiplier.
7. Data demo disimpan lokal melalui UserDefaults dan bertahan setelah app ditutup. Reset dengan menu akun.

## Implementasi dan batasan
- ✅ Buyer/admin switch, registrasi demo, kode referral otomatis unik, bind referral dengan validasi siklus, total downline.
- ✅ Katalog voucher; order `pending`, penyelesaian demo idempotent menjadi `settlement`, pencatatan inventory, ledgers, komisi multi-level dan multiplier.
- ✅ Withdraw dengan saldo hold, approve/reject, refund sekali; admin voucher CRUD dan konfigurasi MLM.
- ✅ Data demo persisten per instalasi, menggunakan bilangan integer rupiah (bukan floating point untuk saldo).
- ❌ Belum ada autentikasi password/OTP, backend Express/PostgreSQL, akses multisistem, API Midtrans Snap/WebView, webhook signature verification, disbursement bank, audit trail server, atau validasi KYC.
- ⚠️ Tombol simulasi pembayaran menambah **saldo demo**, tanpa memproses uang. Jangan gunakan untuk transaksi nyata.
- ⚠️ Admin switch bebas hanya boleh pada mode demo; tidak boleh digunakan untuk mengotorisasi aksi server.
- ⚠️ Karena build environment di sini tidak memiliki Xcode/macOS, hasil build di Xcode **belum dapat diuji di lingkungan ini**.

## Persyaratan produksi (belum diimplementasikan)
Server autentikasi dengan kontrol RBAC; PostgreSQL dengan transaksi database, unique constraints & ledger immutable; Midtrans sandbox/production Snap token dibuat di server, webhook Midtrans diverifikasi signature & status API (capture harus sesuai fraud status), settlement idempotent; perhitungan MLM atomik di server; withdrawal/disbursement melalui approval backend yang tercatat; pengamanan data pribadi, rate limits, log audit, monitoring dan rekonsiliasi keuangan. Jangan simpan server key Midtrans di aplikasi.
# haji
