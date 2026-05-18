#!/usr/bin/env bash

# =================================================
# ⚡ Rofi 电源菜单脚本
# =================================================

# 定义带有 Nerd Font 图标的选项
shutdown="  关 机"
reboot="󰜉  重 启"
suspend="󰒲  睡 眠"
lock="  锁 屏"
logout="󰗽  注 销"

# 将选项拼合为一个列表，投递给 Rofi
options="$shutdown\n$reboot\n$suspend\n$lock\n$logout"

# 呼出 Rofi 并捕获用户的选择
# -theme 指定我们接下来要编写的专属样式表
chosen="$(echo -e "$options" | rofi -dmenu -i -theme ~/.config/rofi/themes/powermenu.rasi)"

# 根据选择执行相应的系统命令
case $chosen in
    $shutdown)
        systemctl poweroff
        ;;
    $reboot)
        systemctl reboot
        ;;
    $suspend)
        systemctl suspend
        ;;
    $lock)
        # 替换为你实际使用的锁屏工具，比如 swaylock 或 hyprlock
        swaylock -f -c 000000 
        ;;
    $logout)
        # 👑 针对 Niri 的专属注销命令
        niri msg action quit
        ;;
esac