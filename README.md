# haji

Voucher top-up Umroh & Haji dengan cashback MLM berjenjang.
Backend: ASP.NET Core (.NET 10) + PostgreSQL + pembayaran Midtrans Snap. Aplikasi: Flutter (`VoucherUmrohHaji/mobile/`).

## Struktur

- `VoucherUmrohHaji/service/` — API
- `VoucherUmrohHaji/mobile/` — aplikasi Flutter
- `docs/` — spec & rencana implementasi

## Endpoint

| Method | Path | Keterangan |
|---|---|---|
| POST | `/api/auth/register` | Daftar (nama, email, password, referral opsional) |
| POST | `/api/auth/login` | Login, dapat access + refresh token |
| POST | `/api/auth/refresh` | Tukar refresh token |
| GET | `/api/vouchers` | Daftar voucher aktif |
| POST | `/api/orders` | Buat order, dapat Snap token/url Midtrans |
| GET | `/api/orders` | Riwayat order milik sendiri |
| POST | `/api/orders/{id}/cancel` | Batalkan order pending |
| GET | `/api/orders/{id}/status` | Cek status order (+ inquiry Midtrans) |
| POST | `/api/webhooks/midtrans` | Notifikasi pembayaran (verifikasi signature) |
| GET | `/api/wallet` | Saldo, voucher dimiliki, mutasi |
| GET | `/api/referral/me` | Kode referral, jaringan, pengali cashback |
| POST | `/api/referral/bind` | Hubungkan upline |
| POST | `/api/withdrawals` | Ajukan penarikan (saldo di-hold) |
| GET | `/api/withdrawals` | Riwayat penarikan |
| GET/POST/PUT/DELETE | `/api/admin/vouchers` | CRUD voucher (admin) |
| GET | `/api/admin/withdrawals` | Semua pengajuan withdraw (admin) |
| POST | `/api/admin/withdrawals/{id}/approve` / `reject` | Approval withdraw (admin) |
| GET | `/api/admin/members` | Daftar anggota (admin) |
| PUT | `/api/admin/mlm-config` | Persentase per level, step, multiplier (admin) |
| GET | `/api/health` | Health check |

Autentikasi: JWT Bearer (`Authorization: Bearer <token>`). Endpoint admin butuh role `admin`.

## Menjalankan (dev)

```bash
# Postgres
docker run --name haji-pg -e POSTGRES_PASSWORD=haji -e POSTGRES_DB=voucher -p 5432:5432 -d postgres:17

# API
cd VoucherUmrohHaji/service
dotnet user-secrets set "AdminUser:Password" "..."
dotnet user-secrets set "Jwt:Key" "..."
dotnet user-secrets set "Midtrans:ServerKey" "SB-Mid-server-..."
dotnet run

# Flutter
cd VoucherUmrohHaji/mobile
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5080
```
