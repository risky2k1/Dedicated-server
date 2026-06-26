# Valheim Dedicated Server

Server Valheim với mod **ServerCharacters** (lưu nhân vật trên server, chống mang đồ từ world khác).

Hai cách deploy:

| Cách       | Thư mục             | Phù hợp                           |
| ---------- | ------------------- | --------------------------------- |
| **Docker** | `./linux/setup.sh`  | Tiện, tự update/backup            |
| **Native** | `./native/setup.sh` | VPS RAM thấp (3 GB), có IP public |

## Yêu cầu

### Docker (Linux / Windows)

|            | Linux                      | Windows                                                           |
| ---------- | -------------------------- | ----------------------------------------------------------------- |
| Docker     | Docker Engine + Compose v2 | [Docker Desktop](https://www.docker.com/products/docker-desktop/) |
| Dung lượng | ~2 GB trống                | ~2 GB trống                                                       |

### Native (Linux VPS)

|      | Yêu cầu                                            |
| ---- | -------------------------------------------------- |
| OS   | Ubuntu 22.04 / 24.04                               |
| RAM  | 3 GB+ (khuyến nghị 4 GB)                           |
| CPU  | 2 vCPU                                             |
| Disk | 30 GB NVMe                                         |
| Mạng | Mở UDP **2456–2457** trên firewall (có IPv4 riêng) |

## Cài nhanh — Native (khuyến nghị cho VPS)

```bash
cd Valheim
cp .env.example .env
# Sửa .env: SERVER_PASS (≥5 ký tự), SERVER_NAME, WORLD_NAME
./native/setup.sh
sudo ufw allow 2456:2457/udp
sudo systemctl start valheim
```

Script tự:

1. Cài SteamCMD + Valheim dedicated server (~1 GB)
2. Cài BepInEx + ServerCharacters
3. Tạo systemd service `valheim`
4. Cài cron backup/update (theo `.env`)

**Lệnh thường dùng:**

```bash
sudo systemctl start valheim      # bật
sudo systemctl stop valheim       # tắt (save world trước khi stop)
journalctl -u valheim -f          # xem log
./native/backup-world.sh          # backup thủ công
./native/update-server.sh         # update game (server phải tắt)
./native/install-serverdevcommands.sh   # tùy chọn: spawn/god cho admin
```

**Dữ liệu** dùng chung với Docker: `config/worlds_local/`, `config/bepinex/`.

### Server devcommands (tùy chọn — admin)

Mod [Server devcommands](https://thunderstore.io/c/valheim/p/JereKuusela/Server_devcommands/) bật lệnh vanilla (`spawn`, `god`, `ghost`, …) cho admin trên dedicated server. **Không bắt buộc** — ServerCharacters vẫn chạy bình thường nếu không cài.

| Ai cần cài? | Server (VPS) | Client |
| ----------- | ------------ | ------ |
| **Admin**   | Có (script bên dưới) | Có — r2modman/Thunderstore, cùng version |
| **Player thường** | Không | Không |

Trên VPS (sau `git pull` hoặc copy script):

```bash
cd /opt/Dedicated-server/Valheim
./native/install-serverdevcommands.sh
sudo systemctl restart valheim
```

Trên **máy admin**: cài mod **Server devcommands** (JereKuusela) qua r2modman, profile Valheim, version **1.108.0** (hoặc khớp `SERVER_DEVCOMMANDS_VERSION` trong `.env`). Vào server → **F5** → `spawn Wood 1000` (không cần gõ `devcommands` trước).

> Lệnh `ServerCharacters giveitem ...` thuộc mod ServerCharacters — không cần Server devcommands.

### Join game (Native VPS)

| | Giá trị |
|---|---|
| Địa chỉ | `IP_VPS:2456` (vd: `160.187.0.6:2456`) |
| Mật khẩu | `SERVER_PASS` trong `.env` |
| Client | Cài **ServerCharacters** cùng version server (1.4.16) |

Kiểm tra trên VPS:

```bash
curl -4 ifconfig.me              # IP public
systemctl status valheim
ss -ulnp | grep -E '2456|2457'   # port UDP đang listen
journalctl -u valheim -n 30      # đợi server ready
ufw status | grep 2456
```

Trong game: **Join** → **Join IP** → nhập `IP:2456` → nhập password.

`SERVER_PUBLIC=false` vẫn join được qua IP trực tiếp — chỉ không hiện trong server browser public.

### Copy data từ máy local lên VPS (SCP)

Chạy trên **máy local** (thay `IP_VPS`):

```bash
cd /path/to/Valheim

ssh root@IP_VPS 'systemctl stop valheim; mkdir -p /opt/Dedicated-server/Valheim/config/{worlds_local,characters_local,bepinex/config}'

# World
scp -r config/worlds_local/* root@IP_VPS:/opt/Dedicated-server/Valheim/config/worlds_local/

# Character (ServerCharacters)
scp -r config/characters_local/* root@IP_VPS:/opt/Dedicated-server/Valheim/config/characters_local/

# BepInEx config — chỉ thư mục config/, không scp cả bepinex/
scp config/bepinex/config/* root@IP_VPS:/opt/Dedicated-server/Valheim/config/bepinex/config/ 2>/dev/null || \
scp config/bepinex/org.bepinex.plugins.servercharacters.cfg root@IP_VPS:/opt/Dedicated-server/Valheim/config/bepinex/config/

ssh root@IP_VPS 'cd /opt/Dedicated-server/Valheim && ./native/link-bepinex-config.sh && systemctl start valheim'
```

Kiểm tra trên VPS:

```bash
ls -lh /opt/Dedicated-server/Valheim/config/worlds_local/*.db
ls -la /opt/Dedicated-server/Valheim/config/characters_local/
```

### Cài lại từ đầu (VPS)

> **Cảnh báo:** Xóa hết world/config trên VPS. Dữ liệu trên máy local vẫn giữ — scp lại sau bước 3.

**Bước 1 — Gỡ service và xóa file**

```bash
# Gỡ systemd + cron (nếu repo còn)
cd /opt/Dedicated-server/Valheim 2>/dev/null && ./native/uninstall.sh || true

# Hoặc gỡ tay nếu đã xóa repo
systemctl stop valheim 2>/dev/null || true
systemctl disable valheim 2>/dev/null || true
rm -f /etc/systemd/system/valheim.service
systemctl daemon-reload
crontab -l 2>/dev/null | grep -v valheim-native | crontab - || true

# Xóa toàn bộ
rm -rf /opt/Dedicated-server
rm -rf /root/Steam
```

**Bước 2 — Clone và cài lại**

```bash
apt install -y git curl unzip tar lib32gcc-s1 lib32stdc++6

cd /opt
git clone https://github.com/risky2k1/Dedicated-server.git
cd Dedicated-server/Valheim

cp .env.example .env
nano .env
```

Ví dụ `.env` (giá trị có khoảng trắng **phải** có dấu `"`):

```bash
SERVER_NAME="Tuns Valheim Server"
WORLD_NAME=SuperSeed2
SERVER_PASS="123qwe"
SERVER_PUBLIC=false
BEPINEX=true
BACKUPS_CRON="0 */6 * * *"
UPDATE_CRON="*/15 * * * *"
SERVER_ARGS="-modifier combat hard -modifier resources most -modifier portals casual"
```

```bash
chmod +x native/setup.sh
./native/setup.sh

ufw allow 2456:2457/udp
systemctl start valheim
journalctl -u valheim -f
```

Đợi tải game (~1 GB) và log báo server ready.

**Bước 3 — Copy data từ local**

Xem mục [Copy data từ máy local lên VPS](#copy-data-từ-máy-local-lên-vps-scp) ở trên.

**Bước 4 — Join**

`IP_VPS:2456` + password trong `.env`.

## Cài nhanh — Docker

```bash
cd Valheim
cp .env.example .env
# Sửa .env: PLAYIT_SECRET_KEY, SERVER_PASS (tối thiểu 5 ký tự)
./linux/setup.sh
```

### Windows

```cmd
cd Valheim
copy .env.example .env
REM Sửa .env bằng Notepad
windows\setup.bat
```

Hoặc PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File windows\setup.ps1
```

Script sẽ tự:

1. Tạo file `.env` (nếu chưa có)
2. Tải mod ServerCharacters vào `config/bepinex/plugins/`
3. Chạy `docker compose up -d`

Lần đầu khởi động sẽ tải game server (~1 GB), đợi **3–10 phút**.

## Cấu hình Playit (một lần)

Theo [wizard Docker Compose](https://playit.gg/account/agents) của playit.gg:

1. Đăng ký / đăng nhập tại [playit.gg](https://playit.gg)
2. **Agents** → **Add Agent** → chọn **Docker Compose** → copy **Secret Key**
3. Dán key vào `.env`:
   ```
   PLAYIT_SECRET_KEY=your_key_here
   ```
4. Trên dashboard, tạo tunnel **Valheim**:
   - **Local Address:** `127.0.0.1`
   - **Port:** `2456` và `2457` (UDP)

`docker-compose.yml` đã cấu hình sẵn:

- **playit:** `ghcr.io/playit-cloud/playit-agent:0.17` + `network_mode: host` (theo wizard)
- **valheim:** publish port `2456-2457/udp` ra localhost để playit forward vào

Không cần mở port trên router. Người chơi join bằng địa chỉ playit cung cấp (IP/domain + port).

> **Lưu ý:** Không commit secret key vào git. Nếu key bị lộ, tạo lại agent trên playit.gg.

## Cấu hình ServerCharacters

Mod **bắt buộc cài trên cả server lẫn mọi client** (cùng version). Cài qua Thunderstore hoặc r2modman.

Sau lần chạy server đầu tiên, mở file config tại:

```
config/bepinex/config/<tên file ServerCharacters>.cfg
```

Khuyến nghị:

| Setting               | Giá trị | Lý do                                    |
| --------------------- | ------- | ---------------------------------------- |
| Single Character Mode | `true`  | Mỗi SteamID chỉ 1 nhân vật               |
| Backup Only Mode      | `false` | Server enforce profile, không chỉ backup |

Restart server sau khi sửa config:

```bash
docker compose restart valheim
```

## Biến môi trường (.env)

| Biến                | Mô tả                                              |
| ------------------- | -------------------------------------------------- |
| `PLAYIT_SECRET_KEY` | Secret key từ playit.gg                            |
| `SERVER_NAME`       | Tên hiển thị trong server browser                  |
| `WORLD_NAME`        | Tên world (không có khoảng trắng)                  |
| `SERVER_PASS`       | Mật khẩu join (≥ 5 ký tự, không trùng tên server)  |
| `SERVER_PUBLIC`     | `false` = private, join qua playit                 |
| `BEPINEX`           | `true` = bật mod support                           |
| `ADMINLIST_IDS`     | SteamID64 admin (để trống nếu không cần admin)     |
| `PUID` / `PGID`     | UID/GID chạy container (Linux: `setup.sh` tự điền) |
| `TZ`                | Múi giờ (vd: `Asia/Ho_Chi_Minh`)                   |

Xem thêm tùy chọn trong `.env.example`.

> **Lưu ý `.env`:** Giá trị có khoảng trắng hoặc cron (`*`) phải bọc dấu `"` — vd: `SERVER_NAME="My Server"`, `BACKUPS_CRON="0 */6 * * *"`. Native dùng parser an toàn; Docker Compose cũng khuyến nghị quote.

## Dữ liệu lưu ở đâu

```
config/
├── worlds_local/          ← world (.db, .fwl) — WORLD_NAME trỏ vào đây
├── characters_local/      ← nhân vật ServerCharacters
├── backups/
└── bepinex/
    ├── plugins/           ← mod DLL (server đọc qua symlink)
    └── config/            ← BepInEx + ServerCharacters config (CHỖ DÙNG)
data/                      ← Docker only
server/                    ← Native only (game binary, không sửa tay)
```

**Native:** `-savedir` = `config/` (không phải `config/worlds_local/`). Valheim tự tạo `worlds_local/` bên trong.

**BepInEx:** chỉ `config/bepinex/config/` được dùng. File `.cfg` ở `config/bepinex/` (ngoài thư mục `config/`) là duplicate — chạy `./native/fix-data-layout.sh` để gom lại.

**SCP world từ local:** copy vào `config/worlds_local/` (file `.db`/`.fwl` nằm trực tiếp trong đó, không tạo thêm cấp con).

Dữ liệu nằm trong thư mục project, **không** liên quan `AppData\LocalLow\IronGate\Valheim` trên Windows (đó là save client).

## Lệnh thường dùng

Container **không** tự chạy khi mở máy — chỉ start khi bạn chạy lệnh.

```bash
# Bật server (khi cần chơi)
docker compose up -d

# Xem log
docker compose logs -f valheim

# Tắt server
docker compose down

# Cập nhật image
docker compose pull && docker compose up -d
```

## Crossplay (tùy chọn)

Bỏ comment `CROSSPLAY=true` trong `.env`, thêm tunnel UDP port **2458** trên playit. Mọi client cần tương thích crossplay.

## Cấu trúc thư mục

```
Valheim/
├── docker-compose.yml
├── .env.example
├── README.md
├── native/                    ← SteamCMD native (VPS)
│   ├── setup.sh
│   ├── uninstall.sh
│   ├── fix-data-layout.sh
│   ├── link-bepinex-config.sh
│   ├── start-server.sh
│   ├── backup-world.sh
│   ├── update-server.sh
│   └── install-serverdevcommands.sh
├── linux/                     ← Docker (Linux)
│   ├── setup.sh
│   └── install-servercharacters.sh
└── windows/                   ← Docker (Windows)
    ├── setup.bat
    ├── setup.ps1
    └── install-servercharacters.ps1
```

## Xử lý lỗi

### Native

**World không load / tạo world mới lạ (Dedicated) thay vì SuperSeed2**  
→ `-savedir` sai tạo `worlds_local/worlds_local/`. Chạy:
```bash
systemctl stop valheim
# git pull nếu có bản mới, hoặc sửa tay common.sh: -savedir phải là config/ không phải config/worlds_local/
./native/fix-data-layout.sh
# .env: WORLD_NAME=SuperSeed2
systemctl start valheim
```

**Hai chỗ config BepInEx**  
→ Chỉ `config/bepinex/config/` được dùng. `./native/fix-data-layout.sh` gom file từ `config/bepinex/*.cfg` vào đó.

**Server không start**  
→ `journalctl -u valheim -n 50` — kiểm tra `SERVER_PASS` ≥ 5 ký tự.

**Client không vào được**  
→ Mở firewall UDP 2456–2457. Join bằng `IP_VPS:2456`. Client phải cài ServerCharacters cùng version.

**Thiếu lib32 khi cài SteamCMD**  
→ `sudo ./native/install-deps.sh` rồi chạy lại `./native/setup.sh`.

### Docker

**Docker không chạy (Windows)**  
→ Mở Docker Desktop, đợi icon xanh rồi chạy lại `setup.bat`.

**Server chưa sẵn sàng**  
→ `docker compose logs -f valheim` — đợi dòng báo server started.

**Client không vào được**  
→ Kiểm tra tunnel playit trỏ đúng `127.0.0.1:2456` và `127.0.0.1:2457`. Client phải cài ServerCharacters cùng version.

**Playit không kết nối (Windows)**  
→ `network_mode: host` trên Docker Desktop có thể hạn chế. Thử chạy trên Linux/WSL2, hoặc kiểm tra log: `docker compose logs -f playit`.

**Mật khẩu bị từ chối**  
→ `SERVER_PASS` phải ≥ 5 ký tự và không được là substring của `SERVER_NAME`.

**Permission denied khi chạy setup.sh**  
→ File `config/` bị Docker tạo với quyền root. Chạy một lần:

```bash
sudo chown -R $(id -u):$(id -g) config data
./linux/setup.sh
```

`setup.sh` sẽ set `PUID`/`PGID` trong `.env` để container không tạo file root nữa.
