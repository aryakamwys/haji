# Design Spec — VoucherUmrohHaji Produksi (Flutter + ASP.NET Core + Midtrans)

Tanggal: 2026-10-27 · Status: menunggu review user

## 1. Keputusan

| Keputusan | Pilihan |
|---|---|
| Scope | Produksi penuh: pembayaran Midtrans Snap + webhook settlement + auth lengkap |
| Frontend | Flutter, folder `flutter/`, mirror fitur demo SwiftUI |
| Backend | ASP.NET Core Minimal API (.NET 10), project `VoucherUmrohHaji/service` |
| Database | PostgreSQL + EF Core (Npgsql) |
| Arsitektur | Pendekatan A: Minimal API + folder per fitur, tanpa layer Repository/Interface tambahan |
| State Flutter | Riverpod + dio + flutter_secure_storage |
| Midtrans | Sandbox dulu (keys via user-secrets/env), naik produksi ganti key |

Sumber fitur (reference only): `VoucherUmrohHaji/*.swift` — demo offline SwiftUI.
Prinsip: **semua logic uang di server**. Flutter hanya menampilkan & mengirim request.

## 2. Struktur repo

```
/ (repo: github.com/aryakamwys/haji)
├── CLAUDE.md                     # standards + konteks proyek
├── .claude/skills/               # dotnet-clean-service, git-workflow
├── docs/superpowers/specs/       # spec ini + implementation plan
├── VoucherUmrohHaji/
│   ├── *.swift                   # demo lama (referensi, tidak dikembangkan)
│   └── service/                  # BACKEND .NET 10
│       ├── Program.cs
│       ├── Features/             # Auth, Vouchers, Orders, Payments, Wallet, Referrals, Withdrawals, Admin
│       ├── Data/                 # AppDbContext, entitas, migrasi, seed
│       ├── Common/               # error handling, auth utils, Midtrans client
│       └── service.csproj
└── flutter/                      # FRONTEND Flutter
    └── lib/
        ├── core/                 # api client (dio), token storage, theme, format rupiah
        ├── features/             # auth, shop, wallet, referral, withdraw, admin
        └── main.dart
```

## 3. Model data (PostgreSQL)

| Tabel | Kolom penting |
|---|---|
| members | id (uuid), name, email **unique**, password_hash, role (`admin`/`buyer`), referral_code **unique**, parent_id (self-FK), balance **bigint**, downlines int, created_at UTC |
| vouchers | id (uuid), title, price bigint, value bigint, is_active |
| orders | id `ORD-…`, member_id, voucher_id, amount bigint, value bigint, status (`pending`/`settlement`/`cancel`/`expire`), midtrans_order_id, snap_token, created_at UTC |
| voucher_owned | id, member_id, title, value, order_id, created_at |
| ledgers | id, member_id, type (`topup`/`mlm_cashback`/`withdraw`/`refund`), title, amount bigint (±), order_id, created_at — **append-only** |
| withdrawals | id `WD-…`, member_id, amount, bank, account, holder, status (`pending`/`approved`/`rejected`), created_at |
| mlm_rules | level int, percentage numeric(5,2) |
| settings | 1 baris: downline_step int, multiplier numeric(5,2) |
| refresh_tokens | id, member_id, expires_at, revoked bool |

Uang: `bigint` (Rupiah, tanpa sen) → `long` di C#. Persen & multiplier: `decimal`.
Timestamp semua UTC.

## 4. Endpoint (prefix `/api`)

| Grup | Endpoint |
|---|---|
| Auth | `POST /auth/register` (nama, email, password, referral opsional) · `POST /auth/login` · `POST /auth/refresh` |
| Vouchers | `GET /vouchers` (aktif saja) · admin: `POST/PUT/DELETE /admin/vouchers` |
| Orders | `POST /orders` → pending + snap token · `GET /orders` (milik sendiri) · `POST /orders/{id}/cancel` (hanya pending) · `GET /orders/{id}/status` (inquiry ke Midtrans) |
| Payments | `POST /webhooks/midtrans` (anonim, verifikasi signature) |
| Wallet | `GET /wallet` → saldo + voucher dimiliki + mutasi |
| Referrals | `GET /referral/me` · `POST /referral/bind` |
| Withdrawals | `POST /withdrawals` · `GET /withdrawals` · admin: `GET /admin/withdrawals` · `POST /admin/withdrawals/{id}/approve` · `POST /admin/withdrawals/{id}/reject` |
| Admin | `GET /admin/members` (paginated) · `PUT /admin/mlm-config` |

