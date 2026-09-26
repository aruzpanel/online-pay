# Online Pay — bizning serverda

## Qurish va serverga chiqarish

    bash deploy.sh

Go qismi Docker ichida quriladi (Windows'da CGO/sqlite uchun), web UI `npm` bilan.
Serverda hech narsa kompilyatsiya qilinmaydi — 2 GB RAM yetmaydi.

## Serverda

Server hali **eski nom ostida** turibdi — nom almashgani uchun uni ko'chirish
shart emas, `deploy.sh` yangi binary'ni o'sha joyga qo'yadi:

- Binary: `/opt/paycue/paycue` (ichida endi Online Pay), xizmat: `systemctl status paycue`
- CLI: `/usr/local/bin/onlinepay-cli` (eski `~/.config/paycue` profilini ham o'qiydi)
- Sozlama: `/opt/paycue/.env` (STATS_REPORT=false)
- Baza: `/opt/paycue/db.sqlite3`, Telegram sessiya: `/opt/paycue/sessions/`
- Zaxira: har kuni 08:17 (Toshkent) `/var/backups/paycue/`, 14 kun saqlanadi
- HTTPS: Caddy → `pay.danatpay.uz` → 127.0.0.1:8080

Web dashboard login kaliti brauzerda hali `paycue_token` — ataylab: nom
almashgani uchun hech kim tizimdan chiqib ketmasin.
