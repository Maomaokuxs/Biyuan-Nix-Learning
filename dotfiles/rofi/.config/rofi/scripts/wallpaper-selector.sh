#!/bin/sh

WALLPAPER_DIR="$HOME/Pictures/wallpapers"
CACHE_DIR="$HOME/.cache/by-mgr/rofi-wallpaper-thumbs"
COLOR_SCRIPT="$HOME/.config/niri/scripts/pick-color.sh"

# =================================================
# 1. 环境预检与初始化 (专为全新 NixOS 环境设计)
# =================================================

# 如果用户的壁纸总目录还不存在，提前静默创建，防止后续 find 命令报错崩溃
if [ ! -d "$WALLPAPER_DIR" ]; then
    mkdir -p "$WALLPAPER_DIR"
fi

# 检查 by-mgr 专属缓存目录，不存在则创建
if [ ! -d "$CACHE_DIR" ]; then
    mkdir -p "$CACHE_DIR"
fi

# =================================================
# 2. 核心逻辑：确保守护进程存活（修正为 awww）
# =================================================
if ! pkill -0 awww-daemon 2>/dev/null; then
    awww-daemon &
    sleep 0.5
fi

# 3. 异步预生成完美 16:9 比例缩略图
find "$WALLPAPER_DIR" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.webp" \) | while read -r img; do
    rel_path="${img#$WALLPAPER_DIR/}"
    cache_name="${rel_path//\//_}"
    thumb_path="$CACHE_DIR/$cache_name"
    
    if [ ! -f "$thumb_path" ] || [ "$img" -nt "$thumb_path" ]; then
        magick "$img" -thumbnail 256x144^ -gravity center -extent 256x144 -quality 85 "$thumb_path" &
    fi
done

# 4. 呼出 Rofi 宽屏网格菜单
selected=$(find "$WALLPAPER_DIR" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.webp" \) | while read -r img; do
    rel_path="${img#$WALLPAPER_DIR/}"
    cache_name="${rel_path//\//_}"
    thumb_path="$CACHE_DIR/$cache_name"
    
    if [ ! -f "$thumb_path" ]; then
        thumb_path="$img"
    fi
    
    echo -en "${rel_path}\0icon\x1f${thumb_path}\n"
done | rofi -dmenu -no-config -i -theme ~/.config/rofi/themes/wallpaper.rasi -p "󰸉 桌面壁纸池:")

if [ -z "$selected" ]; then
    exit 0
fi

# =================================================
# 5. 切换壁纸与过渡动画
# =================================================
wallpaper_path="$WALLPAPER_DIR/$selected"

awww img "$wallpaper_path" \
    --transition-type "wipe" \
    --transition-angle 30 \
    --transition-step 90 \
    --transition-fps 60

# =================================================
# 🚀 6. 核心联动：触发全局色彩进化 (Niri, Waybar, Starship...)
# =================================================
if [ -f "$COLOR_SCRIPT" ]; then
    echo "🎨 正在提取新壁纸颜色并分发到全系统..."
    # 异步执行取色分发，这样不会卡住 Rofi 的淡出动画
    "$COLOR_SCRIPT" "$wallpaper_path" &
else
    notify-send "⚠️ 取色失败" "未找到取色脚本：$COLOR_SCRIPT"
fi

# 7. 发送桌面系统通知
notify-send "壁纸选择器" "已切换为：$(basename "$selected")" -i "$wallpaper_path"
