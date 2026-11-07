#!/usr/bin/env bash
# Tải mã nguồn và build tcpdump + libpcap (libpcap build tĩnh, cùng cờ với tcpdump).
# Dùng:   bash targets/build.sh <phiên bản> <biến thể>
#   phiên bản: 4.9.2 (bản cũ) | 4.9.3 (bản đối chiếu đã vá) | 4.99.7 (bản mới)
#   biến thể : plain | asan | cov | afl | msan
# Kết quả: bin/tcpdump-<phiên bản>-<biến thể>, log ở build/<phiên bản>-<biến thể>/build.log
source "$(dirname "$0")/../scripts/common.sh"

VER="${1:?Thiếu phiên bản: 4.9.2 | 4.9.3 | 4.99.7}"
VARIANT="${2:?Thiếu biến thể: plain | asan | cov | afl | msan}"
PCAP_VER="$(libpcap_for "$VER")"

case "$VARIANT" in
  plain) CC_DEFAULT=clang;          FLAGS="-g -O2" ;;
  # ASan + UBSan; bỏ kiểm tra alignment vì tcpdump đọc dữ liệu không căn lề có chủ đích trên x86 (gây nhiễu).
  asan)  CC_DEFAULT=clang;          FLAGS="-g -O1 -fno-omit-frame-pointer -fsanitize=address,undefined -fno-sanitize=alignment" ;;
  # Bản đo độ phủ, dùng gcc để khớp với gcov/lcov.
  cov)   CC_DEFAULT=gcc;            FLAGS="-g -O0 --coverage" ;;
  # Bản cho AFL++ kèm ASan (vai 2). Cần afl-clang-fast.
  afl)   CC_DEFAULT=afl-clang-fast; FLAGS="-g -O1 -fno-omit-frame-pointer"; export AFL_USE_ASAN=1 ;;
  # Bản MSan (tuỳ chọn), chỉ clang hỗ trợ.
  msan)  CC_DEFAULT=clang;          FLAGS="-g -O1 -fno-omit-frame-pointer -fsanitize=memory -fsanitize-memory-track-origins" ;;
  *) echo "Biến thể không hỗ trợ: $VARIANT" >&2; exit 1 ;;
esac
CC="${CC:-$CC_DEFAULT}"
command -v "$CC" >/dev/null || { echo "Không tìm thấy compiler $CC. Chạy env/install_deps.sh trước." >&2; exit 1; }
needs_compat "$VER" && FLAGS="$FLAGS $COMPAT_FLAGS"

fetch_src tcpdump "$VER"
fetch_src libpcap "$PCAP_VER"

OUT="$BUILD_DIR/$VER-$VARIANT"
LOG="$OUT/build.log"
rm -rf "$OUT"; mkdir -p "$OUT" "$BIN_DIR"
# tcpdump tự tìm libpcap ở thư mục ../libpcap, nên đặt hai thư mục cạnh nhau.
cp -a "$SRC_DIR/libpcap-$PCAP_VER" "$OUT/libpcap"
cp -a "$SRC_DIR/tcpdump-$VER" "$OUT/tcpdump"

echo "[build] tcpdump $VER + libpcap $PCAP_VER, biến thể $VARIANT, CC=$CC"
fail() { echo "[build] LỖI khi build $1, 30 dòng cuối của $LOG:" >&2; tail -30 "$LOG" >&2; exit 1; }

( cd "$OUT/libpcap" &&
  CC="$CC" CFLAGS="$FLAGS" LDFLAGS="$FLAGS" ./configure --disable-shared \
     --disable-dbus --disable-rdma --disable-bluetooth --disable-usb --without-libnl &&
  make -j"$(nproc)" ) >"$LOG" 2>&1 || fail libpcap

( cd "$OUT/tcpdump" &&
  CC="$CC" CFLAGS="$FLAGS" LDFLAGS="$FLAGS" ./configure --without-crypto --without-smi --without-cap-ng &&
  make -j"$(nproc)" ) >>"$LOG" 2>&1 || fail tcpdump

ln -sf "$OUT/tcpdump/tcpdump" "$BIN_DIR/tcpdump-$VER-$VARIANT"
# Kiểm tra binary đã link đúng libpcap vừa build.
"$BIN_DIR/tcpdump-$VER-$VARIANT" --version 2>&1 | head -2 | sed 's/^/[build]   /'
echo "[build] Xong: bin/tcpdump-$VER-$VARIANT"
