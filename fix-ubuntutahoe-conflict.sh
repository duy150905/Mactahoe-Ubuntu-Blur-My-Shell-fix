#!/usr/bin/env bash
set -euo pipefail

EXT="${1:-$HOME/.local/share/gnome-shell/extensions/UbuntuTahoe@adfoxtheme.github.io}"

[ -f "$EXT/metadata.json" ] || {
    echo "Không thấy $EXT/metadata.json"
    exit 1
}
command -v perl >/dev/null || {
    echo "Cần cài perl"
    exit 1
}
command -v glib-compile-schemas >/dev/null || {
    echo "Cần cài glib2 (glib-compile-schemas)"
    exit 1
}

BK="${EXT%/}.bak-before-bms-split"
if [ ! -d "$BK" ]; then
    cp -a "$EXT" "$BK"
    echo "Đã sao lưu: $BK"
fi

find "$EXT" -type f \( -name '*.js' -o -name '*.css' \) -print0 | xargs -0 perl -pi -e '
    # 1a. GTypeName trùng với Blur my Shell
    s/(GTypeName:\s*)(["\x27])BMSWaveEffect\2/${1}${2}TahoeWaveEffect${2}/;
    s/(GTypeName:\s*)(["\x27])(Corner|Refraction|Upscale|Pixelize|Downscale|Derivative|Noise|Luminosity|HslToRgb|RgbToHsl|Color)Effect\2/${1}${2}Tahoe${3}Effect${2}/;

    # 1b. biến toàn cục global.blur_my_shell
    s/\bglobal\.blur_my_shell\b/global.ubuntu_tahoe_blur/g;

    # 1c. thuộc tính _bms_* gắn lên đối tượng dùng chung (AppFolderDialog, Main...)
    s/(?<=\.)_bms_/_tahoe_/g;

    # 1d. tên actor / class CSS bắt đầu bằng bms-  (bms-popup-*, bms-overview-*, ...)
    s/(?<![\w-])bms-/tahoe-/g;

    # 1e. tên node dùng để debug
    s/\bBms(?=[A-Z])/Tahoe/g;

    # 1f. class CSS dùng chung tên với Blur my Shell
    s/(?<![\w-])(blurred-overview|appfolder-dialogs-(?:light|dark|transparent)|overview-components-(?:light|dark|transparent)|(?:dark|light|transparent|contrasted)-panel|gradient-panel(?:-reverse)?|panel-light-text|(?:dark|light|transparent)-dash)(?![\w-])/tahoe-$1/g;
'

SCHEMAS="$EXT/schemas"
OLD_XML="$SCHEMAS/org.gnome.shell.extensions.blur-my-shell.gschema.xml"
NEW_XML="$SCHEMAS/org.gnome.shell.extensions.ubuntutahoe-blur.gschema.xml"

if [ -f "$OLD_XML" ]; then
    mv "$OLD_XML" "$NEW_XML"
fi
if [ -f "$NEW_XML" ]; then
    perl -pi -e 's/blur-my-shell/ubuntutahoe-blur/g' "$NEW_XML"
fi
find "$EXT" -type f -name '*.js' -print0 | xargs -0 perl -pi -e 's/org\.gnome\.shell\.extensions\.blur-my-shell/org.gnome.shell.extensions.ubuntutahoe-blur/g'
glib-compile-schemas "$SCHEMAS"

echo
echo "== Kiểm tra còn sót dấu vết Blur my Shell không =="
LEFT=$(grep -rnE "global\.blur_my_shell|[.]_bms_|(^|[^A-Za-z0-9_-])bms-|blur-my-shell|GTypeName:\s*[\"\x27](BMSWave|Corner|Refraction|Upscale|Pixelize|Downscale|Derivative|Noise|Luminosity|HslToRgb|RgbToHsl|Color)Effect[\"\x27]" "$EXT" --include='*.js' --include='*.css' --include='*.xml' || true)
if [ -n "$LEFT" ]; then
    echo "$LEFT"
    echo "!! Vẫn còn các dòng trên."
else
    echo "Sạch: không còn tên nào trùng với Blur my Shell."
fi

echo
echo "Xong. Đăng xuất rồi đăng nhập lại (Wayland không restart shell tại chỗ được), sau đó bật UbuntuTahoe."
echo "Hoàn tác: rm -rf '$EXT' && mv '$BK' '$EXT'"
