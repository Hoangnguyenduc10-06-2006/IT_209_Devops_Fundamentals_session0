# BÁO CÁO KỸ THUẬT: LÝ DO DOANH NGHIỆP CHUYỂN TỪ VPS SANG DOCKER

> **Môn học:** IT-209 – DevOps Fundamentals · **Session 10 – Bài 1**
> **Môi trường thực hiện:** Windows + Docker Desktop 4.89.0 (WSL2 backend)

---

## 1. Bối cảnh

Trước đây doanh nghiệp chạy mỗi ứng dụng trên một VPS (Virtual Private Server), tức là một máy ảo (VM) có hệ điều hành riêng. Cách làm này gây ra ba vấn đề chính: **tốn tài nguyên** (mỗi VM gánh nguyên một hệ điều hành), **triển khai chậm** (dựng VM mất hàng phút, cài đặt thủ công) và **môi trường không đồng nhất** (lỗi kiểu "máy tôi chạy được" giữa Dev, Staging và Production).

Docker giải quyết các vấn đề này bằng **container**: đóng gói ứng dụng cùng thư viện phụ thuộc thành một image nhẹ và bất biến, chạy chung kernel với máy host. Báo cáo này so sánh hai công nghệ, giải thích cơ chế kỹ thuật bên dưới container và ghi lại thông số của môi trường Docker thực tế.

---

## 2. Bảng so sánh VM (VPS) và Container

| Tiêu chí | Virtual Machine (VPS) | Container (Docker) |
|---|---|---|
| **Dung lượng image** | Lớn, từ vài **GB đến hàng chục GB**, vì chứa cả hệ điều hành khách (kernel, driver, dịch vụ hệ thống). | Nhỏ, từ vài **MB đến vài trăm MB** (ví dụ `alpine` ≈ 5 MB, `nginx:alpine` ≈ 20–50 MB). Image chia lớp (layer) nên các layer giống nhau được tái sử dụng. |
| **Thời gian khởi động** | **Vài chục giây đến vài phút**, do phải boot BIOS/UEFI, kernel và init system. | **Dưới 1 giây đến vài giây**, vì chỉ khởi chạy một tiến trình trên kernel đã chạy sẵn của host. |
| **Hao phí OS (overhead)** | **Cao.** Mỗi VM tốn RAM/CPU/Disk cho một OS riêng, cộng thêm lớp Hypervisor ảo hóa phần cứng. | **Rất thấp.** Các container dùng chung kernel của host, không có OS khách, hiệu năng gần như chạy trực tiếp (near-native). |
| **Mức độ cô lập** | **Mạnh.** Cô lập ở mức phần cứng qua Hypervisor, mỗi VM có kernel riêng, nên lỗ hổng kernel trong một VM khó ảnh hưởng sang VM khác. | **Trung bình, ở mức tiến trình.** Dựa vào Namespaces + cgroups. Các container dùng chung kernel, nên một lỗ hổng kernel có thể ảnh hưởng tới tất cả. Có thể tăng cường bằng seccomp, AppArmor/SELinux, rootless mode. |
| **Khả năng mở rộng** | **Chậm và tốn kém.** Mở rộng bằng cách tạo VM mới (mất phút), mật độ thấp (vài đến vài chục VM/host). | **Nhanh và linh hoạt.** Tạo hàng chục, hàng trăm bản sao trong vài giây, mật độ cao (hàng trăm container/host), dễ điều phối bằng Docker Compose, Swarm hay Kubernetes. |

**Nhận xét:** Container không thay thế hoàn toàn VM. Trên thực tế, container thường chạy *bên trong* VM (chính Docker Desktop cũng chạy trên VM WSL2). Tuy nhiên với ứng dụng web, microservices và CI/CD, container giúp tiết kiệm tài nguyên và tăng tốc độ triển khai rõ rệt. Đây là lý do chính khiến doanh nghiệp chuyển đổi.

---

## 3. Cơ chế kỹ thuật: Namespaces và Control Groups (cgroups)

Container thực chất là **một tiến trình Linux bình thường** được kernel "đóng khung" bằng hai cơ chế: **Namespaces** quyết định *container được nhìn thấy gì*, còn **cgroups** quyết định *container được dùng bao nhiêu tài nguyên*.

### 3.1. Namespaces: cô lập phạm vi nhìn thấy

Namespace khiến mỗi container tưởng như mình đang chạy trên một máy riêng.

