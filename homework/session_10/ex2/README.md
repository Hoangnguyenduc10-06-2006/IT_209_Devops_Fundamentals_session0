nội dung thực hành trên gt bash:
Admin@DESKTOP-KQ5OUNR MINGW64 /e/[IT-209]_Devops_Fundamentals/btvn/session10/homework/session_10/ex2
$ docker build -t hw-backend:v1 .
[+] Building 2.1s (11/11) FINISHED                                                                                                                                                                            docker:desktop-linux
 => [internal] load build definition from Dockerfile                                                                                                                                                                          0.0s 
 => => transferring dockerfile: 670B                                                                                                                                                                                          0.0s 
 => [internal] load metadata for docker.io/library/node:18-alpine                                                                                                                                                             1.7s 
 => [auth] library/node:pull token for registry-1.docker.io                                                                                                                                                                   0.0s 
 => [internal] load .dockerignore                                                                                                                                                                                             0.0s 
 => => transferring context: 2B                                                                                                                                                                                               0.0s 
 => [1/5] FROM docker.io/library/node:18-alpine@sha256:8d6421d663b4c28fd3ebc498332f249011d118945588d0a35cb9bc4b8ca09d9e                                                                                                       0.0s 
 => => resolve docker.io/library/node:18-alpine@sha256:8d6421d663b4c28fd3ebc498332f249011d118945588d0a35cb9bc4b8ca09d9e                                                                                                       0.0s 
 => [internal] load build context                                                                                                                                                                                             0.0s 
 => => transferring context: 4.09kB                                                                                                                                                                                           0.0s 
 => CACHED [2/5] WORKDIR /app                                                                                                                                                                                                 0.0s 
 => CACHED [3/5] COPY package*.json ./                                                                                                                                                                                        0.0s 
 => CACHED [4/5] RUN npm install --omit=dev && npm cache clean --force                                                                                                                                                        0.0s 
 => [5/5] COPY . .                                                                                                                                                                                                            0.0s 
 => exporting to image                                                                                                                                                                                                        0.2s 
 => => exporting layers                                                                                                                                                                                                       0.1s 
 => => exporting manifest sha256:3c9023a04dfd2094e71aba51aaaf005a3e4c5d30e313f5d7a74421cee661a85e                                                                                                                             0.0s 
 => => exporting config sha256:4a7dac313482d5f93c65a9107b31de4c5baf99a233f6da4d79330397a3669a52                                                                                                                               0.0s 
 => => exporting attestation manifest sha256:9e98f34c97844408e4418c2ba284f7f8070f5dfc87fc74c47949baeef1a08d3d                                                                                                                 0.0s 
 => => exporting manifest list sha256:03fb9fd9310f2e2644fd86c2b77f8ec83e91177f2d110bfdcb910f34bf7426c7                                                                                                                        0.0s 
 => => naming to docker.io/library/hw-backend:v1                                                                                                                                                                              0.0s 
 => => unpacking to docker.io/library/hw-backend:v1                                                                                                                                                                           0.0s 

View build details: docker-desktop://dashboard/build/desktop-linux/desktop-linux/w520r5wpc4a2r66w47bf3g0ie

Admin@DESKTOP-KQ5OUNR MINGW64 /e/[IT-209]_Devops_Fundamentals/btvn/session10/homework/session_10/ex2
$ docker run -d --name app-single-stage -p 8080:3000 hw-backend:v1

What's next:
    Debug this container error with Gordon → docker ai "help me fix this container error"
docker: Error response from daemon: Conflict. The container name "/app-single-stage" is already in use by container "b8063dac3c401754d50593bca0c9b2c40dc0c1a75a5ecf82ed8d34053ebabbe9". You have to remove (or rename) that container to be able to reuse that name.

Run 'docker run --help' for more information

Admin@DESKTOP-KQ5OUNR MINGW64 /e/[IT-209]_Devops_Fundamentals/btvn/session10/homework/session_10/ex2
$ docker run -d --name app-single-stage -p 8080:3000 hw-backend:v1 .

What's next:
    Debug this container error with Gordon → docker ai "help me fix this container error"
docker: Error response from daemon: Conflict. The container name "/app-single-stage" is already in use by container "b8063dac3c401754d50593bca0c9b2c40dc0c1a75a5ecf82ed8d34053ebabbe9". You have to remove (or rename) that container to be able to reuse that name.

Run 'docker run --help' for more information

Admin@DESKTOP-KQ5OUNR MINGW64 /e/[IT-209]_Devops_Fundamentals/btvn/session10/homework/session_10/ex2
$ ^C

Admin@DESKTOP-KQ5OUNR MINGW64 /e/[IT-209]_Devops_Fundamentals/btvn/session10/homework/session_10/ex2
$ ^C

Admin@DESKTOP-KQ5OUNR MINGW64 /e/[IT-209]_Devops_Fundamentals/btvn/session10/homework/session_10/ex2
$ docker ps
CONTAINER ID   IMAGE          COMMAND                  CREATED          STATUS          PORTS                                         NAMES
b8063dac3c40   f87345760578   "docker-entrypoint.s…"   23 minutes ago   Up 23 minutes   0.0.0.0:8080->3000/tcp, [::]:8080->3000/tcp   app-single-stage

