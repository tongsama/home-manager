# GUI / WSLg / fcitx5・Mozc 設定

## GUI profileについて

このリポジトリでは、GUI環境の種類を `local.nix` の `guiProfile` で切り替える。

```nix
{
  guiProfile = "none";
}
```

利用できる値:

```text
none
wslg-x11
ubuntu-wayland
ubuntu-x11
```

### `none`

非GUI環境向け。

WSLg設定、fcitx5、GTK設定などを発火させない。

例:

```nix
{
  username = "new_user";
  homePrefix = "/home";
  system = "x86_64-linux";

  guiProfile = "none";
  fcitx5Enable = false;
}
```

### `wslg-x11`

WSL2 + WSLg向け。

WSLgでは通常のGNOMEデスクトップセッションが存在しないため、GNOMEのdconf設定だけではウィンドウ装飾や入力メソッド設定が期待通りに反映されないことがある。

このプロファイルでは、以下を行う。

* GTK3 / GTK4用の `settings.ini` を生成する
* WSLg上のGTKアプリのウィンドウ装飾ボタンを調整する
* `/run/user/$UID/bus` がある場合、ユーザーD-Bus経由で `gsettings` を反映する
* fcitx5起動時に `--disable=wayland,waylandim` を付け、IM frontendを GTK IM module / XIM 側へ寄せる
* `QT_QPA_PLATFORM=xcb`
* `GDK_BACKEND=x11` は **現在コメントアウトで無効化**（下記「WSLg + fcitx5」の注記参照）。
  かつてGTKアプリをX11強制していたが、Nix gVimのGTK3ダイアログがWSLgでフォーカス不能になるため

例:

```nix
{
  username = "new_user";
  homePrefix = "/home";
  system = "x86_64-linux";

  guiProfile = "wslg-x11";
  fcitx5Enable = true;
}
```

### `ubuntu-wayland`

通常のUbuntuデスクトップ + Waylandセッション向け。

WSLg固有設定は使わない。
fcitx5はWayland frontendを使う。

例:

```nix
{
  username = "new_user";
  homePrefix = "/home";
  system = "x86_64-linux";

  guiProfile = "ubuntu-wayland";
  fcitx5Enable = true;
}
```

### `ubuntu-x11`

通常のUbuntuデスクトップ + X11セッション向け。

WSLg固有設定は使わない。
fcitx5はX11向けの環境変数で動かす。

例:

```nix
{
  username = "new_user";
  homePrefix = "/home";
  system = "x86_64-linux";

  guiProfile = "ubuntu-x11";
  fcitx5Enable = true;
}
```

## WSLg GUI設定

WSL2 + WSLgでは、通常のGNOME desktop sessionが存在しない。

そのため、GNOMEのdconf設定だけでは、GTKアプリのウィンドウ装飾やタイトルバーボタンが期待通りに変わらないことがある。

このリポジトリでは、`guiProfile = "wslg-x11";` の場合だけ、`wslg.nix` でWSLg向け設定を行う。

### GTK settings.ini

生成されるファイル:

```text
~/.config/gtk-3.0/settings.ini
~/.config/gtk-4.0/settings.ini
```

内容:

```ini
[Settings]
gtk-decoration-layout=:minimize,maximize,close
```

確認:

```bash
cat ~/.config/gtk-3.0/settings.ini
cat ~/.config/gtk-4.0/settings.ini
```

### gsettings反映

WSLg環境では、`gsettings` を使う場合でも通常のGNOMEセッションが無い。

そのため、以下の順でD-Bus session busを探す。

1. `DBUS_SESSION_BUS_ADDRESS` がある場合はそれを使う
2. `/run/user/$UID/bus` がsocketとして存在する場合はそれを使う
3. どちらも無ければskipする

確認:

```bash
echo "$DBUS_SESSION_BUS_ADDRESS"
ls -l /run/user/$(id -u)/bus
```

`/run/user/$UID/at-spi/bus` はAT-SPI用のアクセシビリティバスであり、通常のGSettings用D-Bus session busではない。

## fcitx5 / Mozc設定

日本語入力は `fcitx5.nix` で管理する。

有効化は `local.nix` で行う。

```nix
{
  guiProfile = "wslg-x11";
  fcitx5Enable = true;
}
```

または、通常のUbuntu Waylandデスクトップの場合:

```nix
{
  guiProfile = "ubuntu-wayland";
  fcitx5Enable = true;
}
```