| Namespace | Vai trò | Ví dụ minh họa |
|---|---|---|
| **PID** (Process) | Cô lập cây tiến trình. Tiến trình chính trong container có **PID 1** và không thấy tiến trình của host hay container khác. | `docker exec <c> ps aux` chỉ liệt kê vài tiến trình của container, trong khi host có hàng trăm. |
| **NET** (Network) | Mỗi container có network stack riêng: interface (`eth0`), địa chỉ IP, bảng định tuyến, iptables, dải port. Nhờ vậy nhiều container có thể cùng lắng nghe port 80 mà không xung đột. | Container nhận IP `172.17.0.x` trên bridge `docker0`. Ra ngoài phải publish port (`-p 8080:80`). |
| **MNT** (Mount points) | Cô lập cây thư mục mount. Container có root filesystem riêng (từ image, qua OverlayFS) và không thấy file hệ thống của host, trừ khi mount volume/bind mount một cách tường minh. | `-v ./data:/app/data` chỉ chia sẻ đúng thư mục được chỉ định. |
| UTS, IPC, USER, CGROUP | Lần lượt cô lập hostname, bộ nhớ chia sẻ/semaphore, ánh xạ UID/GID (root trong container ≠ root trên host) và cây cgroup. | `docker info` của máy thực hành có hiển thị `cgroupns` trong *Security Options*. |

### 3.2. Control Groups (cgroups): giới hạn tài nguyên

Nếu chỉ có namespace, một container vẫn có thể chiếm hết CPU/RAM của host và làm các ứng dụng khác bị đói tài nguyên (vấn đề "noisy neighbor"). **cgroups** cho phép kernel **giới hạn, phân bổ và đo lường** tài nguyên cho từng nhóm tiến trình:

- **CPU:** giới hạn số nhân sử dụng (`--cpus=1.5`), trọng số chia sẻ khi tranh chấp (`--cpu-shares`) hoặc ghim vào nhân cụ thể (`--cpuset-cpus=0,1`).
- **RAM:** đặt trần bộ nhớ (`--memory=512m`, `--memory-swap`). Khi vượt ngưỡng, kernel kích hoạt **OOM Killer** và chỉ dừng container đó, host và các container khác không bị ảnh hưởng.
- **Khác:** giới hạn I/O đĩa (`--device-read-bps`), số tiến trình tối đa (`--pids-limit`) để chống fork bomb.

```bash
# Ví dụ: chạy nginx tối đa 0.5 CPU và 256MB RAM
docker run -d --name web --cpus=0.5 --memory=256m nginx:alpine
docker stats web   # theo dõi mức sử dụng thực tế do cgroups đo được
```

**Tóm lại:** Namespaces + cgroups (cùng với filesystem dạng layer) tạo nên container: cô lập như một VM thu nhỏ nhưng không cần hypervisor hay OS khách.

---

## 4. Thông số môi trường Docker (trích xuất từ `docker info`)

Cả hai lệnh `docker version` và `docker info` đều **thực thi thành công bằng user thường** (không cần `sudo` hay quyền Administrator). Log đầy đủ nằm ở [`docker_info.log`](./docker_info.log) và [`docker_version.log`](./docker_version.log).

| Thông số | Giá trị | Ý nghĩa |
|---|---|---|
| **Server Version** | `29.7.2` | Phiên bản Docker Engine (daemon). Client cũng là 29.7.2, API 1.55. |
| **Cgroup Driver** | `cgroupfs` | Docker tự quản lý cgroups trực tiếp qua hệ thống file `/sys/fs/cgroup`. (Trên Linux dùng systemd, khuyến nghị đặt là `systemd`, nhất là khi chạy Kubernetes.) |
| **Cgroup Version** | `2` | Dùng cgroups v2 (unified hierarchy), quản lý tài nguyên thống nhất và chính xác hơn v1. |
| **Containers** | **4** (Running: 1 · Paused: 0 · Stopped: 3) | Tổng số container đang tồn tại trên host. |
| **Images** | **3** | Số image đã tải về hoặc build trên máy. |
| Storage Driver | `overlayfs` (containerd snapshotter) | Cơ chế filesystem dạng layer của image và container. |
| Kernel / OS | `6.18.40.1-microsoft-standard-WSL2` / Docker Desktop | Container chạy trên kernel Linux của VM WSL2. |
| Tài nguyên | 12 CPUs · 7.64 GiB RAM | Tài nguyên tối đa mà các container có thể dùng chung. |

Ảnh chụp log lệnh `docker info`:

![alt text](image.png)

---

## 5. Kết luận

Chuyển từ VPS sang Docker giúp doanh nghiệp **giảm chi phí hạ tầng** (mật độ ứng dụng trên mỗi máy chủ cao hơn nhiều lần), **rút ngắn thời gian triển khai** từ hàng phút xuống vài giây, **đồng nhất môi trường** từ máy lập trình viên tới Production nhờ image bất biến, và **mở rộng linh hoạt** khi lưu lượng tăng. Đổi lại, mức cô lập của container thấp hơn VM vì dùng chung kernel, nên cần áp dụng thêm các biện pháp bảo mật (chạy non-root, seccomp, giới hạn tài nguyên bằng cgroups, quét lỗ hổng image). Mô hình phù hợp nhất hiện nay là **kết hợp**: VM cung cấp ranh giới cô lập phần cứng, còn container chạy bên trong để tối ưu tốc độ và mật độ triển khai.