## 5. Auth
- Password BCrypt. JWT access 15 menit + refresh 30 hari (DB, revocable).
- Role `admin` dari claim; akun admin di-seed dari konfigurasi saat migrasi pertama (email/password dari user-secrets).
- Login rate-limited (rate limiter bawaan .NET).
- Ownership tidak pernah dari input client — selalu dari claim token.

## 6. Alur pembayaran & settlement (inti)

1. `POST /orders` → order `pending` → backend minta **Snap token** ke Midtrans Core API (server key, di server saja) → balikkan `snap_url` ke Flutter.
2. Flutter buka `snap_url` (launch URL / WebView), user bayar.
3. Midtrans → `POST /webhooks/midtrans`. Validasi signature `sha512(order_id + status_code + gross_amount + server_key)`; abaikan jika tidak cocok. Status `settlement`/`capture` (dengan fraud status `accept`) → settlement.
4. **Settlement idempotent**: dalam 1 DB transaction, guard `status == pending`; kalau sudah bukan pending → skip (webhook dobel/expired aman).
5. Isi settlement (port logic Swift): saldo buyer += value · buat voucher_owned · ledger `topup` · naik ke atas per level: `payout = round(amount × pct_level/100 × (1 + ⌊downlines/step⌋ × multiplier))` → saldo upline += payout · ledger `mlm_cashback`.
6. Fallback inquiry: `GET /orders/{id}/status` cek status ke Midtrans API untuk order pending, lalu lewat jalur settlement yang sama.
7. Expire/cancel dari Midtrans (`deny`/`expire`/`cancel`) → update status order.

## 7. Withdrawal
- Buyer ajukan: validasi 0 < amount ≤ balance, data bank lengkap → saldo dikurangi (hold) + withdrawal `pending` + ledger `withdraw` (negatif).
- Admin approve (konfirmasi transfer manual di luar app) → status `approved`. Reject → saldo dikembalikan + ledger `refund`.
- Transfer bank otomatis (disbursement API) = fase lanjutan, tidak sekarang.

## 8. Flutter
- `flutter create flutter` (Material 3), tema tosca seperti Swift, format Rupiah `intl`.
- Layar: Login, Register → sesuai role: **Buyer** 4 tab (Top-Up, Dompet, Referal, Withdraw) / **Admin** 4 tab (Voucher, Komisi, Approval, Anggota).
- `core/`: dio client + interceptor refresh-token, secure storage, router.
- Checkout: panggil `POST /orders` → buka `snap_url` → kembali → poll `GET /orders/{id}/status`.

## 9. Testing
- **Backend (fokus utama — pegang uang)**: xUnit. Logic settlement MLM = fungsi murni terpisah → unit test: hitungan per level, multiplier, pembulatan, idempotency (webhook dobel), invalid transition. Integration test (SQLite in-memory): auth, order→settlement→ledger, withdraw hold/refund, hak akses admin.
- Flutter: widget test login/checkout; logic bisnis tidak ada di Flutter.

## 10. Keamanan
Signature webhook wajib · idempotent settlement · JWT + role gating semua endpoint admin · rate limit login · secrets di user-secrets/env (Midtrans server key TIDAK PERNAH di app) · ledgers append-only · validasi input di boundary · error 400/401/403/404/409 semantik, tanpa detail internal.

## 11. Urutan implementasi (per step, tiap step = commit + push)

1. `feat(service)`: scaffold service — EF Core + Npgsql, AppDbContext, entitas, migrasi awal, seed admin & voucher & rules, health endpoint.
2. `feat(auth)`: register/login/refresh, JWT, BCrypt, rate limit login.
3. `feat(vouchers)`: CRUD admin + katalog publik.
4. `feat(orders)`: order + cancel + list, Midtrans client (Snap token), konfig sandbox.
5. `feat(payments)`: webhook + signature + settlement MLM + inquiry fallback + unit test settlement.
6. `feat(wallet)`, `feat(referrals)`, `feat(withdrawals)`, `feat(admin)`.
7. `feat(flutter)`: scaffold app, auth, 4 tab buyer, 4 tab admin, checkout Snap.
8. `test` + `docs(api)`: integrasi & dokumentasi endpoint.

## 12. Ditangguhkan (fase lanjutan)
Reset password via email (butuh SMTP) · OTP/KYC · disbursement otomatis · audit log terpisah · monitoring/rekonsiliasi · multi-currency.
