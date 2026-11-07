#!/usr/bin/env bash
# Cài gói cần thiết trên Ubuntu 22.04/24.04 hoặc Kali (Debian).
# Dùng: bash env/install_deps.sh
set -euo pipefail
SUDO=""; [ "$(id -u)" -ne 0 ] && SUDO="sudo"

PKGS=(build-essential clang flex bison autoconf automake git curl xz-utils
      lcov valgrind cppcheck clang-tools afl++)
$SUDO apt-get update
$SUDO apt-get install -y "${PKGS[@]}"
# Runtime của ASan/MSan cho clang: Ubuntu 24.04 và Kali tách ra gói riêng; Ubuntu 22.04 đã có sẵn.
$SUDO apt-get install -y libclang-rt-dev 2>/dev/null || true

# Kiểm tra clang build được chương trình có ASan.
t="$(mktemp -d)"; echo 'int main(void){return 0;}' > "$t/t.c"
if clang -fsanitize=address,undefined "$t/t.c" -o "$t/t" 2>/dev/null && "$t/t"; then
  echo "[ok] clang + ASan chạy được"
else
  echo "[!] clang chưa có runtime ASan: cài gói libclang-rt-<số phiên bản clang>-dev, ví dụ libclang-rt-18-dev"
fi
rm -rf "$t"

echo
echo "Đã cài: ${PKGS[*]}"
echo "Còn cài tay theo vai:"
echo "  - Radamsa (vai 3): build từ https://gitlab.com/akihe/radamsa hoặc 'brew install radamsa'."
echo "  - ESBMC (vai 4): Ubuntu dùng 'sudo add-apt-repository ppa:esbmc/esbmc && sudo apt install esbmc';"
echo "    Kali không dùng được PPA, tải bản build sẵn ở trang release GitHub của ESBMC."
echo "  - Docker (vai 1, dự phòng): gói docker.io hoặc Docker Desktop."
