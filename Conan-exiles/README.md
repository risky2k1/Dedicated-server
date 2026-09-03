# Conan Exiles Enhanced — Dedicated Server (Native Linux)

Server Conan Exiles **Enhanced** (UE5) chạy **native Linux** qua SteamCMD — không Docker, không Wine.

Cấu trúc và workflow giống thư mục `Valheim/native/`.

## Yêu cầu

|      | Yêu cầu |
| ---- | ------- |
| OS   | Ubuntu 22.04 / 24.04 |
| RAM  | **10 GB+** (idle ~9 GB; khuyến nghị **16 GB**) |
| CPU  | 2–4 vCPU |
| Disk | 20 GB+ trống (~5 GB game) |
| Mạng | UDP **7777–7778**, **27015** (TCP **25575** nếu bật RCON) |

> VPS 2 GB / 4 GB **không** chạy được Conan Enhanced. Cần nâng RAM trước khi `setup.sh`.

## Cài nhanh

```bash
cd Conan-exiles
cp .env.example .env
nano .env   # ADMIN_PASSWORD, SERVER_NAME, SERVER_PASSWORD, MAX_PLAYERS

chmod +x native/*.sh
./native/setup.sh

sudo ufw allow 7777:7778/udp
sudo ufw allow 27015/udp
sudo systemctl start conan
journalctl -u conan -f
```

Script tự:

1. Cài SteamCMD + Conan dedicated server (AppID **443030**, depot **Linux**)
2. Ghi config từ `.env` vào `config/Saved/Config/LinuxServer/`
3. Symlink `server/ConanSandbox/Saved` → `config/Saved`
4. Tạo systemd service `conan` + cron backup

**Lệnh thường dùng:**

```bash
sudo systemctl start conan
sudo systemctl stop conan          # SIGINT — flush SQLite
journalctl -u conan -f
./native/apply-config.sh           # sau khi sửa .env (server nên tắt)
./native/backup-world.sh
./native/update-server.sh          # server phải tắt
```

## Join game

| | Giá trị |
|---|---|
| Direct connect | `IP_VPS:7777` |
| Password | `SERVER_PASSWORD` trong `.env` (nếu có) |
| Admin | Trong game: `MakeMeAdmin <ADMIN_PASSWORD>` |

Kiểm tra:

```bash
curl -4 ifconfig.me
systemctl status conan
ss -ulnp | grep -E '7777|7778|27015'
tail -f config/Saved/Logs/ConanSandbox.log
```

Đợi log có `Startup report` / `Engine is initialized`.

## Biến môi trường (.env)

| Biến | Mô tả |
| ---- | ----- |
| `SERVER_NAME` | Tên server browser |
| `SERVER_PASSWORD` | Mật khẩu join (trống = mở) |
| `ADMIN_PASSWORD` | MakeMeAdmin (bắt buộc đổi) |
| `SERVER_PORT` / `QUERY_PORT` | Mặc định 7777 / 27015 |
| `MAX_PLAYERS` | Số slot |
| `PVP_ENABLED` | `true` / `false` |
| `RCON_ENABLED` | RCON (shutdown/backup sạch hơn) |
| `BACKUPS_CRON` | Lịch backup `config/Saved` |

Giá trị có khoảng trắng hoặc cron (`*`) phải bọc `"` — vd: `SERVER_NAME="Tun Conan"`, `BACKUPS_CRON="0 */6 * * *"`.

Chỉnh thêm rates / thrall / purge trong `config/Saved/Config/LinuxServer/ServerSettings.ini` (server **tắt** khi sửa — Conan ghi đè ini lúc shutdown).

## Dữ liệu lưu ở đâu

```
Conan-exiles/
├── .env
├── config/
│   ├── Saved/                 ← world (game_0.db) + Config/LinuxServer/
│   └── backups/
├── native/                    ← scripts
└── server/                    ← SteamCMD game (không sửa tay)
```

`config/Saved` được symlink vào `server/ConanSandbox/Saved` nên update game không mất world.

## Cấu trúc script

```
native/
├── setup.sh
├── apply-config.sh
├── start-server.sh
├── backup-world.sh
├── update-server.sh
├── uninstall.sh
├── install-deps.sh
├── install-steamcmd.sh
├── install-server.sh
├── install-systemd.sh
└── lib/common.sh
```

## Xử lý lỗi

**SteamCMD `Missing configuration` / không có binary Linux**  
→ App 443030 mặc định depot Windows. Script đã dùng `+@sSteamCmdForcePlatformType linux`. Chạy lại `./native/install-server.sh`. Kiểm tra:

```bash
test -f server/ConanSandbox/Binaries/Linux/ConanSandboxServer-Linux-Shipping && echo OK
```

**OOM / bị kill**  
→ RAM thiếu. Enhanced cần ~9 GB idle.

**Client không vào được**  
→ Mở UDP 7777–7778 và 27015. Join `IP:7777`. Client phải cùng bản Enhanced.

**Sửa .env không có hiệu lực**  
→ `sudo systemctl stop conan && ./native/apply-config.sh && sudo systemctl start conan`

**Backup hỏng**  
→ Backup khi server đang chạy có thể corrupt SQLite. Tắt server rồi `./native/backup-world.sh`.

## Gỡ cài

```bash
./native/uninstall.sh
# Giữ world: chỉ xóa binaries
# rm -rf server native/steamcmd
# Xóa hết:
# rm -rf /path/to/Conan-exiles
```
