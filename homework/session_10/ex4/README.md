# Session 10 – Bài 4: Kết nối Backend + PostgreSQL bằng Docker CLI

## 1. Mục tiêu

Dựng thủ công (chỉ dùng Docker CLI, không dùng Compose) một cụm gồm 2 container:

| Thành phần | Tên | Image | Ghi chú |
|---|---|---|---|
| Network | `app-net` | – | Custom bridge network, có DNS nội bộ |
| Volume | `db-data` | – | Named volume lưu dữ liệu Postgres |
| Database | `db-server` | `postgres:15-alpine` | Mount `db-data:/var/lib/postgresql/data` |
| Backend | `app-container` | `hw-backend:v1` (bài 2) | Nhận biến kết nối `DB_HOST=db-server` |

```mermaid
flowchart LR
  subgraph app-net [Custom bridge: app-net 172.19.0.0/16]
    A[app-container<br/>172.19.0.3] -- "db-server:5432" --> D[(db-server<br/>172.19.0.2)]
  end
  D --- V[(Volume db-data)]
  H[Host :8081] --> A
```

## 2. Cách chạy

```bash
cd homework/session_10/ex4
bash commands.sh            # chạy toàn bộ kịch bản
bash commands.sh --reset    # xóa network + volume cũ, chạy lại từ đầu
```

> **Lưu ý Windows/Git Bash:** script đặt `MSYS_NO_PATHCONV=1` để Git Bash không tự đổi `/var/lib/postgresql/data` thành đường dẫn Windows. Khi gõ tay lệnh `docker exec -it` trong Git Bash, nếu gặp lỗi *"the input device is not a TTY"* thì thêm `winpty` ở đầu lệnh hoặc bỏ `-t`.

## 3. Các bước trong `commands.sh`

**Bước 1. Tạo custom bridge network**

```bash
docker network create --driver bridge app-net
```

Khác với bridge mặc định (`docker0`), custom bridge có **DNS nội bộ** (embedded DNS `127.0.0.11`), nên các container gọi nhau bằng **tên container** thay vì IP.

**Bước 2. Tạo named volume**

```bash
docker volume create db-data
```

Volume do Docker quản lý (`/var/lib/docker/volumes/db-data`) và tồn tại độc lập với vòng đời container.

**Bước 3. Chạy database**

```bash
docker run -d --name db-server --network app-net \
  -v db-data:/var/lib/postgresql/data \
  -e POSTGRES_USER=appuser -e POSTGRES_PASSWORD=apppass -e POSTGRES_DB=appdb \
  postgres:15-alpine
```

DB **không publish port** ra host, chỉ các container trong `app-net` mới truy cập được, nên an toàn hơn.

**Bước 4. Chạy backend**

```bash
docker run -d --name app-container --network app-net -p 8081:3000 \
  -e DB_HOST=db-server -e DB_PORT=5432 \
  -e DB_USER=appuser -e DB_PASSWORD=apppass -e DB_NAME=appdb \
  -e DATABASE_URL=postgres://appuser:apppass@db-server:5432/appdb \
  hw-backend:v1
```

Biến kết nối dùng **hostname `db-server`**, không hardcode IP. Backend map cổng 8081 để không trùng với `app-single-stage` (8080) của bài 2. Nếu chưa có image `hw-backend:v1`, script tự build từ `../ex2`.

**Bước 5. Test Data Persistence**

1. Tạo bảng `students` và insert 3 dòng, lưu lại số dòng và mã md5 của dữ liệu.
2. Xóa cứng container: `docker rm -f db-server`.
3. Chạy lại container `db-server` **mới** (ID khác) gắn cùng `-v db-data:/var/lib/postgresql/data`.
4. Truy vấn lại và so sánh số dòng và md5. Script in **PASS** nếu trùng khớp.

## 4. Kết quả kiểm tra

**`docker network ls | grep app-net`** và **`docker volume ls | grep db-data`**

