#!/usr/bin/env bash

# =================================================
# 🔄 核心修正：将子命令改为 Niri 官方认可的 event-stream
# =================================================
echo "🛰️ Niri 屏幕热插拔事件监听器已完美上线..."

# 使用 event-stream 代替之前臆想的 monitor
niri msg event-stream | while read -r line; do
    # 只要日志流里蹦出了 "OutputAdded"（新屏幕加入）
    if echo "$line" | grep -q "OutputAdded"; then
        echo "🔌 [热插拔] 检测到外接副屏幕通电，正在等待信号稳定..."
        sleep 1.5 # 留给大屏 1.5 秒完成硬件握手
        
        # 抓取 swww 当前的主屏幕壁纸
        current_wall=$(swww query | head -n 1 | awk -F 'img: ' '{print $2}')
        
        if [ -f "$current_wall" ]; then
            echo "🎨 正在将壁纸 [$(basename "$current_wall")] 补刷至副屏幕..."
            # 重新触发完全体编译，让副屏幕也吃上最新的调色板
            ~/.config/niri/scripts/test-pick-color.sh "$current_wall"
        else
            echo "⚠️ 刷图失败：未能读取到当前壁纸路径。"
        fi
    fi
done
