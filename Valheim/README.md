# Valheim Dedicated Server (Docker)

Server Valheim chạy bằng Docker, tự port forward qua [playit.gg](https://playit.gg), có mod **ServerCharacters** để lưu nhân vật trên server (chống mang đồ từ world khác).

## Yêu cầu

| | Linux | Windows |
|---|-------|---------|
| Docker | Docker Engine + Compose v2 | [Docker Desktop](https://www.docker.com/products/docker-desktop/) (bật WSL2 backend) |
| Mạng | Internet ổn định | Internet ổn định |
| Dung lượng | ~2 GB trống (game + world) | ~2 GB trống |

## Cài nhanh

### Linux

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
├── linux/
│   ├── setup.sh
│   └── install-servercharacters.sh
└── windows/
    ├── setup.bat
    ├── setup.ps1
    └── install-servercharacters.ps1
```

## Xử lý lỗi

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