```
f355689d5dc8   app-net                     bridge    local
local     db-data
```

**`docker network inspect app-net`** (rút gọn): cả 2 container cùng nằm trong subnet `172.19.0.0/16`

```json
"Driver": "bridge",
"Config": [{ "Subnet": "172.19.0.0/16", "Gateway": "172.19.0.1" }],
"Containers": {
    "8d6121b4b4f3...": { "Name": "db-server",     "IPv4Address": "172.19.0.2/16" },
    "eda46e3a49e4...": { "Name": "app-container", "IPv4Address": "172.19.0.3/16" }
}
```

**`docker exec -it app-container ping -c 2 db-server`**: hostname được phân giải thành IP nội bộ `172.19.0.2`

```
PING db-server (172.19.0.2): 56 data bytes
64 bytes from 172.19.0.2: seq=0 ttl=64 time=0.116 ms
64 bytes from 172.19.0.2: seq=1 ttl=64 time=0.087 ms

--- db-server ping statistics ---
2 packets transmitted, 2 packets received, 0% packet loss
```

**Biến môi trường kết nối DB trong backend**

```
DATABASE_URL=postgres://appuser:apppass@db-server:5432/appdb
DB_HOST=db-server
DB_NAME=appdb
DB_PASSWORD=apppass
DB_PORT=5432
DB_USER=appuser
```

**Data Persistence**: dữ liệu nguyên vẹn sau khi tái tạo container DB

```
--> [5.1] Thêm dữ liệu
 id |     name     |          created_at
----+--------------+-------------------------------
  1 | Nguyen Van A | 2026-10-12 18:54:23.875314+00
  2 | Tran Thi B   | 2026-10-12 18:54:23.875314+00
  3 | Le Van C     | 2026-10-12 18:54:23.875314+00
Trước khi xóa: rows=3 | md5=9b422247d6e5ee47a662fb3cd101b6a9 | container=7090273e55eb

--> [5.2] Xóa cứng container DB
db-server

--> [5.3] Khởi chạy lại container DB mới, gắn cùng volume db-data
--> [5.4] Xác minh dữ liệu
 id |     name     |          created_at
----+--------------+-------------------------------
  1 | Nguyen Van A | 2026-10-12 18:54:23.875314+00
  2 | Tran Thi B   | 2026-10-12 18:54:23.875314+00
  3 | Le Van C     | 2026-10-12 18:54:23.875314+00
Sau khi tạo lại: rows=3 | md5=9b422247d6e5ee47a662fb3cd101b6a9 | container=8d6121b4b4f3

✅ PASS: Dữ liệu nguyên vẹn sau khi tái tạo container DB (3 rows, container 7090273e55eb -> 8d6121b4b4f3)
```

## 5. Phân tích

- **Vì sao gọi được bằng hostname?** Custom bridge network có embedded DNS server. Mỗi container khi tham gia network được đăng ký bản ghi `tên-container -> IP`. Bridge mặc định không có tính năng này, chỉ hỗ trợ `--link` (đã lỗi thời).
- **Vì sao không hardcode IP?** IP của container có thể thay đổi mỗi lần tạo lại. Dùng hostname thì backend luôn tìm được DB mới mà không cần sửa cấu hình.
- **Vì sao dữ liệu không mất?** Postgres ghi dữ liệu vào `/var/lib/postgresql/data`, và thư mục này được mount từ named volume `db-data` nằm **ngoài** writable layer của container. `docker rm -f` chỉ xóa container, không xóa volume. Container mới mount lại volume đó, thấy `PG_VERSION` đã có nên bỏ qua bước init và dùng lại dữ liệu cũ. Dữ liệu chỉ mất khi chạy `docker volume rm db-data` hoặc `docker rm -v`.

## 6. Dọn dẹp

```bash
docker rm -f app-container db-server
docker volume rm db-data
docker network rm app-net
```
