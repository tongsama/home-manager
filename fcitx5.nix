{ pkgs, lib, config, ... }:

let
  cfg = config.my.fcitx5;

  guiProfile = config.my.gui.profile;

  isGui =
    guiProfile != "none";

  isWslgX11 =
    guiProfile == "wslg-x11";

  isUbuntuWayland =
    guiProfile == "ubuntu-wayland";

  isUbuntuX11 =
    guiProfile == "ubuntu-x11";

  enableFcitx5 =
    cfg.enable && isGui;

  fcitx5StartCommand =
    if isWslgX11 then
      "fcitx5 -d --disable=wayland,waylandim"
    else
      "fcitx5 -d";
in
{
  options.my.fcitx5.enable =
    lib.mkEnableOption "Fcitx5 Japanese input";

  config = lib.mkIf enableFcitx5 {
    i18n.inputMethod = {
      enable = true;
      type = "fcitx5";

      fcitx5 = {
        addons = with pkgs; [
          fcitx5-mozc
          fcitx5-gtk
          qt6Packages.fcitx5-configtool
        ];

        # WSLgではWayland frontendを使わない。
        # native Ubuntu Waylandでは使う。
        waylandFrontend = isUbuntuWayland;

        settings = {
          inputMethod = {
            GroupOrder = {
              "0" = "Default";
            };

            "Groups/0" = {
              Name = "Default";
              "Default Layout" = "us";
              DefaultIM = "mozc";
            };

            "Groups/0/Items/0" = {
              Name = "keyboard-us";
              Layout = "";
            };

            "Groups/0/Items/1" = {
              Name = "mozc";
              Layout = "";
            };
          };
        };
      };
    };

    home.packages = with pkgs; [
      #fcitx5
      #fcitx5-mozc
      #fcitx5-gtk
      #qt6Packages.fcitx5-configtool

      # XWayland確認用。不要なら外してOK。
      xprop

      # WSLg/native両方でfcitx診断に便利
      #fcitx5-with-addons
    ];

    home.sessionVariables =
      {
        INPUT_METHOD = "fcitx";
        GTK_IM_MODULE = "fcitx";
        QT_IM_MODULE = "fcitx";
        XMODIFIERS = "@im=fcitx";
        SDL_IM_MODULE = "fcitx";
      }
      // lib.optionalAttrs isWslgX11 {
        # WSLgではfcitx5をXWayland側に倒す
        GDK_BACKEND = "x11";
        QT_QPA_PLATFORM = "xcb";
      }
      // lib.optionalAttrs isUbuntuWayland {
        # native Ubuntu WaylandではWaylandを優先
        GDK_BACKEND = "wayland,x11";
        QT_QPA_PLATFORM = "wayland;xcb";
      }
      // lib.optionalAttrs isUbuntuX11 {
        GDK_BACKEND = "x11";
        QT_QPA_PLATFORM = "xcb";
      };

    # WSLgはデスクトップセッションがない前提なのでbash起動時にdaemonを立てる。
    #programs.bash.initExtra = lib.mkIf isWslgX11 ''
    #  if [ -n "''${DISPLAY:-}" ]; then
    #    if command -v fcitx5 >/dev/null 2>&1; then
    #      if ! pgrep -u "$USER" -x fcitx5 >/dev/null 2>&1; then
    #        ${fcitx5StartCommand} >/tmp/fcitx5-wslg.log 2>&1 || true
    #      fi
    #    fi
    #  fi
    #'';
    home.file.".config/bash/hm-extra.d/fcitx5-wslg.bash" = lib.mkIf isWslgX11 {
      text = ''
        # Managed by Home Manager
        export INPUT_METHOD=fcitx
        export GTK_IM_MODULE=fcitx
        export QT_IM_MODULE=fcitx
        export XMODIFIERS=@im=fcitx
        export SDL_IM_MODULE=fcitx
    
        export GDK_BACKEND=x11
        export QT_QPA_PLATFORM=xcb    

        # WSLg + fcitx5:
        # Wayland frontendを使わず、XWayland/XIM/GTK IM module側へ寄せる。
        if [ -n "''${DISPLAY:-}" ]; then
          if command -v fcitx5 >/dev/null 2>&1; then
            if ! pgrep -u "$USER" -x fcitx5 >/dev/null 2>&1; then
              fcitx5 -d --disable=wayland,waylandim >/tmp/fcitx5-wslg.log 2>&1 || true
            fi
          fi
        fi
      '';
    };

    # native Ubuntu desktopではXDG Autostartに寄せる。
    # GUIログイン時に起動する想定。
    xdg.configFile."autostart/fcitx5.desktop" = lib.mkIf (isUbuntuWayland || isUbuntuX11) {
      text = ''
        [Desktop Entry]
        Type=Application
        Name=Fcitx 5
        Exec=${pkgs.fcitx5}/bin/fcitx5 -d
        X-GNOME-Autostart-enabled=true
        NoDisplay=true
      '';
    };
  };
}
