#!/usr/bin/env bash
# Cấu hình chung cho mọi script trong repo.
# KHÔNG tự đổi TCPDUMP_FLAGS: mọi công cụ phải chạy tcpdump với cùng một lệnh để số liệu so được với nhau.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_DIR="$ROOT/src"        # mã nguồn tải về (không commit)
BUILD_DIR="$ROOT/build"    # bản build (không commit)
BIN_DIR="$ROOT/bin"        # link tới các binary tcpdump (không commit)

# Lệnh chuẩn: tcpdump $TCPDUMP_FLAGS -r <file>
# -nn: không phân giải tên (không gọi DNS), -vvv -e -XX: in chi tiết để chạy qua nhiều parser hơn.
TCPDUMP_FLAGS="-nn -vvv -e -XX"
PER_FILE_TIMEOUT=10        # giây cho mỗi file đầu vào

# Phiên bản libpcap đi cùng từng phiên bản tcpdump.
libpcap_for() {
  case "$1" in
    4.9.2|4.9.3) echo 1.8.0 ;;
    4.99.7)      echo 1.10.7 ;;
    *) echo "Phiên bản không hỗ trợ: $1 (dùng 4.9.2, 4.9.3 hoặc 4.99.7)" >&2; return 1 ;;
  esac
}

# Mã nguồn 2016-2017 cần thêm cờ để build được với gcc/clang mới (Ubuntu 24.04, Kali).
needs_compat() { case "$1" in 4.9.*|1.8.*) return 0 ;; *) return 1 ;; esac; }
COMPAT_FLAGS="-fcommon -Wno-error=implicit-int -Wno-error=implicit-function-declaration -Wno-error=int-conversion -Wno-error=incompatible-pointer-types"

# Tải mã nguồn: ưu tiên bản phát hành trên tcpdump.org, không được thì lấy tag trên GitHub.
fetch_src() {
  local name="$1" ver="$2" dest="$SRC_DIR/$1-$2" url tmp
  [ -f "$dest/.fetched" ] && return 0
  rm -rf "$dest"; mkdir -p "$dest"
  case "$name-$ver" in
    libpcap-1.8.0) url="https://github.com/the-tcpdump-group/libpcap/archive/refs/tags/libpcap-1.8.0.tar.gz" ;;  # tcpdump.org không còn 1.8.0
    tcpdump-4.9.*) url="https://www.tcpdump.org/release/$name-$ver.tar.gz" ;;
    *)             url="https://www.tcpdump.org/release/$name-$ver.tar.xz" ;;
  esac
  tmp="$(mktemp)"
  if curl -fsSL --retry 2 --max-time 120 -o "$tmp" "$url" 2>/dev/null && tar -xf "$tmp" -C "$dest" --strip-components=1; then
    echo "[fetch] $name $ver <- $url"
  else
    echo "[fetch] không tải được $url, lấy tag $name-$ver trên GitHub"
    rm -rf "$dest"
    git -c advice.detachedHead=false clone -q --depth 1 --branch "$name-$ver" \
      "https://github.com/the-tcpdump-group/$name" "$dest"
  fi
  rm -f "$tmp"
  # Bản lấy từ git của 4.99.x / 1.10.x chưa có sẵn configure.
  if [ ! -x "$dest/configure" ]; then
    (cd "$dest" && if [ -x ./autogen.sh ]; then ./autogen.sh; else autoreconf -fi; fi) >"$dest/.autogen.log" 2>&1 \
      || { echo "[fetch] tạo configure thất bại, xem $dest/.autogen.log" >&2; return 1; }
  fi
  touch "$dest/.fetched"
}
