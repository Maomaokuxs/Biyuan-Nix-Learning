#!/usr/bin/env bash

# =================================================
# 🚀 瞬发精致版 (修复 0 字节竞态条件)
# =================================================

WALLPAPER_DIR="$HOME/Pictures/wallpapers"
CACHE_DIR="$HOME/.cache/by-mgr/rofi-wallpaper-thumbs"
COLOR_SCRIPT="$HOME/.config/niri/scripts/pick-color.sh"

mkdir -p "$WALLPAPER_DIR" "$CACHE_DIR"

if ! pkill -0 awww-daemon 2>/dev/null; then
    awww-daemon &
    sleep 0.5
fi

# =================================================
# 1. 异步极速生成 (原子写入，绝不产生坏文件)
# =================================================
find "$WALLPAPER_DIR" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" \) | while read -r img; do
    rel_path="${img#$WALLPAPER_DIR/}"7
    cache_name="${rel_path//\//_}"
    thumb_path="$CACHE_DIR/${cache_name}.jpg"
    tmp_path="${thumb_path}.tmp" # 👑 临时文件护城河
    
    if [ ! -f "$thumb_path" ] || [ "$img" -nt "$thumb_path" ]; then
        # 加了单引号 '256x144^' 防止 bash 转义出错
	# 👑 Retina 超采样魔法：生成 512x288 的高清原图
	( magick "$img" -auto-orient -filter Lanczos -resize '384x216^' -gravity center -extent 384x216 -unsharp 0x0.5+0.5+0 -quality 95 "$tmp_path" && mv "$tmp_path" "$thumb_path" ) &
    fi
done

# =================================================
# 2. 立即拉起 Rofi
# =================================================
selected=$(find "$WALLPAPER_DIR" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" \) | while read -r img; do
    rel_path="${img#$WALLPAPER_DIR/}"
    cache_name="${rel_path//\//_}"
    thumb_path="$CACHE_DIR/${cache_name}.jpg"
    
    # 兜底：如果还没生成完（连 jpg 文件都没有），安全回退到原图
    if [ ! -f "$thumb_path" ]; then
        thumb_path="$img"
    fi
    
    # 👑 换用更稳定的 printf 替代 echo，防止特殊字符断板
    printf "%s\0icon\x1f%s\n" "$rel_path" "$thumb_path"
done | rofi -dmenu -no-config -i -theme ~/.config/rofi/themes/wallpaper.rasi -p "󰸉 桌面壁纸:")

if [ -z "$selected" ]; then
    exit 0
fi

# =================================================
# 3. 切换壁纸与系统联动
# =================================================
wallpaper_path="$WALLPAPER_DIR/$selected"

awww img "$wallpaper_path" \
    --transition-type "wipe" \
    --transition-angle 30 \
    --transition-step 90 \
    --transition-fps 60

if [ -f "$COLOR_SCRIPT" ]; then
    "$COLOR_SCRIPT" "$wallpaper_path" &
fi

notify-send "壁纸已切换" "$(basename "$selected")" -i "$wallpaper_path"
