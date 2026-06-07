# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      <home-manager/nixos>
    ];

  nix.settings.substituters = [
    "https://mirrors.ustc.edu.cn/nix-channels/store"      # 中科大镜像
    "https://mirror.sjtu.edu.cn/nix-channels/store"       # 上海交大镜像（备选）
    "https://cache.nixos.org/"                            # 官方源（最后fallback）
  ];

# --- 启动引导器 --- #

  # Use the systemd-boot EFI boot loader.
  # boot.loader.systemd-boot.enable = true;

  # 1. 禁用原有的 systemd-boot
  boot.loader.systemd-boot.enable = false;

  # 2. 启用并配置 GRUB (适配 UEFI 启动模式)
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    
    # 使用完美等比缩放的 16:10 分辨率，后面的 auto 依然作为防黑屏兜底
    #gfxmodeEfi = "1920x1200,auto";    
    # 在 UEFI 启动模式下，device 必须严格设置为 "nodev"
    device = "nodev"; 
    
    # 开启系统探测。这会自动扫描并探测出你的 Windows 引导，并将其完美添加到 GRUB 的启动菜单中，省去手动同步时间的麻烦。
    useOSProber = true;
    default = "saved";
  };

  # 3. 允许系统修改 EFI 变量
  boot.loader.efi.canTouchEfiVariables = true;
  
  # 4.自定义启动项
  boot.loader.grub.extraEntries = ''
    menuentry "Reboot" {
      reboot
    }
    menuentry "Poweroff" {
      halt
    }
    menuentry "UEFI Firmware Settings" --class recovery {
      fwsetup
    }
  '';

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

# --- 主机名--- #

  networking.hostName = "nixos"; # Define your hostname.

  # Configure network connections interactively with nmcli or nmtui.
  networking.networkmanager.enable = true;

# --- 时区 --- #

  # Set your time zone.
  time.timeZone = "Asia/Shanghai";
  # 👑 强制将硬件时间（RTC）设置为本地时间，完美同步 Windows
  time.hardwareClockInLocalTime = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";
 
 # --- daed --- #

  # 1. 把 daed 软件包放进系统环境

  # 2. 手搓一个 daed 的后台守护进程服务
    systemd.services.daed = {
    enable = true;
    description = "daed transparent proxy dashboard";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    
    # 【新增这一段】：在启动 daed 之前，自动将系统的 geoip 和 geosite 数据软链接到 daed 目录
    preStart = ''
      ln -sf ${pkgs.v2ray-geoip}/share/v2ray/geoip.dat /var/lib/daed/geoip.dat
      ln -sf ${pkgs.v2ray-domain-list-community}/share/v2ray/geosite.dat /var/lib/daed/geosite.dat
    '';
    
    serviceConfig = {
      ExecStart = "${pkgs.daed}/bin/daed run -c /var/lib/daed";
      StateDirectory = "daed";
      Restart = "on-failure";
      LimitNPROC = 512;
      LimitNOFILE = 1048576;
    };
  };
    
# Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  #};

  # Enable the X11 windowing system.
  # services.xserver.enable = true;


  

  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

# --- 音频服务 --- #

  # Enable sound.
  # services.pulseaudio.enable = true;
  # OR
  services.pipewire = {
     enable = true;
     pulse.enable = true;
   };

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

# --- 普通用户 --- #

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.biyuan = {
     isNormalUser = true;
     extraGroups = [ "wheel" "video" "networkmanager" "i2c" "input"]; # Enable ‘sudo’ for the user.
     packages = with pkgs; [
       tree      ];
   };

  programs.firefox.enable = true;

# --- 系统软件包 --- #

  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
   environment.systemPackages = with pkgs; [
     neovim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
     wget
     git
     curl
     wget
     htop
     pciutils
     alacritty  # 终端模拟器 (Super+T)
     fuzzel     # 应用启动器 (Super+D)
     swaylock   # 屏幕锁 (Super+Alt+L)
     waybar     # 状态栏
     mako       # 通知
     xdg-desktop-portal-gtk # 屏幕共享等功能需要
     greetd     # 登录管理器
     daed       # 代理工具
     stow       # 文件链接工具
     xdg-user-dirs
     psmisc
     kitty      # 终端模拟器
     rofi       # 应用起动器，电源菜单，壁纸选择器
     wofi
     awww
     fastfetch 
     hellwal
     splayer
     vscodium
     jq
     unzip
     imagemagick
     starship
     waypaper
     snapper
     nautilus
     yazi
     cava
     loupe
     btop
     ncdu
     brightnessctl
     google-chrome
     gnome-keyring
     libsecret
     seahorse # (可选) 这是一个图形化密钥环管理工具，方便你查看里面存了什么
     ddcutil
     wshowkeys
   ];


