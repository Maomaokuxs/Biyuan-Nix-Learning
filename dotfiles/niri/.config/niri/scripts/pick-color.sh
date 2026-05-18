#!/usr/bin/env bash

# ==========================================
# 0. 环境与路径防御准备
# ==========================================
WALLPAPER=$(readlink -f "$1")
if [ -z "$WALLPAPER" ] || [ ! -f "$WALLPAPER" ]; then
    echo -e "\033[0;31m❌ 错误: 未提供有效的壁纸路径。\033[0m"
    echo "用法: $0 /路径/到/壁纸.png"
    exit 1
fi

TARGET_DIR="$HOME/.cache/by-mgr/hellwal"
mkdir -p "$TARGET_DIR"

# 壁纸渲染 (Wayland 环境下)
if [ -n "$WAYLAND_DISPLAY" ]; then
    if command -v swww &> /dev/null; then
        swww query &>/dev/null || swww init &>/dev/null
        swww img "$WALLPAPER" --transition-type grow --transition-pos center --transition-duration 2
    fi
fi

# ==========================================
# 1. 内存取色与拦截兜底
# ==========================================
echo ">> 正在分析壁纸色彩 (内存处理)..."
JSON_DATA=$(hellwal -i "$WALLPAPER" -j)

BG=$(echo "$JSON_DATA" | jq -r '.special.background // .colors.color0 // "#1e1e2e"')
FG=$(echo "$JSON_DATA" | jq -r '.special.foreground // .colors.color15 // "#ffffff"')
ACCENT=$(echo "$JSON_DATA" | jq -r '.colors.color4 // "#89b4fa"')
MUTED=$(echo "$JSON_DATA" | jq -r '.colors.color8 // .colors.color0 // "#45475a"')

[[ "$MUTED" == "#000000" || "$MUTED" == "#111111" ]] && MUTED="#2a2b3c"
[[ "$BG" == "#000000" || "$BG" == "#111111" ]] && BG="#1e1e2e"

if [[ ! "$BG" =~ ^# ]] || [[ ! "$ACCENT" =~ ^# ]]; then
    echo -e "\033[0;31m❌ 提取颜色失败。\033[0m"
    exit 1
fi

# ==========================================
# 2. 核心：生成全系统唯一的中央色彩数据库
# ==========================================
echo "💾 正在固化中央色彩数据库 -> global-palette.env"
PALETTE_FILE="$TARGET_DIR/global-palette.env"

# 完美修正：将 upcase 替换为标准的 ascii_upcase
echo "$JSON_DATA" | jq -r --arg bg "$BG" --arg fg "$FG" --arg acc "$ACCENT" --arg mut "$MUTED" '
  "BG=\"\($bg)\"",
  "FG=\"\($fg)\"",
  "ACCENT=\"\($acc)\"",
  "MUTED=\"\($mut)\"",
  (.colors | to_entries[] | "\(.key | ascii_upcase)=\"\(.value)\"")
' > "$PALETTE_FILE"

# ==========================================
# 3. 分发：将唯一数据源映射到 color-软件名 切片
# ==========================================
echo "🏭 正在为各应用工厂分发 [color-软件名] 影子切片..."
source "$PALETTE_FILE"

# Kitty (color-kitty.conf)
cat << EOF > "$TARGET_DIR/color-kitty.conf"
background $BG
foreground $FG
cursor     $ACCENT
active_tab_background   $ACCENT
active_tab_foreground   $BG
inactive_tab_background $BG
inactive_tab_foreground $MUTED
color0  $COLOR0
color1  $COLOR1
color2  $COLOR2
color3  $COLOR3
color4  $COLOR4
color5  $COLOR5
color6  $COLOR6
color7  $COLOR7
color8  $COLOR8
color9  $COLOR9
color10 $COLOR10
color11 $COLOR11
color12 $COLOR12
color13 $COLOR13
color14 $COLOR14
color15 $COLOR15
EOF

# Waybar (color-waybar.css)
cat << EOF > "$TARGET_DIR/color-waybar.css"
@define-color bg $BG;
@define-color fg $FG;
@define-color accent $ACCENT;
@define-color muted $MUTED;
EOF

# 🎯 影子三：Niri (color-niri.kdl)
cat << EOF > "$TARGET_DIR/color-niri.kdl"
layout {
    focus-ring {
        active-color "$ACCENT"
        inactive-color "$MUTED"
    }
}
EOF

# 🎯 影子四：Rofi (color-rofi.rasi)
cat << EOF > "$TARGET_DIR/color-rofi.rasi"
* {
    bg: $BG;
    fg: $FG;
    accent: $ACCENT;
    muted: $MUTED;
}
EOF

# ==========================================
# 4. 信号弹：强制引发热重载
# ==========================================
kill -USR1 $(pidof kitty) 2>/dev/null
killall -SIGUSR2 waybar 2>/dev/null

# ==========================================
# Starship (归档至中央缓存)
# ==========================================
echo "🏭 正在为 Starship 分发色彩切片..."

cat << EOF > "$HOME/.cache/by-mgr/hellwal/color-starship.toml"
[palettes.hellwal]
bg = "$BG"
fg = "$FG"
accent = "$ACCENT"
muted = "$MUTED"
color0 = "$COLOR0"
color1 = "$COLOR1"
color2 = "$COLOR2"
color3 = "$COLOR3"
color4 = "$COLOR4"
color5 = "$COLOR5"
color6 = "$COLOR6"
color7 = "$COLOR7"
EOF

# 🚀 每次换壁纸，永远用干净的 base 模板去拼接颜色，生成最终的 starship.toml
cat "$HOME/.config/starship_base.toml" "$HOME/.cache/by-mgr/hellwal/color-starship.toml" > "$HOME/.config/starship.toml"

echo -e "\033[0;32m✨ 调色板全局进化成功 [color-前缀已生效]！\033[0m"
