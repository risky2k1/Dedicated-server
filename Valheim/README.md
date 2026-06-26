# Valheim Dedicated Server

Server Valheim với mod **ServerCharacters** (lưu nhân vật trên server, chống mang đồ từ world khác).

Hai cách deploy:

| Cách | Thư mục | Phù hợp |
|------|---------|---------|
| **Docker** | `./linux/setup.sh` | Tiện, tự update/backup |
| **Native** | `./native/setup.sh` | VPS RAM thấp (3 GB), có IP public |

## Yêu cầu

### Docker (Linux / Windows)

| | Linux | Windows |
|---|-------|---------|
| Docker | Docker Engine + Compose v2 | [Docker Desktop](https://www.docker.com/products/docker-desktop/) |
| Dung lượng | ~2 GB trống | ~2 GB trống |

### Native (Linux VPS)

| | Yêu cầu |
|---|---------|
| OS | Ubuntu 22.04 / 24.04 |
| RAM | 3 GB+ (khuyến nghị 4 GB) |
| CPU | 2 vCPU |
| Disk | 30 GB NVMe |
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
```

**Dữ liệu** dùng chung với Docker: `config/worlds_local/`, `config/bepinex/`.

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

| Setting | Giá trị | Lý do |
|---------|---------|-------|
| Single Character Mode | `true` | Mỗi SteamID chỉ 1 nhân vật |
| Backup Only Mode | `false` | Server enforce profile, không chỉ backup |

Restart server sau khi sửa config:

```bash
docker compose restart valheim
```

## Biến môi trường (.env)

| Biến | Mô tả |
|------|-------|
| `PLAYIT_SECRET_KEY` | Secret key từ playit.gg |
| `SERVER_NAME` | Tên hiển thị trong server browser |
| `WORLD_NAME` | Tên world (không có khoảng trắng) |
| `SERVER_PASS` | Mật khẩu join (≥ 5 ký tự, không trùng tên server) |
| `SERVER_PUBLIC` | `false` = private, join qua playit |
| `BEPINEX` | `true` = bật mod support |
| `ADMINLIST_IDS` | SteamID64 admin (để trống nếu không cần admin) |
| `PUID` / `PGID` | UID/GID chạy container (Linux: `setup.sh` tự điền) |
| `TZ` | Múi giờ (vd: `Asia/Ho_Chi_Minh`) |

Xem thêm tùy chọn trong `.env.example`.

## Dữ liệu lưu ở đâu

```
config/
├── worlds_local/          ← world (.db, .fwl)
├── backups/               ← backup world tự động
└── bepinex/
    ├── plugins/           ← mod DLL
    └── config/            ← cấu hình mod + file nhân vật server
data/                      ← file game server (cache, tự tải)
```

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
│   ├── start-server.sh
│   ├── backup-world.sh
│   └── update-server.sh
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
