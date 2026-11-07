# ss-tcpdump — BTL Software Security

Phân tích tĩnh và động tcpdump: bản cũ 4.9.2, bản đối chiếu 4.9.3 và bản mới 4.99.7.
Kế hoạch, phân vai và lịch: [doc kế hoạch](https://claude.ai/artifact/5gXdaWKT37yBEaKynsFdpN).

## Bắt đầu nhanh (Ubuntu 22.04/24.04 hoặc Kali)

```bash
bash env/install_deps.sh            # cài gói cần thiết, kiểm tra clang + ASan
bash targets/build.sh 4.9.2 asan    # tải mã nguồn và build -> bin/tcpdump-4.9.2-asan
bash seeds/collect_seeds.sh         # gom seed corpus chung -> seeds/corpus-v1/
bash coverage/baseline.sh 4.99.7    # đo độ phủ baseline -> results/coverage/4.99.7/baseline/
```

Lệnh chuẩn khi chạy tcpdump: `tcpdump -nn -vvv -e -XX -r <file>`, khai báo một chỗ ở `TCPDUMP_FLAGS` trong `scripts/common.sh`. Không ai tự đổi.

## Phiên bản và biến thể build

| Phiên bản | libpcap đi kèm | Vai trò |
| --- | --- | --- |
| 4.9.2 | 1.8.0 | Bản cũ, còn các CVE mà 4.9.3 vá |
| 4.9.3 | 1.8.0 | Bản đối chiếu đã vá, dùng cho git bisect và đếm lỗi theo bản vá |
| 4.99.7 | 1.10.7 | Bản stable mới nhất |

| Biến thể | Compiler | Dùng cho |
| --- | --- | --- |
| `plain` | clang | Chạy thường, làm mốc đo overhead |
| `asan` | clang | ASan + UBSan (bỏ kiểm tra alignment vì gây nhiễu) |
| `cov` | gcc | Đo độ phủ bằng gcov/lcov |
| `afl` | afl-clang-fast | AFL++ kèm ASan (vai 2) |
| `msan` | clang | MSan, tuỳ chọn (vai 3) |

Đã chạy thử trên Ubuntu 24.04 (clang 18, gcc 13 và gcc 14): mọi biến thể của cả 3 phiên bản build được.
Số tham khảo để tự kiểm tra cài đặt, **không dùng cho báo cáo**: baseline 4.99.7 với 723 file seed cho khoảng 47,7% dòng và 36,4% nhánh.

## Cấu trúc thư mục

```
env/        install_deps.sh
scripts/    common.sh (cấu hình chung), machine_info.sh
targets/    build.sh
seeds/      collect_seeds.sh, corpus-v1.sha256 (corpus không commit)
coverage/   baseline.sh
dynamic/    aflpp/ (vai 2), radamsa/, valgrind/, msan/ (vai 3)
static/     cppcheck/, scan-build/, esbmc/ (vai 4)
results/    kết quả nhỏ của từng lần chạy, xem results/README.md
triage/     bugs.csv: bảng lỗi chung
injected/   bản cấy lỗi (vai 1, tuần 23–29/11)
report/     nguồn báo cáo, slide
```

## Quy tắc

1. Repo để **private**. Không commit file gây crash, output fuzzer hay corpus lớn: nén rồi đưa lên Drive của nhóm, ghi đường dẫn vào `triage/bugs.csv` (cột `drive_path`).
2. Lần chạy chính thức: cùng seed corpus, cùng `TCPDUMP_FLAGS`, cùng thời lượng, trên máy chuẩn, mỗi lần 1 nhân CPU.
3. Đặt tên lần chạy `<tool>_<version>_<config>_run<k>`; kết quả ở `results/<tool>/<version>/<tên lần chạy>/` kèm `MACHINE.md`.
4. Gộp lỗi 2 bước: cùng loại lỗi ASan và cùng 3 frame đầu stack trace thì là 1 lỗi; với bản cũ, đếm theo commit sửa lỗi.
5. Không bịa số: mọi con số trong slide và báo cáo phải có nguồn trong `results/`.
6. Lỗi còn trên 4.99.7 hoặc bản git mới nhất: không công khai, báo riêng qua security@tcpdump.org kèm file pcap.

## Ghi chú cho máy ảo Kali

- Cấp cho VM ít nhất 4 vCPU, 8 GB RAM, 40 GB đĩa.
- ESBMC không cài qua PPA trên Kali được: tải bản build sẵn ở trang release GitHub của ESBMC.
- Bản 4.9.2 build được với gcc/clang mới nhờ `COMPAT_FLAGS` trong `scripts/common.sh`. Nếu vẫn lỗi, build trong Docker `ubuntu:20.04`.
