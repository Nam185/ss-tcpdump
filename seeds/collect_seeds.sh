#!/usr/bin/env bash
# Gom seed corpus chung từ thư mục tests/ của tcpdump 4.99.7 (lấy từ tag git, để ai chạy cũng ra đúng một bộ file).
# Lần đầu tạo seeds/corpus-v1.sha256; các lần sau so với file đó để chắc cả nhóm dùng chung corpus.
# Dùng: bash seeds/collect_seeds.sh   (bỏ file lớn hơn MAX_SEED_BYTES, mặc định 1 MiB)
source "$(dirname "$0")/../scripts/common.sh"

MAX="${MAX_SEED_BYTES:-1048576}"
DEST="$ROOT/seeds/corpus-v1"
MANIFEST="$ROOT/seeds/corpus-v1.sha256"
GIT_SRC="$SRC_DIR/tcpdump-4.99.7-git"

if [ ! -d "$GIT_SRC/tests" ]; then
  mkdir -p "$SRC_DIR"
  git -c advice.detachedHead=false clone -q --depth 1 --branch tcpdump-4.99.7 \
    https://github.com/the-tcpdump-group/tcpdump "$GIT_SRC"
fi

rm -rf "$DEST"; mkdir -p "$DEST"
declare -A seen=()
kept=0; dup=0; big=0
while IFS= read -r -d '' f; do
  if [ "$(stat -c %s "$f")" -gt "$MAX" ]; then big=$((big + 1)); continue; fi
  h="$(sha256sum "$f" | cut -d' ' -f1)"
  if [ -n "${seen[$h]:-}" ]; then dup=$((dup + 1)); continue; fi
  seen[$h]=1
  cp "$f" "$DEST/"
  kept=$((kept + 1))
done < <(find "$GIT_SRC/tests" -maxdepth 1 -type f \( -name '*.pcap' -o -name '*.pcapng' \) -print0 | sort -z)
echo "[seeds] $kept file trong seeds/corpus-v1 (bỏ $dup file trùng nội dung, $big file > $MAX byte)"

NEW="$(mktemp)"
(cd "$DEST" && find . -type f -printf '%P\n' | LC_ALL=C sort | xargs -d '\n' sha256sum) > "$NEW"
if [ -f "$MANIFEST" ]; then
  if cmp -s "$NEW" "$MANIFEST"; then
    echo "[seeds] Khớp seeds/corpus-v1.sha256: corpus giống hệt của cả nhóm"
  else
    echo "[seeds] CẢNH BÁO: corpus khác seeds/corpus-v1.sha256, báo vai 1 trước khi chạy chính thức" >&2
  fi
  rm -f "$NEW"
else
  mv "$NEW" "$MANIFEST"
  echo "[seeds] Đã tạo seeds/corpus-v1.sha256 (commit file này, không commit thư mục corpus)"
fi
