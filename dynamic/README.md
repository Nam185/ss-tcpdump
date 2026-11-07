# dynamic/

| Thư mục | Vai | Nội dung |
| --- | --- | --- |
| `aflpp/` | Vai 2 | Script chạy AFL++, dictionary nếu có, ghi chú cấu hình |
| `radamsa/` | Vai 3 | Script sinh mẫu và chạy hàng loạt |
| `valgrind/` | Vai 3 | Script chạy Valgrind Memcheck trên một tập đầu vào |
| `msan/` | Vai 3 | Script chạy lại tập đầu vào qua bản MSan |

Binary dùng chung do `targets/build.sh` tạo, ví dụ `bin/tcpdump-4.9.2-afl`, `bin/tcpdump-4.9.2-asan`.
Lệnh chạy tcpdump lấy từ `TCPDUMP_FLAGS` trong `scripts/common.sh`, không tự đổi.
Output đặt trong `dynamic/<tool>/out*/` (đã bị .gitignore chặn); nén và đưa lên Drive khi xong.
