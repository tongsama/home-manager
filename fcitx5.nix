{ pkgs, lib, config, options, ... }:

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

  # home-manager のバージョンで i18n.inputMethod の API が異なる。
  #   ~24.11 : i18n.inputMethod.enabled = "fcitx5" (旧API。fcitx5.settings 等は無い)
  #   25.05~ : i18n.inputMethod.enable = true; type = "fcitx5" (+ fcitx5.settings 等)
  # options を見て存在するキーだけで組み立てる。無いキーを含めると mkIf false でも
  # option パス存在検証で落ちるため、plain な条件付き属性 (lib.optionalAttrs) を使う。
  imOpts = options.i18n.inputMethod;

  imEnableAttr =
    if imOpts ? type then
      { enable = true; type = "fcitx5"; }
    else
      { enabled = "fcitx5"; };

  fcitx5SettingsAttr = {
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

  fcitx5Attr =
    {
      addons = with pkgs; [
        fcitx5-mozc
        fcitx5-gtk
        qt6Packages.fcitx5-configtool
      ];
    }
    # WSLgではWayland frontendを使わない。native Ubuntu Waylandでは使う。
    // lib.optionalAttrs (imOpts.fcitx5 ? waylandFrontend) {
      waylandFrontend = isUbuntuWayland;
    }
    // lib.optionalAttrs (imOpts.fcitx5 ? settings) {
      settings = fcitx5SettingsAttr;
    };
in
{
  # option 宣言 (my.fcitx5.enable) は options.nix に移動済み。

  config = lib.mkIf enableFcitx5 {
    i18n.inputMethod = imEnableAttr // {
      fcitx5 = fcitx5Attr;
    };

    home.packages = [
      #pkgs.fcitx5
      #pkgs.fcitx5-mozc
      #pkgs.fcitx5-gtk
      #pkgs.qt6Packages.fcitx5-configtool

      # XWayland確認用。不要なら外してOK。
      # 26.05 系は top-level の pkgs.xprop、24.05 系は pkgs.xorg.xprop。
      (pkgs.xprop or pkgs.xorg.xprop)

      # WSLg/native両方でfcitx診断に便利
      #pkgs.fcitx5-with-addons
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
        # WSLgではfcitx5をXWayland側に倒すため、以前は全GTKアプリを X11 強制していた。
        #
        # しかし GDK_BACKEND=x11 を強制すると、Nixビルドの gVim (新しめの GTK3) の
        # ダイアログ (「変更を保存しますか?」等) が WSLg(Weston RAIL) のフォーカスを
        # 受け取れず、クリックできなくなる。apt版 gVim (別の GTK3 ビルド) では問題なし。
        # GDK_BACKEND=wayland で起動するとダイアログ正常 & fcitx5 の日本語入力もOK、と
        # WSLg上で確認済み (2026-06)。
        #
        # そのため GDK_BACKEND の X11 強制を無効化し、GTKアプリに Wayland を優先させる。
        # 不具合のある GTK アプリが出たら、その時に再検討 / 再有効化する。
        # (QT_QPA_PLATFORM=xcb は GTK とは別系統なので、ひとまず据え置く)
        # GDK_BACKEND = "x11";
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
    
        # GDK_BACKEND=x11 の強制は無効化 (理由は fcitx5.nix の sessionVariables のコメント参照)。
        # Nix gVim の GTK3 ダイアログが WSLg+XWayland でフォーカスを受け取れない問題のため。
        # GDK_BACKEND=wayland でも fcitx5 入力はOKと確認済み (2026-06)。
        #export GDK_BACKEND=x11
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