#保留一个软件包
  
  nixpkgs.config.permittedInsecurePackages = [ "electron-39.8.10" ];
  

programs.nix-ld.enable = true;
programs.nix-ld.libraries = with pkgs; [
  stdenv.cc.cc.lib
  libpcap
];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.mtr.enable = true;
  programs.gnupg.agent = {
  enable = true;
  enableSSHSupport = true;
  };

# -------------------------------------------------------------------------------------- #  

  # [废案]终端美化：系统级 Starship 全局配置
  
  #programs.starship = {
  #  enable = true;
    
    # 将 TOML 配置直接翻译为 Nix 语法，应用到所有用户
  #  settings = {
  #    format = "$os$username$directory$git_branch$git_status$time$line_break$character";
      
  #    os = {
  #      disabled = false;
  #      format = "[](#575962)[ ](bg:#575962 fg:#0b0b0b)";
  #    };
      
  #    username = {
  #      show_always = true;
  #      format = "[ $user ](bg:#575962 fg:#0b0b0b)[](fg:#575962 bg:#302f30)";
  #    };
      
  #    directory = {
  #      format = "[ $path ](bg:#302f30 fg:#ffffff)";
  #      truncation_length = 3;
  #    };
      
  #    git_branch = {
  #      symbol = "";
  #      format = "[ $symbol $branch](fg:#575962 bg:#302f30)";
  #    };
      
  #    git_status = {
  #      format = "[ $all_status$ahead_behind ](fg:#575962 bg:#302f30)";
  #    };
      
  #    time = {
  #      disabled = false;
  #      format = "[ 󱎫 $time ](bg:#302f30 fg:#ffffff)[ ](fg:#302f30)";
  #    };
      
  #    character = {
  #      success_symbol = "[❯](bold fg:#575962)";
  #      error_symbol = "[❯](bold fg:red)";
  #    };
  #  };
  #};

# ------------------------------------------------------------------------------- #

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

 # 1. 允许安全凭据存储服务
  services.gnome.gnome-keyring.enable = true;

  # 2. 极为关键：通过 PAM 模块在登录时全自动解锁密码箱，免去每次手动输密码的烦恼
  security.pam.services.greetd.enableGnomeKeyring = true; 
  # 💡 注意：如果你用的不是 greetd 登录管理器，而是 sddm 或 lightdm，请把上面一行的 greetd 换成对应的名字，比如 sddm。
  # 如果你是通过 TTY 命令行登录（无登录管理器），则改为：security.pam.services.login.enableGnomeKeyring = true;


