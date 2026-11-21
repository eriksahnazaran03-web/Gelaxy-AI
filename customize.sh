#!/system/bin/sh

[ -d "$MODPATH/system" ] || abort "! Module payload is incomplete"


find "$MODPATH/system" -type f -name '*.apk' -exec touch {} \; || true

label_tree() {
  SOURCE=$1
  REFERENCE=$2
  [ -d "$SOURCE" ] || return 0
  [ -e "$REFERENCE" ] || return 0
  find "$SOURCE" -print | while IFS= read -r ENTRY; do
    RELATIVE=${ENTRY#"$SOURCE"}
    LABEL_FROM=$REFERENCE$RELATIVE
    while [ ! -e "$LABEL_FROM" ] && [ "$LABEL_FROM" != / ]; do
      LABEL_FROM=${LABEL_FROM%/*}
      [ -n "$LABEL_FROM" ] || LABEL_FROM=/
    done
    chcon --reference="$LABEL_FROM" "$ENTRY" 2>/dev/null || true
  done
}

ui_print "- AI IS ADDING..."
if sh "$MODPATH/gen-floating-feature.sh" "$MODPATH"; then
  ui_print "- Successfull"
else
  ui_print "! Failed "
fi

set_perm_recursive "$MODPATH/system" 0 0 0755 0644
set_perm "$MODPATH/system/lib64/libC2paDps.camera.samsung.so" 0 0 0644 u:object_r:system_lib_file:s0

label_tree "$MODPATH/system" /system
label_tree "$MODPATH/system/vendor" /vendor

touch "$MODPATH/.restore-port-packages"
ui_print "- Galaxy AI Working"