#!/usr/bin/env bash
set -e

# Giữ nguyên đường dẫn Linux trên Windows / Git Bash
export MSYS_NO_PATHCONV=1

echo "--- 0. Dọn dẹp container cũ nếu có ---"
docker rm -f db-server app-container 2>/dev/null || true
docker volume rm db-data 2>/dev/null || true

echo "--- 1. Tạo Custom Bridge Network: app-net ---"
docker network create app-net || true

echo "--- 2. Tạo Named Volume: db-data ---"
docker volume create db-data || true

echo "--- 3. Khởi chạy Database Container (db-server) ---"
docker run -d  --name db-server  --network app-net  -v db-data:/var/lib/postgresql/data  -e POSTGRES_DB=testdb  -e POSTGRES_USER=admin  -e POSTGRES_PASSWORD=secret postgres:15-alpine

echo "Đang đợi PostgreSQL khởi động xong..."
sleep 5

echo "--- 4. Khởi chạy Backend Container (app-container) ---"
# Sử dụng image hw-backend:v1 đã build từ Ex2
docker run -d \
  --name app-container \
  --network app-net \
  -p 8081:3000 \
  -e DB_HOST=db-server \
  -e DB_PORT=5432 \
  -e DB_NAME=testdb \
  -e DB_USER=admin \
  -e DB_PASSWORD=secret \
  hw-backend:v1

echo "--- Kiểm tra kết nối mạng giữa 2 Container (Ping) ---"
docker exec app-container ping -c 2 db-server

echo "=============================================="
echo "--- Bắt đầu Test Data Persistence ---"
echo "=============================================="

echo "-> Thêm bảng và dữ liệu mẫu vào db-server:"
docker exec -i db-server psql -U admin -d testdb -c "
CREATE TABLE IF NOT EXISTS students (id SERIAL PRIMARY KEY, name VARCHAR(50));
INSERT INTO students (name) VALUES ('Hoang Nguyen Duc');
SELECT * FROM students;
"

echo "-> Xóa cứng container Database (docker rm -f db-server):"
docker rm -f db-server 

echo "-> Khởi chạy lại container DB mới gắn cùng volume db-data:"
docker run -d \
  --name db-server \
  --network app-net \
  -v db-data:/var/lib/postgresql/data \
  -e POSTGRES_DB=testdb \
  -e POSTGRES_USER=admin \
  -e POSTGRES_PASSWORD=secret \
  postgres:15-alpine

echo "Đang đợi container DB mới khởi động..."
sleep 5

echo "-> Xác minh dữ liệu không bị mất:"
docker exec -i db-server psql -U admin -d testdb -c "SELECT * FROM students;"

echo ">>> Hoàn tất bài 4: Dữ liệu vẫn nguyên vẹn sau khi tái tạo container! <<<"