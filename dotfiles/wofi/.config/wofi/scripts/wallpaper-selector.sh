#!/bin/sh

WALLPAPER_DIR="$HOME/Pictures/wallpapers"
# 定义一个专门存放缩略图的隐藏缓存目录
CACHE_DIR="$HOME/.cache/wallpaper-thumbs"
mkdir -p "$CACHE_DIR"

if ! pkill -0 swww-daemon 2>/dev/null; then
    swww-daemon &
    sleep 0.5
fi

# 【核心增强】：遍历壁纸，如果发现没有对应的缩略图，就用 ImageMagick 自动生成一张
find "$WALLPAPER_DIR" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.webp" \) | while read -r img; do
    img_name=$(basename "$img")
    thumb_path="$CACHE_DIR/$img_name"
    
    # 如果缓存不存在，或者原图比缓存新（说明你更新过壁纸），就压缩一份缩略图
    if [ ! -f "$thumb_path" ] || [ "$img" -nt "$thumb_path" ]; then
        # 压缩成宽高最大 160 像素的轻量图，质量 80%
        convert "$img" -thumbnail 160x90^ -gravity center -extent 160x90 -quality 80 "$thumb_path" &
    fi
done
wait # 等待所有后台压缩任务完成（只有第一次加载或者放新壁纸时会慢这半秒，以后全是秒开）

# 3. 喂给 wofi 时：把图片的路径（img:）指向小巧的“缩略图缓存”，但后面的名字保持原样
selected=$(find "$WALLPAPER_DIR" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.webp" \) | while read -r img; do
    img_name=$(basename "$img")
    echo "img:${CACHE_DIR}/${img_name}:${img_name}"
done | wofi --dmenu --allow-images --width=600 --height=500 --prompt="✨ 挑选一张新壁纸..." --cache-file=/dev/null)

if [ -z "$selected" ]; then
    exit 0
fi

# 4. 用户选中后，我们依然去拿原本的高清大图路径去传给 swww
wallpaper_name=$(echo "$selected" | awk -F ':' '{print $3}')
wallpaper_path="$WALLPAPER_DIR/$wallpaper_name"

# 5. 切壁纸
swww img "$wallpaper_path" --transition-type "wipe" --transition-angle 30 --transition-step 90 --transition-fps 60
notify-send "壁纸选择器" "已切换壁纸：$wallpaper_name" -i "$wallpaper_path"