# 开放 daed Web 面板端口
  networking.firewall.allowedTCPPorts = [ 2023 ];

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  system.copySystemConfiguration = true;

  # 允许安装非自由软件
  nixpkgs.config.allowUnfree = true;
  

  # 加载驱动
  services.xserver.videoDrivers = [ "nvidia" "amdgpu" ];
    
  hardware.nvidia = {
    modesetting.enable = true;
    open = false;
  
    package = config.boot.kernelPackages.nvidiaPackages.stable; # 选择稳定版驱动
   
    prime = {
      amdgpuBusId = "PCI:75:0:0";      # 换成你的 AMD 显卡 Bus ID
      nvidiaBusId = "PCI:1:0:0";     # 换成你的 NVIDIA 显卡 Bus ID
      offload.enable = true;
      sync.enable = false;
      };

   };
    
  # 启用硬件加速
    hardware.graphics.enable = true;

  # 1. 启用 Niri 窗口管理器
  programs.niri.enable = true;

  # 2. 配置 Greetd 登录管理器
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        # 使用 tuigreet 作为前端界面
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd niri-session";
        # 【修改这里】：必须是严格的 greeter，不能多字母也不能少字母
        user = "greeter"; 
      };
    };
  };

  # 3. 解决 TTY 刷屏问题（防坑必加）
  systemd.services.greetd.serviceConfig = {
    Type = "idle";
    StandardInput = "tty";
    StandardOutput = "tty";
    StandardError = "journal"; 
    TTYReset = true;
    TTYVHangup = true;
    TTYVTDisallocate = true;
  };

  # Fonts

  # 统一的字体管理配置
  fonts = {
    # 1. 允许系统安装所需的字体包
    packages = with pkgs; [
      jetbrains-mono
      inter
      wqy_zenhei
      wqy_microhei
      liberation_ttf
       
      # 引入最新的 Nerd Fonts (包含各种终端图标)
      nerd-fonts.jetbrains-mono
      nerd-fonts.symbols-only
      nerd-fonts.iosevka

      lxgw-wenkai
      lxgw-neoxihei
      sarasa-gothic 
    ];

    # 2. 字体渲染优化（针对现代高分屏调校）
    fontconfig = {
      enable = true;
      antialias = true;              # 开启抗锯齿
      hinting.enable = true;          # 开启字体微调（让边缘更锐利）
      hinting.style = "slight";       # 微调风格，防止字体变形
      subpixel.lcdfilter = "default"; # LCD 像素过滤，让文字更清晰

      # 3. 设定系统默认字体的回退顺序（防止中文字体错乱）
      defaultFonts = {
        # 默认无衬线字体（UI 界面常用）
        sansSerif = [ "Inter" "WenQuanYi Micro Hei" "DejaVu Sans" ];
        # 默认衬线字体（阅读文章常用）
        serif = [ "Liberation Serif" "WenQuanYi Zen Hei" "DejaVu Serif" ];
        # 默认等宽字体（终端和代码写死使用这个顺序）
        monospace = [ "JetBrainsMono Nerd Font" "WenQuanYi Micro Hei" "DejaVu Sans Mono" ];
      };
    };
  };

  # 输入法
  # 启用并配置 Fcitx5 输入法框架
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      # 开启 Wayland 强兼容模式（Niri 桌面必备）
      waylandFrontend = true;
      
      # 在这里捆绑你需要的中文扩展包和皮肤
      addons = with pkgs; [
        qt6Packages.fcitx5-chinese-addons # 核心中文扩展（含五笔、拼音）
        fcitx5-rime             # Rime 引擎（极客专属）
        fcitx5-material-color   # 精美主题皮肤
        fcitx5-pinyin-zhwiki    # 维基百科词库增强
      ];
    };
  };

  # 环境变量：确保各类软件（如 GTK/QT 应用、Kitty 终端）能完美唤醒输入法
  environment.variables = {
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
  };

  # starship

  # 启用 starship 提示符
  # programs.starship.enable = true;
   environment.interactiveShellInit = ''
    eval "$(starship init bash)"
  '';

 # 背光控制

  # 1. 开启 I2C 硬件支持
  hardware.i2c.enable = true;


  # GTK themes , 背光控制

  # 开启 dconf 守护
  programs.dconf.enable = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # 现在系统认识它了！接管 biyuan 用户的桌面美化

  home-manager.users.biyuan = { pkgs, ... }: {
    # 这里的版本号尽量和你的 system.stateVersion 保持一致
    home.stateVersion = "25.11"; 

    
     gtk = {
      enable = true;
      font = {
        name = "Iosevka Nerd Font";
        package = pkgs.nerd-fonts.iosevka;
        size = 11;
       };
      iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.catppuccin-papirus-folders.override {
          flavor = "mocha";
          accent = "mauve";
        };
      };
      theme = {
        name = "catppuccin-mocha-mauve-standard";
        package = pkgs.catppuccin-gtk.override {
          accents = [ "mauve" ];
          size = "standard";
          variant = "mocha";
        };
      };
      cursorTheme = {
        name = "catppuccin-mocha-mauve-cursors";
        package = pkgs.catppuccin-cursors.mochaMauve;
        size = 24;
      };
      # 【新增这一行来彻底消除警告】
      # 明确告诉 Home Manager：不要把传统主题强加给傲娇的 GTK4/libadwaita 应用
      gtk4.theme = null;
    };

    home.sessionVariables = {
      XCURSOR_THEME = "catppuccin-mocha-mauve-cursors";
      XCURSOR_SIZE = "24";
      GTK_THEME = "catppuccin-mocha-mauve-standard";
    
    };
   
   # 未启用的starship用户级方案，启用了系统级方案
   # programs.bash = {
   # enable = true;{ config, pkgs, ... }: {
  

   
   # # 向 ~/.bashrc 的末尾追加这行点火代码
   # initExtra = ''
   #   eval "$(starship init bash)"
   # '';
   #};

  };

  # 👑 完美的 NixOS 安全提权外壳配置
  security.wrappers.wshowkeys = {
    source = "${pkgs.wshowkeys}/bin/wshowkeys";
    owner = "root";
    group = "root";
    setuid = true; # 👈 只保留这一个高权限通行证即可
  };

  programs.neovim = {
    enable = true;
 };

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.11"; # Did you read the comment?

}