Admin@DESKTOP-KQ5OUNR MINGW64 /e/[IT-209]_Devops_Fundamentals/btvn/session10/homework/session_10/ex2
$ docker rm -f app-single-stage
app-single-stage

Admin@DESKTOP-KQ5OUNR MINGW64 /e/[IT-209]_Devops_Fundamentals/btvn/session10/homework/session_10/ex2
$ docker run -d --name app-single-stage -p 8080:3000 hw-backend:v1
68a013f83f7761221d3b52f4b53a3a717f13034d0fa9174bc78e6de65a352eca

Admin@DESKTOP-KQ5OUNR MINGW64 /e/[IT-209]_Devops_Fundamentals/btvn/session10/homework/session_10/ex2
$ docker logs app-single-stage
Server listening on port 3000

Admin@DESKTOP-KQ5OUNR MINGW64 /e/[IT-209]_Devops_Fundamentals/btvn/session10/homework/session_10/ex2
$ curl -i http://localhost:8080/
HTTP/1.1 200 OK
X-Powered-By: Express
Content-Type: application/json; charset=utf-8
Content-Length: 64
ETag: W/"40-upZb7Fps+hszzRU9BoKtiCsmGCQ"
Date: Mon, 12 Oct 2026 18:48:46 GMT
Connection: keep-alive
Keep-Alive: timeout=5

{"status":"success","message":"Hello from Docker Single-stage!"}
Admin@DESKTOP-KQ5OUNR MINGW64 /e/[IT-209]_Devops_Fundamentals/btvn/session10/homework/session_10/ex2
$












# Session 10 – Bài 2: Đóng gói REST API thành Docker Image (Single-stage)

## 1. Cấu trúc thư mục

```
ex2/
├── Dockerfile      # Định nghĩa image single-stage
├── .dockerignore   # Loại node_modules, log... khỏi build context
├── package.json    # Khai báo dependency (express)
├── server.js       # Ứng dụng Express REST API
└── README.md
```

## 2. Ứng dụng

API Node.js/Express đơn giản, lắng nghe trên cổng lấy từ biến môi trường `PORT` (mặc định 3000):

| Method | Endpoint | Response |
|---|---|---|
| GET | `/` | `{"status":"success","message":"Hello from Docker Single-stage!"}` |

## 3. Giải thích Dockerfile

| Chỉ thị | Giá trị | Ý nghĩa |
|---|---|---|
| `FROM` | `node:18-alpine` | Base image Node.js 18 trên Alpine Linux, dung lượng nhỏ. |
| `WORKDIR` | `/app` | Thư mục làm việc. Các lệnh `COPY`/`RUN`/`CMD` sau đó đều chạy tại đây. |
| `ENV` | `NODE_ENV=production`, `PORT=3000` | Biến môi trường. `server.js` đọc `process.env.PORT`. |
| `COPY` | `package*.json ./` rồi `. .` | Copy `package.json` **trước** để layer `npm install` được cache. Khi chỉ sửa code, Docker không phải cài lại dependency. |
| `RUN` | `npm install --omit=dev && npm cache clean --force` | Cài dependency production và xóa cache npm để giảm dung lượng image. |
| `EXPOSE` | `3000` | Ghi chú (metadata) cổng ứng dụng lắng nghe trong container. |
| `CMD` | `["node", "server.js"]` | **Exec form**: `node` chạy trực tiếp với PID 1 (không qua `/bin/sh`), nên nhận được `SIGTERM` khi `docker stop` và tắt gọn gàng. |

## 4. Build và chạy

```bash
# Build image
docker build -t hw-backend:v1 .

# Chạy container, map cổng host 8080 -> container 3000
docker run -d --name app-single-stage -p 8080:3000 hw-backend:v1

# Kiểm tra
docker ps
docker logs app-single-stage
curl -i http://localhost:8080/
```

> Trên Windows PowerShell, `curl` là alias của `Invoke-WebRequest`. Hãy dùng `curl.exe -i http://localhost:8080/` để có output giống Linux.

## 5. Kết quả kiểm tra

**Build:** hoàn tất không lỗi (5/5 bước), image `hw-backend:v1` có dung lượng ~186MB (nội dung nén 45.6MB).

```
#9 [4/5] RUN npm install --omit=dev && npm cache clean --force
#9 2.809 added 68 packages, and audited 69 packages in 3s
#9 2.812 found 0 vulnerabilities
#10 [5/5] COPY . .
#11 naming to docker.io/library/hw-backend:v1 done
```

**`docker ps`:** container ở trạng thái **Up**

```
CONTAINER ID   IMAGE           COMMAND                  CREATED         STATUS         PORTS                                         NAMES
b8063dac3c40   hw-backend:v1   "docker-entrypoint.s…"   3 seconds ago   Up 3 seconds   0.0.0.0:8080->3000/tcp, [::]:8080->3000/tcp   app-single-stage
```

**`docker logs app-single-stage`:**

```
Server listening on port 3000
```

**`curl -i http://localhost:8080/`:** trả về **HTTP 200 OK** và JSON

```
HTTP/1.1 200 OK
X-Powered-By: Express
Content-Type: application/json; charset=utf-8
Content-Length: 64
Connection: keep-alive

{"status":"success","message":"Hello from Docker Single-stage!"}
```

## 6. Dọn dẹp

```bash
docker rm -f app-single-stage
docker rmi hw-backend:v1
```
