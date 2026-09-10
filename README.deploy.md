# DANAT SHOP uchun Paycue — o'z nusxa

Manba: `UzStack/paycue` dan olingan (2026-06-20, `ad61ff7`). `upstream` remote
saqlangan — kerak bo'lsa `git fetch upstream && git merge upstream/main`.

## Qurish va serverga chiqarish

    bash deploy.sh

Go qismi Docker ichida quriladi (Windows'da CGO/sqlite uchun), web UI `npm` bilan.
Serverda hech narsa kompilyatsiya qilinmaydi — 2 GB RAM yetmaydi.

## Serverda

- Binary: `/opt/paycue/paycue`, xizmat: `systemctl status paycue`
- Sozlama: `/opt/paycue/.env` (STATS_REPORT=false — muallifga statistika yuborilmaydi)
- Baza: `/opt/paycue/db.sqlite3`, Telegram sessiya: `/opt/paycue/sessions/`
- HTTPS: Caddy → `pay.danatpay.uz` → 127.0.0.1:8080
