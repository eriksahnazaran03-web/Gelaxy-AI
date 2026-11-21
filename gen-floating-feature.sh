MODDIR=${1:-${0%/*}}
LIST=$MODDIR/floating_feature_ai.prop
LOG=$MODDIR/floating_feature.log
: > "$LOG"

patch_one() {
  REL=$1                       # vd: system/etc/floating_feature.xml
  SRC=/$REL                    # file goc dang chay tren may
  OUT=$MODDIR/$REL
  [ -f "$SRC" ] || return 1
  grep -q '</SecFloatingFeatureSet>' "$SRC" || { echo "! $SRC not match" >> "$LOG"; return 1; }

  mkdir -p "${OUT%/*}"
  TMP=$OUT.tmp; ADD=$OUT.add
  cp "$SRC" "$TMP" || return 1
  : > "$ADD"

  while IFS= read -r LINE || [ -n "$LINE" ]; do
    LINE=$(printf '%s' "$LINE" | tr -d '\r')
    LINE=${LINE#"${LINE%%[![:space:]]*}"}      # bo khoang trang dau dong
    case "$LINE" in ''|'#'*) continue ;; esac
    case "$LINE" in SEC_*=*) ;; *) echo "skip (sai dinh dang): $LINE" >> "$LOG"; continue ;; esac
    KEY=${LINE%%=*}; VAL=${LINE#*=}
    case "$KEY" in *[!A-Z0-9_]*) echo "skip (key loi): $LINE" >> "$LOG"; continue ;; esac
    case "$VAL" in ''|*'<'*|*'>'*|*'&'*|*'|'*) echo "skip (gia tri loi): $LINE" >> "$LOG"; continue ;; esac
    if grep -q "<$KEY>" "$TMP"; then
      sed -i "s|<$KEY>.*</$KEY>|<$KEY>$VAL</$KEY>|" "$TMP"
      echo "replace $KEY=$VAL" >> "$LOG"
    else
      echo "    <$KEY>$VAL</$KEY>" >> "$ADD"
      echo "add     $KEY=$VAL" >> "$LOG"
    fi
  done < "$LIST"

  sed -i '/<\/SecFloatingFeatureSet>/d' "$TMP"
  cat "$ADD" >> "$TMP"
  echo '</SecFloatingFeatureSet>' >> "$TMP"
  rm -f "$ADD"

  if grep -q '<SecFloatingFeatureSet>' "$TMP" && [ "$(tail -n 1 "$TMP")" = '</SecFloatingFeatureSet>' ]; then
    mv "$TMP" "$OUT"
    chmod 0644 "$OUT"
    echo "ok $REL" >> "$LOG"
    return 0
  fi
  rm -f "$TMP"
  echo "! $REL error skip" >> "$LOG"
  return 1
}

DONE=0
patch_one system/etc/floating_feature.xml && DONE=1

[ -f /vendor/etc/floating_feature.xml ] && patch_one system/vendor/etc/floating_feature.xml && DONE=1
[ "$DONE" = 1 ]