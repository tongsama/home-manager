# ディレクトリ構成と設定ファイル

## ディレクトリ構成

```text
~/.config/home-manager/
├── flake.nix
├── flake.lock
├── home.nix
├── bash.nix
├── ssh.nix
├── secrets-ssh.nix
├── oci.nix
├── secrets-oci.nix
├── k8s-tools.nix
├── k8s-oci.nix
├── starship.nix
├── vim.nix
├── secrets-vim.nix
├── skkdict.nix
├── nodejs.nix
├── fonts.nix
├── gui.nix
├── wslg.nix
├── fcitx5.nix
├── local.example.nix
├── local.nix                 # Git管理外
├── .sops.yaml
├── .gitignore
├── files/
│   ├── oci/
│   │   ├── config.template
│   │   └── sessions/DEFAULT/oci_api_key_public.pem
│   ├── starship/
│   │   └── starship.toml
│   ├── vim/
│   │   ├── dotvimrc
│   │   └── dotvimrc-secrets.template
│   └── skkdict/
│       └── SKK-JISYO.MY.LL.eucjp.gz
├── secrets/
│   ├── ssh.yaml
│   ├── oci.yaml
│   ├── vim.yaml
│   ├── plain-ssh/
│   │   └── .gitignore
│   ├── plain-oci/
│   │   └── .gitignore
│   └── plain-vim/
│       └── .gitignore
├── doc/                      # 項目別ドキュメント
└── README.md                 # 概要・目次
```

## 設定ファイルの要点

### `flake.nix`

`flake.nix` の主な役割:

* `nixpkgs` と `home-manager` のバージョン固定
* `local.nix` の読み込み
* `username` / `homePrefix` / `homeDirectory` / `system` の決定
* `guiProfile` / `fcitx5Enable` の決定
* `homeConfigurations.default` の提供
* pure evaluation用のfallback値 `defaultConfig` の保持

通常運用では `local.nix` を `--impure` で読み込む。

```nix
defaultConfig = {
  username = "new_user";
  homePrefix = "/home";
  system = "x86_64-linux";

  guiProfile = "none";
  fcitx5Enable = false;
};
```

`local.nix` がある場合は、そちらが優先される。

```nix
{
  username = "actual_user";
  homePrefix = "/home";
  system = "x86_64-linux";

  guiProfile = "wslg-x11";
  fcitx5Enable = true;
}
```

標準のflake attributeは以下。

```text
#default
```

そのため、通常コマンドは以下に統一する。

```bash
home-manager switch --flake "$HOME/.config/home-manager#default" --impure -b backup
```

`extraSpecialArgs` では、`local.nix` から読み込んだローカル値を `home.nix` に渡す。

例:

```nix
extraSpecialArgs = {
  inherit username homeDirectory localConfigLoaded localConfigPathString;

  guiProfile = localConfig.guiProfile or "none";
  fcitx5Enable = localConfig.fcitx5Enable or false;
};
```

### `home.nix`

`home.nix` の主な役割:

* 各moduleのimport
* `home.username`
* `home.homeDirectory`
* `home.stateVersion`
* 基本パッケージ
* `programs.home-manager.enable = true`
* `local.nix` 読み込み忘れや、実行ユーザ不一致を検出するactivation guard
* `guiProfile` / `fcitx5Enable` を各module用のoptionへ渡す

読み込むmodule:

```nix
imports = [
  ./bash.nix
  ./ssh.nix
  ./secrets-ssh.nix
  ./oci.nix
  ./secrets-oci.nix
  ./k8s-tools.nix
  ./k8s-oci.nix
  ./starship.nix

  ./gui.nix
  ./fonts.nix
  ./vim.nix
  ./secrets-vim.nix
  ./nodejs.nix
  ./wslg.nix
  ./fcitx5.nix
];
```

ローカル設定値をmodule optionへ反映する。

```nix
my.gui.profile = guiProfile;
my.fcitx5.enable = fcitx5Enable;
```

`local.nix` が存在するのに `--impure` なしで実行された場合は、activation前に止める。

ただし、`home-manager switch -b backup` のようにflake attributeを明示しない場合、このガードに到達する前にattribute解決で失敗することがある。
その場合も、設定が壊れたわけではない。正しいコマンドで再実行する。

```bash
home-manager switch --flake "$HOME/.config/home-manager#default" --impure -b backup
```

### `gui.nix`

`gui.nix` はGUI環境の種別を表す共通optionを定義する。

```nix
options.my.gui.profile = lib.mkOption {
  type = lib.types.enum [
    "none"
    "wslg-x11"
    "ubuntu-wayland"
    "ubuntu-x11"
  ];

  default = "none";
};
```

この値をもとに、`wslg.nix` や `fcitx5.nix` が環境別に設定を切り替える。

### `wslg.nix`

`wslg.nix` は `my.gui.profile == "wslg-x11"` の場合だけ発火する。

主な役割:

* GTK3 / GTK4の `settings.ini` を生成する
* WSLg上のGTKアプリのタイトルバーに最小化・最大化ボタンを出す
* user D-Bus session busが存在する場合は、`gsettings` でも `button-layout` を設定する

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

`gsettings` 反映時は、`DBUS_SESSION_BUS_ADDRESS` があればそれを使う。
なければ `/run/user/$UID/bus` が存在する場合だけ使う。

`/run/user/$UID/at-spi/bus` はAT-SPI用のアクセシビリティバスであり、通常のGSettings用D-Bus session busではない。
そのため、このリポジトリでは `/run/user/$UID/bus` を見る。

確認:

```bash
cat ~/.config/gtk-3.0/settings.ini
cat ~/.config/gtk-4.0/settings.ini

ls -l /run/user/$(id -u)/bus
```

