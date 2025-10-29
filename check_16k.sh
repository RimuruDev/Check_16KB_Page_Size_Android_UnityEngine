cat > ~/check_16k.sh <<'SH'
#!/usr/bin/env bash
set -euo pipefail

AAB="${1:-}"
if [[ -z "$AAB" ]]; then
  echo "Usage: check_16k.sh /path/to/app.aab"
  exit 2
fi
if [[ ! -f "$AAB" ]]; then
  echo "File not found: $AAB"
  exit 2
fi

OUT="$(mktemp -d /tmp/aab.XXXXXX)"
unzip -q "$AAB" -d "$OUT"

LLVM="${LLVM:-/opt/homebrew/opt/llvm/bin/llvm-readelf}"
"$LLVM" --version >/dev/null 2>&1 || { echo "llvm-readelf not found. brew install llvm"; exit 1; }

bad=0
while IFS= read -r -d '' so; do
  if ! "$LLVM" -l "$so" \
     | awk '/Program Headers:/, /Section to Segment mapping:/{ if ($1=="LOAD" && $NF!="0x4000") bad=1 } END{ exit bad }'
  then
    echo "BAD: $so"
    bad=1
  fi
done < <(find "$OUT" -path '*arm64-v8a*' -name '*.so' -print0)

[[ $bad -eq 0 ]] && echo "OK: all arm64-v8a libs have LOAD Align 0x4000"
rm -rf "$OUT"
SH

chmod +x ~/check_16k.sh