非GUI環境では無効にする。

```nix
{
  guiProfile = "none";
  fcitx5Enable = false;
}
```

### 導入するもの

Home Manager  guiProfile = "ubuntu-wayland";
fcitx5Enable = true;
}

````

非GUI環境では無効にする。

```nix
{
  guiProfile =の `i18n.inputMethod` moduleを使う。

```nix
i18n.inputMethod = {
  enable = true;
  type = "fcitx5";

  fcitx5 = {
    addons = with pkgs; [
      fcitx5-mozc
      fcitx5-gtk
      qt6Packages.fcitx5-configtool
    ];
  };
};
````

注意:

`i18n.inputMethod.fcitx5.addons` を使うと、Home Manager側で `fcitx5-with-addons` が生成される。

そのため、`home.packages` に以下を重複して入れない。

```nix
fcitx5
fcitx5-mozc
fcitx5-gtk
qt6Packages.fcitx5-configtool
fcitx5-with-addons
```

これらを重複して入れると、以下のような衝突が起きることがある。

```text
pkgs.buildEnv error: two given paths contain a conflicting subpath:
  ...-fcitx5-with-addons.../bin/fcitx5
  ...-fcitx5.../bin/fcitx5
```

または:

```text
.../bin/fcitx5-config-qt
```

`fcitx5-configtool` は現在のnixpkgsでは以下を使う。

```nix
qt6Packages.fcitx5-configtool
```

### 入力メソッド設定

`fcitx5.nix` では、Mozcを既定の入力メソッドとして設定する。

```nix
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
```

確認:

```bash
cat ~/.config/fcitx5/profile
```

### WSLg + fcitx5

WSLgでは、fcitx5をWayland frontendで動かすと期待通りに動かないことがあるため、
fcitx5自体は `--disable=wayland,waylandim` でWayland frontendを使わず、GTK IM module / XIM 側へ寄せる。

設定される環境変数:

```bash
export INPUT_METHOD=fcitx
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
export SDL_IM_MODULE=fcitx

#export GDK_BACKEND=x11   # 現在は無効化 (下記の注記参照)
export QT_QPA_PLATFORM=xcb
```

> **注記 (2026-06): `GDK_BACKEND=x11` の強制を無効化**
>
> 以前は全GTKアプリを `GDK_BACKEND=x11` でXWaylandに倒していた。しかし
> Nixビルドの gVim (新しめのGTK3) のダイアログ (「変更を保存しますか?」等) が
> WSLg(Weston RAIL) のフォーカスを受け取れず操作不能になる問題があった
> (apt版gVimでは発生しない)。`GDK_BACKEND=wayland` ならダイアログ正常 &
> fcitx5入力もOKと確認したため、強制をコメントアウトしGTKアプリにWaylandを優先させている。
> 不具合のあるGTKアプリが出たら再検討する。`QT_QPA_PLATFORM=xcb` は据え置き。

fcitx5起動:

```bash
fcitx5 -d --disable=wayland,waylandim
```

この起動処理は、`~/.config/bash/hm-extra.d/fcitx5-wslg.bash` に生成される。

新しいbashを開くと、`DISPLAY` がある場合だけfcitx5を自動起動する。

確認:

```bash
echo "$GTK_IM_MODULE"
echo "$QT_IM_MODULE"
echo "$XMODIFIERS"
echo "$GDK_BACKEND"
echo "$QT_QPA_PLATFORM"

pgrep -a fcitx5
```

期待値例:

```text
fcitx
fcitx
@im=fcitx
x11
xcb
fcitx5 -d --disable=wayland,waylandim
```

手動起動:

```bash
fcitx5 -d --disable=wayland,waylandim
```

設定画面:

```bash
fcitx5-config-qt &
```

### 通常のUbuntu Wayland + fcitx5

`guiProfile = "ubuntu-wayland";` の場合はWaylandを優先する。

設定される環境変数:

```bash
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
GDK_BACKEND=wayland,x11
QT_QPA_PLATFORM=wayland;xcb
```

fcitx5はXDG autostartで起動する。

生成されるファイル:

```text
~/.config/autostart/fcitx5.desktop
```

### 通常のUbuntu X11 + fcitx5

`guiProfile = "ubuntu-x11";` の場合はX11向けに設定する。

```bash
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
GDK_BACKEND=x11
QT_QPA_PLATFORM=xcb
```

fcitx5はXDG autostartで起動する。

