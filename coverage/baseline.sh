#!/usr/bin/env bash
# Đo độ phủ dòng và nhánh của tcpdump khi chạy toàn bộ seed corpus (baseline, chưa fuzz).
# Dùng: bash coverage/baseline.sh [phiên bản]   (mặc định 4.99.7)
# Kết quả: results/coverage/<phiên bản>/baseline/summary.txt (commit), báo cáo HTML ở coverage/out/ (không commit)
source "$(dirname "$0")/../scripts/common.sh"

VER="${1:-4.99.7}"
BIN="$BIN_DIR/tcpdump-$VER-cov"
SEEDS="$ROOT/seeds/corpus-v1"
[ -x "$BIN" ] || bash "$ROOT/targets/build.sh" "$VER" cov
[ -d "$SEEDS" ] || bash "$ROOT/seeds/collect_seeds.sh"

TDIR="$BUILD_DIR/$VER-cov/tcpdump"
OUT="$ROOT/coverage/out/$VER-baseline"
RES="$ROOT/results/coverage/$VER/baseline"
rm -rf "$OUT"; mkdir -p "$OUT" "$RES"

# lcov 1.x (Ubuntu 22.04) và 2.x (Ubuntu 24.04, Kali) dùng tên tuỳ chọn khác nhau.
if lcov --version | grep -qE 'version 1\.'; then
  RC=(--rc lcov_branch_coverage=1); IGN=()
else
  RC=(--rc branch_coverage=1); IGN=(--ignore-errors mismatch,negative,unused,inconsistent)
fi

find "$TDIR" -name '*.gcda' -delete
ok=0; bad=0
for f in "$SEEDS"/*; do
  if timeout "$PER_FILE_TIMEOUT" "$BIN" $TCPDUMP_FLAGS -r "$f" >/dev/null 2>&1; then ok=$((ok + 1)); else bad=$((bad + 1)); fi
done

lcov -q --capture --directory "$TDIR" --output-file "$OUT/baseline.info" "${RC[@]}" "${IGN[@]}" 2>"$OUT/lcov.log"
genhtml -q "$OUT/baseline.info" --output-directory "$OUT/html" "${RC[@]}" "${IGN[@]}" >>"$OUT/lcov.log" 2>&1 || true

{
  echo "Baseline coverage: tcpdump $VER (biến thể cov), $(date -Iseconds)"
  echo "Lệnh: tcpdump $TCPDUMP_FLAGS -r <file>, timeout ${PER_FILE_TIMEOUT}s/file"
  echo "Seed corpus: seeds/corpus-v1 ($((ok + bad)) file; $ok chạy xong, $bad thoát với mã lỗi hoặc timeout)"
  lcov --summary "$OUT/baseline.info" "${RC[@]}" "${IGN[@]}" 2>&1 | grep -E 'lines|functions|branches'
} | tee "$RES/summary.txt"
bash "$ROOT/scripts/machine_info.sh" > "$RES/MACHINE.md"
echo "[coverage] Báo cáo HTML: coverage/out/$VER-baseline/html/index.html"
