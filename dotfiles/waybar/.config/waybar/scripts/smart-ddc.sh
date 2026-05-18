# !usr/bin/evn

# =================================================
# 📺 专属于外接大屏（HDMI-A-1）的调光脚本
# =================================================

# 👑 核心逻辑：精准定位挂载在 HDMI-A-1 接口上的 I2C 总线号
get_bus() {
    ddcutil detect 2>/dev/null | \
    grep -B2 'card1-HDMI-A-1' | \
    grep 'I2C bus:' | \
    awk -F'-' '{print $2}' | \
    tr -d ' '
}

BUS=$(get_bus)

# 如果没接外屏，安全退出
if [ -z "$BUS" ]; then
    if [ "$1" = "read" ]; then
        echo '{"percentage": 0}'
    fi
    exit 0
fi

# 核心动作分支
case "$1" in
    "read")
        VAL=$(ddcutil --bus "$BUS" getvcp 10 --brief 2>/dev/null | awk '{print $4}')
        if [ -z "$VAL" ]; then VAL=0; fi
        echo "{\"percentage\": $VAL}"
        ;;
    "up")
        ddcutil --bus "$BUS" setvcp 10 + 10 --noverify
        ;;
    "down")
        ddcutil --bus "$BUS" setvcp 10 - 10 --noverify
        ;;
    "click")
        ddcutil --bus "$BUS" setvcp 10 50 --noverify
        ;;
esac
