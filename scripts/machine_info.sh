#!/usr/bin/env bash
# In cấu hình máy dạng Markdown. Lưu cạnh mỗi kết quả:
#   bash scripts/machine_info.sh > results/<tool>/<version>/<tên lần chạy>/MACHINE.md
v() { command -v "$1" >/dev/null 2>&1 && "$@" 2>&1 | head -1 || echo "chưa cài"; }
echo "# Máy chạy"
echo
echo "- Thời điểm: $(date -Iseconds)"
echo "- Người chạy: ${RUNNER:-<điền tên>}"
echo "- OS: $( (. /etc/os-release 2>/dev/null && echo "$PRETTY_NAME") || uname -s)"
echo "- Kernel: $(uname -r)"
echo "- Máy ảo: $(systemd-detect-virt 2>/dev/null || echo 'không rõ')"
echo "- CPU: $(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | sed 's/^ //'), $(nproc) nhân dùng được"
echo "- RAM: $(free -h | awk '/^Mem:/ {print $2}')"
echo "- clang: $(v clang --version)"
echo "- gcc: $(v gcc --version)"
echo "- AFL++: $(command -v afl-fuzz >/dev/null && (afl-fuzz -h 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -m1 -oE '\+\+[0-9][0-9a-z.]*' || echo 'có') || echo 'chưa cài')"
echo "- Valgrind: $(v valgrind --version)"
echo "- cppcheck: $(v cppcheck --version)"
echo "- ESBMC: $(v esbmc --version)"
